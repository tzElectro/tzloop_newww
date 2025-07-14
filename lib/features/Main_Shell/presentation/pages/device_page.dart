import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tzloop_newww/core/models/wled_device.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/device_card.dart';
// import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/draggable_device_grid.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/add_new_device_card.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/device_provider.dart';
import 'package:tzloop_newww/core/widgets/empty_discovery_state.dart';
import 'package:tzloop_newww/core/widgets/discovery_status.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tzloop_newww/core/widgets/feedback_manager.dart';
import 'package:logger/logger.dart';

@RoutePage()
class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  bool _isSearching = false;
  String _discoveryStatus = 'Pull to refresh';
  bool _hasError = false;
  Timer? _discoveryTimer;
  final Logger _logger = Logger();

  @override
  void initState() {
    super.initState();
    _startAutoDiscovery();
  }

  @override
  void dispose() {
    _discoveryTimer?.cancel();
    super.dispose();
  }

  void _startAutoDiscovery() {
    _discoveryTimer?.cancel();
    _discoveryTimer =
        Timer.periodic(const Duration(seconds: 30), (_) => _startDiscovery());
  }

  Future<void> _startDiscovery() async {
    if (_isSearching) return;

    setState(() {
      _isSearching = true;
      _hasError = false;
      _discoveryStatus = 'Searching for devices...';
    });

    try {
      await ref.read(deviceProvider.notifier).discoverDevices();
      setState(() {
        _discoveryStatus = 'Updated ${TimeOfDay.now().format(context)}';
        _hasError = false;
      });
    } catch (e) {
      setState(() {
        _discoveryStatus = 'Error: ${e.toString().split(':').last.trim()}';
        _hasError = true;
      });

      if (mounted) {
        context.showError('Failed to discover devices: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  Future<void> _toggleDevice(WledDevice device) async {
    if (device.info.ip.isEmpty) {
      if (mounted) {
        context
            .showError('Device IP is not available. Trying to rediscover...');
      }
      await _startDiscovery();
      return;
    }

    try {
      // Send command first
      await ref.read(deviceProvider.notifier).sendCommand(
        device.info.ip,
        {'on': !device.state.on, 'transition': 2},
      );

      // Update local state only after successful command
      final devices = ref.read(deviceProvider);
      final index = devices.indexWhere((d) => d.info.mac == device.info.mac);
      if (index != -1) {
        final updatedDevice = device.copyWith(
          state: device.state.copyWith(on: !device.state.on),
        );
        ref.read(deviceProvider.notifier).updateDevice(index, updatedDevice);
      }
    } catch (e) {
      if (mounted) {
        context
            .showError('Failed to toggle ${device.info.name}: ${e.toString()}');
      }
      // Try to rediscover devices if IP is invalid
      if (e.toString().contains('IP cannot be empty') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        _startDiscovery();
      }
    }
  }

  Future<void> _changeBrightness(WledDevice device, double value) async {
    if (device.info.ip.isEmpty) {
      if (mounted) {
        context
            .showError('Device IP is not available. Trying to rediscover...');
      }
      await _startDiscovery();
      return;
    }

    try {
      // Send command first
      await ref.read(deviceProvider.notifier).sendCommand(
        device.info.ip,
        {'bri': (value / 100 * 255).round(), 'transition': 1},
      );

      // Update local state only after successful command
      final devices = ref.read(deviceProvider);
      final index = devices.indexWhere((d) => d.info.mac == device.info.mac);
      if (index != -1) {
        final updatedDevice = device.copyWith(
          state: device.state.copyWith(bri: (value / 100 * 255).round()),
        );
        ref.read(deviceProvider.notifier).updateDevice(index, updatedDevice);
      }
    } catch (e) {
      if (mounted) {
        context.showError(
            'Failed to change brightness for ${device.info.name}: ${e.toString()}');
      }
      // Try to rediscover devices if IP is invalid
      if (e.toString().contains('IP cannot be empty') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        _startDiscovery();
      }
    }
  }

  void _navigateToColorPage(BuildContext context, WledDevice device) {
    if (device.info.mac.isEmpty ||
        device.info.ip.isEmpty ||
        device.info.name.isEmpty) {
      context.showError('Device details are missing');
      return;
    }

    context.router.pushNamed(
      '/device/${device.info.name}/${device.info.ip}/color',
    );
  }

  void _handleDevicesReorder(List<WledDevice> newDevices) {
    // Here you can implement the logic to persist the new order
    // For now, we'll just update the UI
    final currentDevices = ref.read(deviceProvider);
    final reorderedDevices = newDevices.map((deviceData) {
      return currentDevices.firstWhere(
        (device) => device.info.mac == deviceData.info.mac,
      );
    }).toList();

    // Update the provider with the new order
    ref.read(deviceProvider.notifier).reorderDevices(reorderedDevices);
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(deviceProvider);
    _logger.i('DevicePage rebuild with ${devices.length} devices');

    return RefreshIndicator(
      onRefresh: _startDiscovery,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: DiscoveryStatus(
                status: _discoveryStatus,
                isLoading: _isSearching,
              ),
            ),
          ),
          if (devices.isEmpty)
            const SliverFillRemaining(
              child: EmptyDiscoveryState(),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio:
                      0.85, // Changed from 1.5 to make cards taller
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                ),
                itemCount: devices.length + 1,
                itemBuilder: (ctx, index) {
                  if (index == devices.length) {
                    return const AddNewDeviceCard();
                  }
                  final device = devices[index];
                  return DeviceCard(
                    key: ValueKey(device.info.mac),
                    title: device.info.name,
                    deviceIp: device.info.ip,
                    isOn: device.state.on,
                    brightness:
                        (device.state.bri / 255 * 100).round().toDouble(),
                    onToggle: (value) => _toggleDevice(device),
                    onBrightnessChange: (value) =>
                        _changeBrightness(device, value),
                    onTap: () => _navigateToColorPage(context, device),
                    // isDraggable: false,
                    index: index,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
