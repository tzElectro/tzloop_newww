import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../../../core/services/device_discovery_service.dart';
import '../../../../core/router/app_router.dart';

@RoutePage()
class EffectsGalleryPage extends StatefulWidget {
  const EffectsGalleryPage({super.key});

  @override
  State<EffectsGalleryPage> createState() => _EffectsGalleryPageState();
}

class _EffectsGalleryPageState extends State<EffectsGalleryPage> {
  final _discoveryService = DeviceDiscoveryService();
  final List<String> _devices = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final devices = await _discoveryService.discoverDevices();
      setState(() {
        _devices.clear();
        _devices.addAll(devices.map((d) => d.info.ip));
      });
    } catch (e) {
      debugPrint('Error discovering devices: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showDeviceSelector(BuildContext context, Map<String, dynamic> effect) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Device',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (_devices.isEmpty)
              const Text('No devices found')
            else
              ListView.builder(
                shrinkWrap: true,
                itemCount: _devices.length,
                itemBuilder: (context, index) {
                  final ip = _devices[index];
                  return ListTile(
                    leading: const Icon(Icons.lightbulb_outline),
                    title: const Text('WLED Device'),
                    subtitle: Text(ip),
                    onTap: () {
                      Navigator.pop(context);
                      context.router.push(
                        const EffectsRoute(),
                      );
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effects = [
      {
        'name': 'Solid',
        'id': 0,
        'icon': Icons.lightbulb_outline,
        'parameters': [],
      },
      {
        'name': 'Blink',
        'id': 1,
        'icon': Icons.flash_on,
        'parameters': [
          {'name': 'Speed', 'min': 0, 'max': 255, 'default': 128},
        ],
      },
      {
        'name': 'Breathe',
        'id': 2,
        'icon': Icons.waves,
        'parameters': [
          {'name': 'Speed', 'min': 0, 'max': 255, 'default': 128},
          {'name': 'Intensity', 'min': 0, 'max': 255, 'default': 128},
        ],
      },
      {
        'name': 'Rainbow',
        'id': 3,
        'icon': Icons.palette,
        'parameters': [],
      },
      {
        'name': 'Rainbow Cycle',
        'id': 4,
        'icon': Icons.replay_circle_filled,
        'parameters': [],
      },
      {
        'name': 'Scanner',
        'id': 5,
        'icon': Icons.scanner,
        'parameters': [],
      },
      {
        'name': 'Dual Scanner',
        'id': 6,
        'icon': Icons.compare_arrows,
        'parameters': [],
      },
      {
        'name': 'Running Pixels',
        'id': 7,
        'icon': Icons.run_circle,
        'parameters': [],
      },
      {
        'name': 'Twinkle',
        'id': 8,
        'icon': Icons.auto_awesome,
        'parameters': [],
      },
      {
        'name': 'Fireworks',
        'id': 9,
        'icon': Icons.celebration,
        'parameters': [],
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effects Gallery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDevices,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: effects.length,
              itemBuilder: (context, index) {
                final effect = effects[index];
                return Card(
                  child: InkWell(
                    onTap: () => _showDeviceSelector(context, effect),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          effect['icon'] as IconData,
                          size: 32,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          effect['name'] as String,
                          style: Theme.of(context).textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
