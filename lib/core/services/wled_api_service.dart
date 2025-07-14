// lib/services/unified_wled_service.dart
// A single service that combines LAN discovery + live WebSocket streaming
// (from the old wled_api_service.dart) with the resilient HTTP/Dio command
// helpers (from the newer WLEDApiService).
//
// Usage pattern in UI / Riverpod:
//   final repo = UnifiedWledService();
//   repo.startDiscovery();
//   repo.deviceStream.listen((device) { /* rebuild UI */ });
//   await repo.setBrightness(mac: device.info.mac, brightness: 128);
//   // …
//   repo.dispose();

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:logger/logger.dart';
import 'package:multicast_dns/multicast_dns.dart' as mdns;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

import '../models/wled_device.dart';

/// Combines discovery + WebSocket live updates with robust Dio commands.
class UnifiedWledService {
  // ──────────────────────────────────────────────
  // ↓                                         ↓
  //  WebSocket / Discovery members            REST / Dio members
  // ──────────────────────────────────────────────
  final Map<String, WebSocketChannel> _channels = {}; // MAC → WS
  final Map<String, String> _macToIp = {}; // MAC → last‑known IP
  final Map<String, StreamController<Map<String, dynamic>>> _deviceControllers =
      {};
  final _stateController = StreamController<Map<String, dynamic>>.broadcast();

  mdns.MDnsClient? _mdnsClient;
  StreamSubscription? _mdnsSub;

  // Dio + logging + retry helpers
  final Dio _dio;
  final Logger _logger;
  static const int _timeoutMs = 15000;
  static const int _maxRetries = 2;
  Timer? _debounceTimer;
  Map<String, dynamic>? _lastStateCache;
  DateTime? _lastStateCacheTime;
  static const _stateCacheDuration = Duration(seconds: 5);

  final Map<String, Timer> _heartbeatTimers =
      {}; // Add this at the top with other fields
  final Map<String, Timer> _reconnectTimers = {};
  static const _heartbeatInterval = Duration(seconds: 30);
  static const _reconnectDelay = Duration(seconds: 5);

  Stream<Map<String, dynamic>> get deviceStream => _stateController.stream;

  UnifiedWledService()
      : _dio = Dio(
          BaseOptions(
            connectTimeout: const Duration(milliseconds: _timeoutMs),
            receiveTimeout: const Duration(milliseconds: _timeoutMs),
            sendTimeout: const Duration(milliseconds: _timeoutMs),
          ),
        ),
        _logger = Logger();

  // ──────────────────────────────────────────────
  // Discovery + live WebSocket layer
  // ──────────────────────────────────────────────
  Future<void> startDiscovery() async {
    if (kIsWeb) {
      _logger.w('mDNS discovery not supported on Web; add devices manually.');
      return;
    }

    _logger.i('Starting WLED mDNS discovery…');
    _mdnsClient?.stop();
    await _mdnsSub?.cancel();

    _mdnsClient = mdns.MDnsClient(
      rawDatagramSocketFactory: (dynamic host, int port,
          {bool? reuseAddress, bool? reusePort, int? ttl}) async {
        return await RawDatagramSocket.bind(host, port,
            reuseAddress: reuseAddress ?? false,
            reusePort: reusePort ?? false,
            ttl: ttl ?? 255);
      },
    );
    await _mdnsClient!.start();

    // Clear UI list before rediscovery
    _stateController.addError('CLEAR_DEVICES_SIGNAL');

    _mdnsSub = _mdnsClient!
        .lookup<mdns.ResourceRecord>(
          mdns.ResourceRecordQuery.service('_wled._tcp.local'),
        )
        .listen(_handleMdnsRecord);
  }

  Future<void> _handleMdnsRecord(mdns.ResourceRecord record) async {
    if (record.resourceRecordType != mdns.ResourceRecordType.service) return;
    final srv = record as mdns.SrvResourceRecord;
    final ip = srv.target;
    final port = srv.port;
    _logger.d('Discovered WLED at $ip:$port');

    try {
      final response = await _dio.get('http://$ip/json');
      final data = response.data;

      // ✅ Ensure IP is set before parsing
      if (data['info'] is Map<String, dynamic>) {
        data['info']['ip'] = ip;
      }

      final device = WledDevice.fromJson(data);
      final mac = device.info.mac;

      _macToIp[mac] = ip; // Store mapping

      // If we already hold a channel but IP changed, reconnect
      if (_channels.containsKey(mac)) {
        _logger.i('IP change for $mac → reconnecting WebSocket…');
        await _channels[mac]!.sink.close();
        _channels.remove(mac);
      }

      await _establishWebSocket(ip, mac, device);
    } catch (e) {
      _logger.e('Initial JSON fetch failed for $ip: $e');
    }
  }

