import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tzloop_newww/core/models/wled_device.dart';
import 'package:tzloop_newww/core/services/wled_api_service.dart';
import 'package:tzloop_newww/core/services/device_discovery_service.dart';
import 'package:logger/logger.dart';

class DeviceNotifier extends StateNotifier<List<WledDevice>> {
  final UnifiedWledService _apiService;
  final DeviceDiscoveryService _discoveryService;
  final Logger _logger = Logger();

  bool _isDiscovering = false;
  Timer? _autoRediscoveryTimer;

  DeviceNotifier({
    UnifiedWledService? apiService,
    DeviceDiscoveryService? discoveryService,
  })  : _apiService = apiService ?? UnifiedWledService(),
        _discoveryService = discoveryService ?? DeviceDiscoveryService(),
        super([]) {
    _startAutoDiscovery();
  }

  void _startAutoDiscovery() {
    _autoRediscoveryTimer?.cancel();
    _autoRediscoveryTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (state.isEmpty) {
        discoverDevices();
      }
    });
  }

  Future<void> discoverDevices() async {
    if (_isDiscovering) return;
    _isDiscovering = true;
    try {
      _logger.i('Starting device discovery...');
      final devices = await _discoveryService.discoverDevices();

      _logger.i('Initial discovery result: ${devices.length} devices');
      for (var device in devices) {
        _logger.i(
            'Found device: ${device.info.name} (${device.info.ip}) MAC: ${device.info.mac}');
      }

      if (devices.isEmpty) {
        _logger.w('No devices found during discovery');
        return;
      }

      _logger.i('Found ${devices.length} devices, validating...');
      final validDevices = <WledDevice>[];

      for (final device in devices) {
        try {
          _logger
              .i('Validating device: ${device.info.name} at ${device.info.ip}');
          // Verify we can get the device state
          final deviceState = await _apiService.getDevice(device.info.ip);
          if (deviceState != null) {
            validDevices.add(deviceState);
            _logger.i(
                '✅ Validated device: ${device.info.name} at ${device.info.ip}');
          } else {
            _logger.w('❌ Device state null for: ${device.info.name}');
          }
        } catch (e) {
          _logger.e('❌ Failed to validate device ${device.info.name}: $e');
        }
      }

      if (validDevices.isEmpty) {
        _logger.w('No valid devices found after validation');
        return;
      }

      _logger.i('Setting ${validDevices.length} validated devices to state');
      state = validDevices;
      _logger.i('Current state now has ${state.length} devices');
    } catch (e, stack) {
      _logger.e('Discovery failed', error: e, stackTrace: stack);
    } finally {
      _isDiscovering = false;
    }
  }

  Future<void> sendCommand(
      String deviceIp, Map<String, dynamic> command) async {
    // ✅ Add detailed logging before validation
    print('🔍 sendCommand called with IP: "$deviceIp"');
    print('📦 Command: $command');

    if (deviceIp.isEmpty) {
      print('❌ Device IP is empty!');
      throw Exception('Device IP cannot be empty');
    }

    // ✅ Safer IP validation with int.tryParse
    final parts = deviceIp.split('.');
    if (parts.length != 4) {
      print(
          '❌ Invalid IP format: $deviceIp (expected 4 parts, got ${parts.length})');
      throw Exception('Invalid IP address format: $deviceIp');
    }

    for (var part in parts) {
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) {
        print('❌ Invalid IP part: "$part" in IP: $deviceIp');
        throw Exception('Invalid IP address part: $part');
      }
    }

    print('✅ IP validation passed: $deviceIp');

    // Find device in state
    final deviceIndex = state.indexWhere((d) => d.info.ip == deviceIp);
    if (deviceIndex == -1) {
      print('⚠️ Device not found in state for IP: $deviceIp');
      print(
          '📋 Available devices: ${state.map((d) => '${d.info.name}(${d.info.ip})').join(', ')}');
      _logger.w('Device not found in state, attempting to rediscover...');
      await discoverDevices();
      // Check again after discovery
      if (!state.any((d) => d.info.ip == deviceIp)) {
        print('❌ Device still not found after rediscovery');
        throw Exception('Device not found: $deviceIp');
      }
    }

    print('📡 Sending command to $deviceIp: $command');
    _logger.i('Sending command to device at $deviceIp: $command');

    // Try to send command with retries
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        await _apiService.setState(deviceIp, command);
        print('✅ Command sent successfully to $deviceIp');
        _logger.i('✅ Command sent successfully to $deviceIp');
        break;
      } catch (e) {
        retryCount++;
        print('❌ Command failed (attempt $retryCount): $e');
        _logger.w('Command failed, retry $retryCount: $e');
        if (retryCount == 3) rethrow;
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }

    // Update device state after successful command
    try {
      final updatedDevice = await _apiService.getDevice(deviceIp);
      if (updatedDevice != null) {
        final updatedIndex = state.indexWhere((d) => d.info.ip == deviceIp);
        if (updatedIndex != -1) {
          state = List<WledDevice>.from(state)..[updatedIndex] = updatedDevice;
          print('✅ Device state updated successfully');
          _logger.i('✅ Device state updated successfully');
        }
      }
    } catch (e) {
      print('⚠️ Failed to update device state: $e');
      _logger.w('Failed to update device state: $e');
    }
  }

  Future<void> refreshDevice(String deviceIp) async {
    try {
      _logger.i('Refreshing device state for $deviceIp');
      final updatedDevice = await _apiService.getDevice(deviceIp);
      if (updatedDevice != null) {
        final deviceIndex = state.indexWhere((d) => d.info.ip == deviceIp);
        if (deviceIndex != -1) {
          state = List<WledDevice>.from(state)..[deviceIndex] = updatedDevice;
          _logger
              .i('✅ Device refreshed successfully: ${updatedDevice.info.name}');
        } else {
          _logger.w('Device not found in state for refresh: $deviceIp');
        }
      } else {
        _logger.w('Failed to get updated device state for: $deviceIp');
      }
    } catch (e) {
      _logger.e('Error refreshing device $deviceIp: $e');
      rethrow;
    }
  }

  void updateDevice(int index, WledDevice device) {
    if (index >= 0 && index < state.length) {
      state = List<WledDevice>.from(state)..[index] = device;
      _logger.i('Updated device at index $index: ${device.info.name}');
    }
  }

  void reorderDevices(List<WledDevice> newOrder) {
    _logger.i('Reordering devices');
    state = List<WledDevice>.from(newOrder);
  }

  bool get isDiscovering => _isDiscovering;

  @override
  void dispose() {
    _autoRediscoveryTimer?.cancel();
    super.dispose();
  }
}

// Service and Provider Setup
final wledApiServiceProvider = Provider<UnifiedWledService>((ref) {
  final service = UnifiedWledService();
  ref.onDispose(() => service.dispose());
  return service;
});

final deviceProvider =
    StateNotifierProvider<DeviceNotifier, List<WledDevice>>((ref) {
  return DeviceNotifier();
});

// Used to inject deviceIp into subroutes or tabs
final scopedDeviceIpProvider = Provider<String>((ref) {
  throw UnimplementedError(); // To be overridden in AutoRoute wrapper
});
