import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:multicast_dns/multicast_dns.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:logger/logger.dart';
import 'package:pool/pool.dart';
import 'package:hive/hive.dart';
import '../models/wled_device.dart';
import 'wled_api_service.dart';

class DeviceDiscoveryService {
  final UnifiedWledService _apiService;
  final Logger _logger;
  final NetworkInfo _networkInfo;
  final MDnsClient _mdns = MDnsClient();
  Timer? _retryTimer;
  final StreamController<String> _progressController =
      StreamController<String>.broadcast();
  bool _isSearching = false;
  static const Duration _connectionTimeout = Duration(seconds: 30);
  static const Duration _discoveryTimeout = Duration(minutes: 2);
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 3);

  // Add persistent storage for MAC to IP mappings
  static const String _macToIpKey = 'mac_to_ip_mappings';
  final Box<Map<dynamic, dynamic>>? _macToIpBox;

  DeviceDiscoveryService()
      : _apiService = UnifiedWledService(),
        _logger = Logger(),
        _networkInfo = NetworkInfo(),
        _macToIpBox = Hive.box<Map<dynamic, dynamic>>('device_mappings');

  Stream<String> get progressStream => _progressController.stream;

  Future<List<WledDevice>> discoverDevices() async {
    if (_isSearching) {
      _logger.w('Discovery already in progress');
      return [];
    }
    _isSearching = true;

    try {
      _logger.i('Starting device discovery...');
      _progressController.add('Starting discovery...');

      // Get WiFi IP to determine mode
      String? wifiIP;
      int retryCount = 0;

      while (wifiIP == null && retryCount < _maxRetries) {
        wifiIP = await _networkInfo.getWifiIP();
        if (wifiIP == null) {
          _logger.w(
              'Failed to get WiFi IP, attempt ${retryCount + 1}/$_maxRetries');
          await Future.delayed(_retryDelay);
          retryCount++;
        }
      }

      _logger.i('WiFi IP: $wifiIP');

      if (wifiIP == null) {
        _progressController.add(
            'No WiFi connection detected. Please check your WiFi settings and permissions.');
        return [];
      }

      List<WledDevice> devices = [];

      // Check if we're in AP mode (4.3.2.1)
      if (wifiIP.startsWith('4.')) {
        _logger.i('Detected AP mode connection');
        _progressController.add('Checking AP mode connection...');

        final apDevice = await _checkAPModeDevice();
        if (apDevice != null) {
          _logger.i('Successfully connected to AP mode device');
          return [apDevice];
        } else {
          _progressController.add(
              'AP mode connection failed. Please ensure you are connected to the WLED device\'s WiFi');
          return [];
        }
      }

      // Try to restore devices from cache first
      devices = await _restoreFromCache();
      if (devices.isNotEmpty) {
        _logger.i('Restored ${devices.length} devices from cache');
        _progressController.add('Found ${devices.length} cached devices');
      }

      // Home network mode - try mDNS first, then subnet scan
      _logger.i('Scanning home network...');
      _progressController.add('Scanning home network...');

      // Try mDNS discovery first with retries
      if (!kIsWeb) {
        retryCount = 0;
        List<WledDevice> mdnsDevices = [];

        while (mdnsDevices.isEmpty && retryCount < _maxRetries) {
          try {
            mdnsDevices = await _discoverWithMDNS().timeout(_discoveryTimeout);
            for (var device in mdnsDevices) {
              if (!_isDuplicate(device, devices)) {
                devices.add(device);
              }
            }
          } catch (e) {
            _logger.w('mDNS discovery attempt ${retryCount + 1} failed: $e');
            await Future.delayed(_retryDelay);
          }
          retryCount++;
        }

        if (devices.isNotEmpty) {
          _logger.i('Found ${devices.length} devices via mDNS');
          await _cacheDevices(devices);
        }
      }

      // If no devices found, try subnet scan with retries
      if (devices.isEmpty) {
        final subnet = wifiIP.substring(0, wifiIP.lastIndexOf('.'));
        _logger.i('Performing subnet scan: $subnet.*');
        _progressController.add('Scanning local network...');

        retryCount = 0;
        while (devices.isEmpty && retryCount < _maxRetries) {
          try {
            final scanDevices = await _scanNetwork().timeout(_discoveryTimeout);
            for (var device in scanDevices) {
              if (!_isDuplicate(device, devices)) {
                devices.add(device);
              }
            }
          } catch (e) {
            _logger.w('Network scan attempt ${retryCount + 1} failed: $e');
            await Future.delayed(_retryDelay);
          }
          retryCount++;
        }

        if (devices.isNotEmpty) {
          _logger.i('Found ${devices.length} devices via network scan');
          await _cacheDevices(devices);
        }
      }

      if (devices.isEmpty) {
        _logger.w('No devices found after all attempts');
        _progressController.add(
            'No devices found. Please check your network connection and try again.');
      }

      return devices;
    } catch (e, stackTrace) {
      _logger.e('Discovery error', error: e, stackTrace: stackTrace);
      _progressController.add('Error: ${e.toString()}');
      return [];
    } finally {
      _isSearching = false;
    }
  }

  Future<List<WledDevice>> _performNetworkDiscovery() async {
    List<WledDevice> devices = [];
    int retryCount = 0;
    const maxRetries = 3;

    while (devices.isEmpty && retryCount < maxRetries) {
      try {
        if (!kIsWeb) {
          // Try mDNS first
          devices.addAll(await _discoverWithMDNS());
          if (devices.isNotEmpty) {
            _logger.i('Found ${devices.length} devices via mDNS');
            _progressController.add('Found via mDNS: ${devices.length}');
          }

          // Fall back to network scan
          if (devices.isEmpty) {
            devices.addAll(await _scanNetwork());
          }
        }

        // Validate found devices
        devices = devices
            .where((device) => _isValidDeviceIp(device.info.ip))
            .toList();

        // Initialize devices
        for (var device in devices) {
          await _initializeDevice(device);
        }

        if (devices.isEmpty && retryCount < maxRetries - 1) {
          _progressController
              .add('Retrying... (${retryCount + 1}/$maxRetries)');
          await Future.delayed(const Duration(seconds: 2));
        }
      } catch (e) {
        _logger.e('Discovery error: $e');
        _progressController.add('Error: ${e.toString()}');
      }
      retryCount++;
    }

    _progressController.add('Discovery complete');
    return devices;
  }

  Future<List<WledDevice>> _scanNetwork() async {
    if (kIsWeb) return [];

    final wifiIP = await _networkInfo.getWifiIP();
    if (!_isValidDeviceIp(wifiIP)) {
      _logger.w('Invalid WiFi IP: $wifiIP');
      _progressController.add('No valid network connection');
      return [];
    }

    final subnet = wifiIP!.substring(0, wifiIP.lastIndexOf('.'));
    _logger.i('Scanning subnet: $subnet.*');
    _progressController.add('Scanning network...');

    final devices = <WledDevice>[];
    final pool = Pool(10);

    await Future.wait(
      List.generate(
        254,
        (i) => pool.withResource(() async {
          final ip = '$subnet.${i + 1}';
          if (await testConnection(ip)) {
            try {
              final device = await _validateDevice(ip);
              if (device != null && !_isDuplicate(device, devices)) {
                devices.add(device);
                _logger.i('Found WLED at $ip: ${device.info.name}');
                _progressController.add('Found: ${device.info.name}');
              }
            } catch (e) {
              _logger.v('$ip: Not a WLED device');
            }
          }
        }),
      ),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        _logger.w('Network scan timed out');
        return [];
      },
    );

    _logger.i('Network scan complete. Found ${devices.length} devices');
    return devices;
  }

  Future<bool> testConnection(String ip, {int retryCount = 0}) async {
    try {
      final socket = await Socket.connect(ip, 80, timeout: _connectionTimeout);
      socket.destroy();
      return true;
    } catch (e) {
      if (retryCount < _maxRetries) {
        await Future.delayed(_retryDelay * (retryCount + 1));
        return testConnection(ip, retryCount: retryCount + 1);
      }
      return false;
    }
  }

  Future<List<WledDevice>> _discoverWithMDNS() async {
    final devices = <WledDevice>[];

    try {
      // Start mDNS discovery
      await _mdns.start();
      _logger.i('Started mDNS discovery');
      _progressController.add('Searching for WLED devices...');

      // Query for WLED devices with retry logic
      int retryCount = 0;
      while (devices.isEmpty && retryCount < _maxRetries) {
        try {
          await for (final PtrResourceRecord ptr in _mdns
              .lookup<PtrResourceRecord>(
                ResourceRecordQuery.serverPointer('_wled._tcp.local'),
              )
              .timeout(_connectionTimeout)) {
            _logger.i('Found mDNS service: ${ptr.domainName}');

            try {
              // Get device details with timeout
              final srv = await _mdns
                  .lookup<SrvResourceRecord>(
                    ResourceRecordQuery.service(ptr.domainName),
                  )
                  .timeout(_connectionTimeout)
                  .first;

              final a = await _mdns
                  .lookup<IPAddressResourceRecord>(
                    ResourceRecordQuery.addressIPv4(srv.target),
                  )
                  .timeout(_connectionTimeout)
                  .first;

              final ip = a.address.address;
              _logger.i('Found WLED device at $ip');

              // Validate device with retries
              WledDevice? device = await _validateDevice(ip);
              if (device != null && !_isDuplicate(device, devices)) {
                devices.add(device);
                _progressController.add('Found device: ${device.info.name}');

                // Cache successful device
                if (device.info.mac.isNotEmpty) {
                  await _saveMacToIpMapping(device.info.mac, ip);
                }
              }
            } catch (e) {
              _logger.w('Error processing mDNS device: $e');
              continue;
            }
          }
        } catch (e) {
          _logger.w('mDNS lookup attempt ${retryCount + 1} failed: $e');
          if (retryCount < _maxRetries - 1) {
            await Future.delayed(_retryDelay);
          }
        }
        retryCount++;
      }
    } catch (e) {
      _logger.e('mDNS discovery error: $e');
      _progressController.add('Error during device discovery');
    } finally {
      try {
        _mdns.stop();
      } catch (e) {
        _logger.w('Error stopping mDNS: $e');
      }
    }

    return devices;
  }

  Future<WledDevice?> _validateDevice(String ip) async {
    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        final deviceJson = await _apiService.getFullState(ip);
        if (deviceJson['info'] is Map<String, dynamic>) {
          // Always ensure IP is set
          deviceJson['info']['ip'] = ip;
          final device = WledDevice.fromJson(deviceJson);

          // Double check IP validity
          if (!_isValidDeviceIp(device.info.ip)) {
            _logger.w('Invalid IP after validation: ${device.info.ip}');
            return null;
          }

          return device;
        }
      } catch (e) {
        _logger.w(
            'Device validation attempt ${retryCount + 1} failed for $ip: $e');
        if (retryCount < _maxRetries - 1) {
          await Future.delayed(_retryDelay);
        }
      }
      retryCount++;
    }
    return null;
  }

  // Helper Methods
  bool _isValidDeviceIp(String? ip) {
    return ip != null &&
        ip.isNotEmpty &&
        ip != "0.0.0.0" &&
        ip != "localhost" &&
        RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip);
  }

  bool _isDuplicate(WledDevice newDevice, List<WledDevice> existing) {
    return existing.any((d) =>
        d.info.mac == newDevice.info.mac ||
        (d.info.ip == newDevice.info.ip && d.info.name == newDevice.info.name));
  }

  Future<void> _initializeDevice(WledDevice device) async {
    try {
      if (device.state.bri == 0) {
        await _apiService.setState(device.info.ip, {'bri': 128, 'on': true});
      }
    } catch (e) {
      _logger.e('Init failed for ${device.info.name}: $e');
    }
  }

  // Caching
  Future<void> _cacheDevices(List<WledDevice> devices) async {
    try {
      final mappings = <String, String>{};
      for (var device in devices) {
        if (device.info.mac.isNotEmpty && device.info.ip.isNotEmpty) {
          mappings[device.info.mac] = device.info.ip;
        }
      }
      await _macToIpBox?.put(_macToIpKey, mappings);
    } catch (e) {
      _logger.e('Error caching devices: $e');
    }
  }

  Future<List<WledDevice>> _loadCachedDevices() async {
    try {
      final box = await Hive.openBox('wled_devices');
      final cached = box.get('devices', defaultValue: []) as List;
      return cached.map((json) => WledDevice.fromJson(json)).toList();
    } catch (e) {
      _logger.e('Cache load failed: $e');
      return [];
    }
  }

  // Add this new method for direct IP validation
  Future<bool> validateDeviceIp(String ip) async {
    try {
      final socket = await Socket.connect(ip, 80,
          timeout: const Duration(milliseconds: 800));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<WledDevice?> _checkAPModeDevice() async {
    const apIP = '4.3.2.1'; // Default WLED AP mode IP
    _logger.i('Trying to connect to AP mode device at $apIP');

    try {
      // First check if we can reach the device
      if (!await testConnection(apIP)) {
        _logger.w('Could not connect to AP mode device');
        return null;
      }

      // Add retry logic with exponential backoff for 503 errors
      int retryCount = 0;
      const maxRetries = 3;
      while (retryCount < maxRetries) {
        try {
          // Try to get device info
          final deviceInfo = await _apiService.getFullState(apIP);

          // Ensure the IP is set in the device info
          if (deviceInfo['info'] is Map<String, dynamic>) {
            deviceInfo['info']['ip'] = apIP;
          }

          final device = WledDevice.fromJson(deviceInfo);
          _logger.i(
              'Successfully found AP mode device: ${device.info.name} at $apIP');

          // Save the MAC to IP mapping if we have both
          if (device.info.mac.isNotEmpty) {
            await _saveMacToIpMapping(device.info.mac, apIP);
          }

          return device;
        } catch (e) {
          if (e.toString().contains('503')) {
            retryCount++;
            if (retryCount < maxRetries) {
              // Exponential backoff: 500ms, 1s, 1.5s
              final delay = Duration(milliseconds: 500 * retryCount);
              _logger.w(
                  'AP mode 503 error, retrying in ${delay.inMilliseconds}ms...');
              await Future.delayed(delay);
              continue;
            }
          }
          rethrow;
        }
      }
      return null;
    } catch (e) {
      _logger.e('Error connecting to AP mode device', error: e);
      return null;
    }
  }

  // Add methods for managing MAC to IP mappings
  Future<void> _saveMacToIpMapping(String mac, String ip) async {
    try {
      final mappings = _macToIpBox?.get(_macToIpKey, defaultValue: {}) ?? {};
      mappings[mac] = ip;
      await _macToIpBox?.put(_macToIpKey, mappings);
      _logger.i('Saved MAC to IP mapping: $mac → $ip');
    } catch (e) {
      _logger.e('Failed to save MAC to IP mapping', error: e);
    }
  }

  Map<String, String> _loadMacToIpMappings() {
    try {
      final mappings = _macToIpBox?.get(_macToIpKey, defaultValue: {}) ?? {};
      return Map<String, String>.from(mappings);
    } catch (e) {
      _logger.e('Failed to load MAC to IP mappings', error: e);
      return {};
    }
  }

  Future<List<WledDevice>> _restoreFromCache() async {
    final devices = <WledDevice>[];
    try {
      final mappings = _macToIpBox?.get(_macToIpKey) as Map<dynamic, dynamic>?;
      if (mappings != null) {
        for (var entry in mappings.entries) {
          final mac = entry.key.toString();
          final ip = entry.value.toString();

          if (_isValidDeviceIp(ip)) {
            final device = await _validateDevice(ip);
            if (device != null && !_isDuplicate(device, devices)) {
              devices.add(device);
              _logger
                  .i('Restored device from cache: ${device.info.name} at $ip');
            }
          } else {
            _logger.w('Removing invalid cached IP: $ip for MAC: $mac');
            await _removeMacToIpMapping(mac);
          }
        }
      }
    } catch (e) {
      _logger.e('Error restoring from cache: $e');
    }
    return devices;
  }

  Future<void> _removeMacToIpMapping(String mac) async {
    try {
      final mappings = _macToIpBox?.get(_macToIpKey) as Map<dynamic, dynamic>?;
      if (mappings != null) {
        mappings.remove(mac);
        await _macToIpBox?.put(_macToIpKey, mappings);
      }
    } catch (e) {
      _logger.w('Error removing MAC mapping: $e');
    }
  }

  void dispose() {
    _retryTimer?.cancel();
    _mdns.stop();
    _progressController.close();
  }
}