  Future<void> connectToDeviceByIp(String ip) async {
    _logger.i('Manual connect to $ip');
    _stateController.addError('CLEAR_DEVICES_SIGNAL');
    for (var c in _channels.values) {
      c.sink.close();
    }
    _channels.clear();

    try {
      // First try a basic HTTP connection to verify the device is reachable
      final testResponse = await http.get(Uri.parse('http://$ip')).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (testResponse.statusCode != 200) {
        throw Exception(
            'Device returned status code: ${testResponse.statusCode}');
      }

      // Now try to get the JSON data
      final res = await _dio.get('http://$ip/json').timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('JSON fetch timed out');
        },
      );

      if (res.data == null) {
        throw Exception('No data received from device');
      }

      // ✅ Ensure IP is set before parsing
      if (res.data['info'] is Map<String, dynamic>) {
        res.data['info']['ip'] = ip;
      }

      final device = WledDevice.fromJson(res.data);
      final mac = device.info.mac;
      _macToIp[mac] = ip;

      _logger.i('Successfully connected to WLED device at $ip (MAC: $mac)');
      await _establishWebSocket(ip, mac, device);
    } catch (e) {
      _logger.e('Manual connect failed: $e');
      if (e is TimeoutException) {
        _stateController.addError('CONNECTION_TIMEOUT:$ip');
      } else if (e is SocketException) {
        _stateController.addError('NETWORK_ERROR:$ip');
      } else {
        _stateController.addError('DIRECT_CONNECT_FAILED:$ip');
      }
      rethrow;
    }
  }

  Future<void> _establishWebSocket(
      String ip, String mac, WledDevice initial) async {
    final uri = Uri.parse('ws://$ip/ws');
    try {
      _logger.d('Attempting WebSocket connection to $uri');

      // Cancel any existing connection for this MAC
      await _cleanupConnection(mac);

      final channel = WebSocketChannel.connect(uri);
      _channels[mac] = channel;
      _deviceControllers[mac] =
          StreamController<Map<String, dynamic>>.broadcast();

      // Wait for the connection to be established with timeout
      await channel.ready.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('WebSocket connection timed out');
        },
      );

      _logger.i('WebSocket connected successfully to $ip');

      // Store the MAC to IP mapping
      _macToIp[mac] = ip;

      // Send initial state update
      _stateController.add(await getState(mac));

      // Start heartbeat timer with more frequent checks
      _startHeartbeat(mac);

      channel.stream.listen((msg) {
        if (msg == 'ping') {
          // Respond to WLED pings
          channel.sink.add('pong');
          return;
        }
        _handleWsMessage(mac, msg, initial);
      }, onError: (err) {
        _handleConnectionFailure(mac, ip, initial);
      });

      // Ask for full state right away
      channel.sink.add(jsonEncode({'v': true}));
    } catch (e) {
      _logger.e('Failed to open WS $uri: $e');
      _handleConnectionFailure(mac, ip, initial);
      rethrow;
    }
  }

  void _handleConnectionFailure(String mac, String ip, WledDevice device) {
    _cleanupConnection(mac);
    _scheduleReconnect(ip, mac, device);

    // Only send error if we don't have a pending reconnection
    if (!_reconnectTimers.containsKey(mac)) {
      _stateController.addError('DEVICE_OFFLINE:$mac');
    }
  }

  Future<void> _cleanupConnection(String mac) async {
    try {
      final channel = _channels[mac];
      if (channel != null) {
        await channel.sink.close();
        _channels.remove(mac);
      }
      _heartbeatTimers[mac]?.cancel();
      _heartbeatTimers.remove(mac);
      _reconnectTimers[mac]?.cancel();
      _reconnectTimers.remove(mac);
      _deviceControllers[mac]?.close();
      _deviceControllers.remove(mac);
    } catch (e) {
      _logger.w('Error during connection cleanup for $mac: $e');
    }
  }

  void _scheduleReconnect(String ip, String mac, WledDevice device) {
    // Cancel any existing reconnect timer
    _reconnectTimers[mac]?.cancel();

    // Implement exponential backoff for reconnection attempts
    final attempts = _reconnectAttempts[mac] ?? 0;
    final delay =
        Duration(milliseconds: 500 * (1 << attempts) + Random().nextInt(1000));

    _reconnectTimers[mac] = Timer(delay, () async {
      try {
        _logger.i('Attempting reconnection to $mac (attempt ${attempts + 1})');
        await _establishWebSocket(ip, mac, device);
        _reconnectAttempts[mac] = 0; // Reset attempts on success
        _logger.i('Successfully reconnected to $mac');
      } catch (e) {
        _logger.w('Reconnection failed for $mac: $e');
        _reconnectAttempts[mac] =
            (attempts + 1).clamp(0, 5); // Cap at 5 attempts
        // Schedule next attempt if not at max attempts
        if (_reconnectAttempts[mac]! < 5) {
          _scheduleReconnect(ip, mac, device);
        } else {
          _logger.e('Max reconnection attempts reached for $mac');
          _stateController.addError('DEVICE_UNREACHABLE:$mac');
          _reconnectAttempts.remove(mac);
        }
      }
    });
  }

  void _startHeartbeat(String mac) {
    _heartbeatTimers[mac]?.cancel();
    _heartbeatTimers[mac] = Timer.periodic(_heartbeatInterval, (_) {
      try {
        if (_channels.containsKey(mac)) {
          // Send a ping by requesting state
          _channels[mac]!.sink.add(jsonEncode({'v': true}));
          _logger.v('Sent heartbeat to $mac');
        }
      } catch (e) {
        _logger.w('Heartbeat failed for $mac: $e');
        final ip = _macToIp[mac];
        if (ip != null) {
          _handleConnectionFailure(
              mac,
              ip,
              WledDevice.fromJson({
                'info': {'mac': mac, 'ip': ip},
                'state': {'on': false, 'bri': 0}
              }));
        }
      }
    });
  }

  // Add reconnection attempt tracking
  final Map<String, int> _reconnectAttempts = {};

  void _handleWsMessage(String mac, dynamic msg, WledDevice base) {
    try {
      final map = jsonDecode(msg);
      if (map is! Map<String, dynamic>) return;

      if (map.containsKey('state') && map['state'].containsKey('transition')) {
        _logger.d('Transition progress: ${map['state']['transition']}');
      }

      Map<String, dynamic> deviceUpdate = {};

      if (map.containsKey('state') && map.containsKey('info')) {
        // Full device update
        deviceUpdate = map;
      } else if (map.containsKey('state')) {
        // State-only update
        deviceUpdate = {
          'state': map['state'],
          'info': base.info.toJson(),
        };
      } else if (map.containsKey('info')) {
        // Info-only update
        deviceUpdate = {
          'state': base.state.toJson(),
          'info': map['info'],
        };
      }

      if (deviceUpdate.isNotEmpty) {
        // Add MAC to the update if not present
        if (!deviceUpdate.containsKey('info') ||
            !deviceUpdate['info'].containsKey('mac')) {
          deviceUpdate['info'] = deviceUpdate['info'] ?? {};
          deviceUpdate['info']['mac'] = mac;
        }

        // Add IP to the update if not present
        if (!deviceUpdate.containsKey('info') ||
            !deviceUpdate['info'].containsKey('ip')) {
          deviceUpdate['info'] = deviceUpdate['info'] ?? {};
          deviceUpdate['info']['ip'] = _macToIp[mac] ?? '';
        }

        // Send update to both device-specific and global streams
        _deviceControllers[mac]?.add(deviceUpdate);
        _stateController.add(deviceUpdate);

        _logger.d(
            'Device state updated via WebSocket - MAC: $mac, Power: ${map['state']?['on']}, Brightness: ${map['state']?['bri']}');
      }
    } catch (e) {
      _logger.w('WS parse error for $mac: $e');
    }
  }

  // ──────────────────────────────────────────────
  // REST command helpers (adapted from WLEDApiService)
  // ──────────────────────────────────────────────

  Future<T> _withRetry<T>(Future<T> Function() op) async {
    int tries = 0;
    while (true) {
      try {
        return await op();
      } catch (e) {
        if (tries++ >= _maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 200 * tries));
      }
    }
  }

  String _resolveIp(String target) {
    // target can be MAC or IP
    if (_macToIp.containsKey(target)) return _macToIp[target]!;
    return target; // assume already an IP
  }

  Future<Map<String, dynamic>> getState(String target) async {
    final ip = _resolveIp(target);

    // Check if cache is still valid
    if (_lastStateCache != null && _lastStateCacheTime != null) {
      final age = DateTime.now().difference(_lastStateCacheTime!);
      if (age < _stateCacheDuration) {
        return _lastStateCache!;
      }
    }

    return _withRetry(() async {
      final res = await _dio.get('http://$ip/json/state');
      _lastStateCache = res.data;
      _lastStateCacheTime = DateTime.now();
      return res.data;
    });
  }

  Future<Map<String, dynamic>> getFullState(String ip) async {
    final response = await http.get(Uri.parse('http://$ip/json'));
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // 🔥 Ensure IP is preserved
    if (json['info'] is Map<String, dynamic>) {
      json['info']['ip'] = ip;
    }

    return json;
  }

  Future<List<String>> getEffects(String target) async {
    final ip = _resolveIp(target);
    return _withRetry(() async {
      try {
        // Try /json/eff first
        final res = await _dio.get('http://$ip/json/eff');
        if (res.data is List) {
          return (res.data as List).map((e) => e.toString()).toList();
        } else {
          throw Exception('Invalid effects data format from /json/eff');
        }
      } catch (e) {
        _logger.w('Failed to get effects from /json/eff, trying /json: $e');
        // Fall back to /json
        final res = await _dio.get('http://$ip/json');
        if (res.data != null && res.data['effects'] != null) {
          final effects = res.data['effects'];
          if (effects is List) {
            return effects.map((e) => e.toString()).toList();
          } else {
            throw Exception('Invalid effects data format from /json');
          }
        }
        throw Exception('No effects found in response');
      }
    });
  }

  Future<List<String>> getPalettes(String target) async {
    final ip = _resolveIp(target);
    return _withRetry(() async {
      try {
        // Try /json/pal first
        final res = await _dio.get('http://$ip/json/pal');
        return List<String>.from(res.data);
      } catch (e) {
        // Fall back to /json
        final res = await _dio.get('http://$ip/json');
        if (res.data != null && res.data['palettes'] != null) {
          return List<String>.from(res.data['palettes']);
        }
        throw Exception('No palettes found in response');
      }
    });
  }

  Future<WledDevice?> getDevice(String ip) async {
    try {
      _logger.i('Fetching device state from $ip');
      final response = await _dio.get('http://$ip/json');
      _logger.i('Got response from $ip: ${response.statusCode}');

      if (response.data == null) {
        _logger.w('No data received from $ip');
        return null;
      }

      // ✅ Ensure IP is set before parsing
      if (response.data['info'] is Map<String, dynamic>) {
        response.data['info']['ip'] = ip;
      }

      final device = WledDevice.fromJson(response.data);
      _logger.i(
          'Successfully parsed device: ${device.info.name} (${device.info.ip})');
      return device;
    } catch (e) {
      _logger.e('Failed to get device from $ip: $e');
      return null;
    }
  }

  // System Commands
  Future<Map<String, dynamic>> sendSystemCommand(
      String target, Map<String, dynamic> command) async {
    final ip = _resolveIp(target);
    return _withRetry(() async {
      final res = await _dio.post(
        'http://$ip/api/system',
        data: command,
      );
      return res.data;
    });
  }

  Future<Map<String, dynamic>> rebootDevice(String target) async {
    return sendSystemCommand(target, {'action': 'reboot'});
  }

  Future<Map<String, dynamic>> factoryReset(String target) async {
    return sendSystemCommand(target, {'action': 'reset'});
  }

  Future<Map<String, dynamic>> clearWiFiSettings(String target) async {
    return sendSystemCommand(target, {'action': 'clear_wifi'});
  }

  Future<Map<String, dynamic>> setDeviceName(String target, String name) async {
    return sendSystemCommand(target, {
      'action': 'set_name',
      'name': name,
    });
  }

  void clearCache() {
    _lastStateCache = null;
    _lastStateCacheTime = null;
  }

  Future<void> _updateState(String ip, Map<String, dynamic> body) async {
    // Debounce to avoid flooding
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      await _withRetry(() => _dio.post('http://$ip/json/state', data: body));
    });
  }

  Future<void> setState(String deviceIp, Map<String, dynamic> state) async {
    _logger.i('Setting state at http://$deviceIp/json/state: $state');
    try {
      final response = await _dio.post(
        'http://$deviceIp/json/state',
        data: state,
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to set state: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Failed to set state', error: e);
      throw Exception('Failed to set state: $e');
    }
  }

  // Public high‑level setters ------------------------------------------------

  Future<void> setPower({
    required String target,
    required bool on,
    int transition = 2, // Default medium transition (0.5s)
  }) async {
    final ip = _resolveIp(target);
    await setState(ip, {
      'on': on,
      'transition': transition,
    });
  }

  Future<void> setBrightness({
    required String target,
    required int brightness,
    int transition = 1, // Default fast transition (0.1s)
  }) async {
    final ip = _resolveIp(target);
    await setState(ip, {
      'bri': brightness.clamp(0, 255),
      'transition': transition,
    });
  }

  Future<void> setColor({
    required String target,
    required List<int> rgb,
    List<int>? rgb2,
    List<int>? rgb3,
  }) async {
    final ip = _resolveIp(target);
    final colors = [rgb, if (rgb2 != null) rgb2, if (rgb3 != null) rgb3];
    await setState(ip, {
      'seg': [
        {'col': colors}
      ]
    });
  }

  Future<void> setEffect({
    required String target,
    required int effectId,
    int? speed,
    int? intensity,
    int? paletteId,
    bool? reversed,
    bool? mirrored,
  }) async {
    final ip = _resolveIp(target);
    final Map<String, dynamic> state = {
      'seg': [
        {
          'fx': effectId,
          if (speed != null) 'sx': speed,
          if (intensity != null) 'ix': intensity,
          if (paletteId != null) 'pal': paletteId,
          if (reversed != null) 'rev': reversed,
          if (mirrored != null) 'mi': mirrored,
        }
      ]
    };
    await setState(ip, state);
  }

  // Raw JSON receiver via WebSocket if available
  void sendRawCommand(String mac, Map<String, dynamic> json) {
    if (_channels.containsKey(mac)) {
      _channels[mac]!.sink.add(jsonEncode(json));
    } else {
      _logger.w('WS not open for $mac, falling back to HTTP');
      final ip = _resolveIp(mac);
      _dio.post('http://$ip/json/state', data: json);
    }
  }

  Future<void> toggleSegment(String target, int segmentId, bool on) async {
    final ip = _resolveIp(target);
    await _withRetry(() async {
      await _dio.post('http://$ip/json/state', data: {
        'seg': [
          {'id': segmentId, 'on': on}
        ]
      });
    });
  }

  Future<void> setSegmentState(String target, int segmentId, bool on) async {
    final ip = _resolveIp(target);
    await _withRetry(() async {
      await _dio.post('http://$ip/json/state', data: {
        'seg': [
          {'id': segmentId, 'on': on}
        ]
      });
    });
  }

  // ──────────────────────────────────────────────
  // Cleanup
  // ──────────────────────────────────────────────
  void dispose() {
    _logger.i('Disposing UnifiedWledService…');
    _debounceTimer?.cancel();
    _mdnsSub?.cancel();
    _mdnsClient?.stop();

    // Clean up all connections
    for (final mac in _channels.keys.toList()) {
      _cleanupConnection(mac);
    }

    _channels.clear();
    _stateController.close();
    for (var controller in _deviceControllers.values) {
      controller.close();
    }
  }

  Future<void> sendCommand(String mac, Map<String, dynamic> command) async {
    try {
      // Prefer WebSocket if available
      if (_channels.containsKey(mac)) {
        _channels[mac]!.sink.add(jsonEncode(command));
      }
      // Fallback to HTTP
      else {
        await _dio.post(
          'http://${_macToIp[mac]}/json/state',
          data: command,
          options: Options(sendTimeout: const Duration(seconds: 1)),
        );
      }
    } catch (e) {
      _logger.e('Command failed for $mac: $e');
    }
  }
}
