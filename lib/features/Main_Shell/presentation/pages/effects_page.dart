 import 'dart:async';

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/wled_effect_service.dart';
import '../../domain/models/device_provider.dart';
import '../../domain/models/wled_effect.dart';
import 'package:tzloop_newww/core/widgets/effects_grid_widget.dart';

@RoutePage()
class EffectsPage extends ConsumerWidget {
  const EffectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(deviceProvider);
    final currentDevice = devices.isNotEmpty ? devices.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Effects'),
        centerTitle: true,
      ),
      body: currentDevice == null
          ? const Center(
              child: Text('No device connected'),
            )
          : EffectsGrid(
              deviceMac: currentDevice.info.mac,
              onEffectSelected: (effect) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied effect: ${effect.name}'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
    );
  }
}

class _EffectsPageState extends ConsumerState<EffectsPage> {
  final _effectService = WledEffectService();
  final List<WLEDEffect> _effects = [];
  final Map<int, Map<String, int>> _effectParameters = {};
  int _currentEffect = -1;
  bool _isLoading = true;
  Timer? _debounceTimer;
  String _selectedCategory = 'All';

  String get deviceIp {
    final devices = ref.read(deviceProvider);
    if (devices.isEmpty) return '';
    final ip = devices.first.info.ip;
    if (ip.isEmpty || ip == '0.0.0.0' || ip == 'localhost') {
      // Try to trigger device discovery if we don't have a valid IP
      ref.read(deviceProvider.notifier).discoverDevices();
      return '';
    }
    return ip;
  }

  String get deviceMac {
    final devices = ref.read(deviceProvider);
    return devices.isNotEmpty ? devices.first.info.mac : '';
  }

  @override
  void initState() {
    super.initState();
    _loadEffectsAndState();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEffectsAndState() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    final ip = deviceIp;
    if (ip.isEmpty) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Searching for WLED devices...'),
            duration: Duration(seconds: 2),
          ),
        );
        // Start device discovery
        ref.read(deviceProvider.notifier).discoverDevices();
      }
      return;
    }

    try {
      await _loadEffects();
      await _loadCurrentState();
    } catch (e) {
      print('Error loading effects and state: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadEffectsAndState,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadEffects() async {
    try {
      final effects = await _effectService.getEffectsWithCategories(deviceIp);
      if (mounted) {
        setState(() {
          _effects.clear();
          _effects.addAll(effects);
        });
      }

      if (effects.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No effects found on the device'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error loading effects: $e');
      rethrow;
    }
  }

  Future<void> _loadCurrentState() async {
    try {
      setState(() => _isLoading = true);
      final deviceNotifier = ref.read(deviceProvider.notifier);
      final devices = ref.read(deviceProvider);
      if (devices.isEmpty) return;

      final currentDevice = devices.first;
      final currentEffectId = currentDevice.state.seg.isNotEmpty
          ? currentDevice.state.seg[0].fx
          : 0;

      setState(() {
        _currentEffect = currentEffectId;
        _isLoading = false;
      });

      // Load effect parameters using the new service
      final params =
          await _effectService.getEffectParameters(deviceIp, currentEffectId);
      if (mounted) {
        setState(() {
          _effectParameters[currentEffectId] = params;
        });
      }
    } catch (e) {
      debugPrint('Error loading current state: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load device state. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showEffectParametersBottomSheet(WLEDEffect effect) {
    final parameters =
        _effectParameters[effect.id] ?? {'sx': 128, 'ix': 128, 'pal': 0};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _effectService.getEffectIcon(effect.category ?? 'Other'),
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                effect.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (effect.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  effect.category!,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
              ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _EffectParameterSlider(
                label: 'Speed',
                value: parameters['sx']!.toDouble(),
                onChanged: (value) {
                  setState(() {
                    parameters['sx'] = value.round();
                  });
                  _updateEffectParameters(effect.id, parameters);
                },
              ),
              const SizedBox(height: 16),
              _EffectParameterSlider(
                label: 'Intensity',
                value: parameters['ix']!.toDouble(),
                onChanged: (value) {
                  setState(() {
                    parameters['ix'] = value.round();
                  });
                  _updateEffectParameters(effect.id, parameters);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateEffectParameters(int effectId, Map<String, int> parameters) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      try {
        await _effectService.updateEffectParameters(
            deviceIp, effectId, parameters);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update effect: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    });
  }

  List<String> get categories {
    final cats = _effects.map((e) => e.category ?? 'Other').toSet().toList();
    cats.sort();
    return ['All', ...cats];
  }

  List<WLEDEffect> get filteredEffects {
    if (_selectedCategory == 'All') return _effects;
    return _effects.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.purpleAccent),
        ),
      );
    }

    if (_effects.isEmpty) {
      return const Center(
        child: Text(
          'No effects available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Column(
          children: [
            // Heading
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              alignment: Alignment.centerLeft,
              child: const Text(
                'Effects',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Categories
            Container(
              height: 48,
              margin: const EdgeInsets.only(top: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      backgroundColor: Colors.black26,
                      selectedColor: Colors.deepPurple.withOpacity(0.3),
                      checkmarkColor: Colors.deepPurple,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Effects list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEffects.length,
                itemBuilder: (context, index) {
                  final effect = filteredEffects[index];
                  final isSelected = effect.id == _currentEffect;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _currentEffect = effect.id);
                          final deviceNotifier =
                              ref.read(deviceProvider.notifier);
                          deviceNotifier.sendCommand(deviceMac, {
                            'seg': [
                              {
                                'fx': effect.id,
                              }
                            ]
                          });
                          _showEffectParametersBottomSheet(effect);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.deepPurple.withOpacity(0.3)
                                : Colors.black26,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.deepPurple
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _effectService
                                    .getEffectIcon(effect.category ?? 'Other'),
                                color: isSelected
                                    ? Colors.deepPurple
                                    : Colors.white54,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      effect.name,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.white70,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (effect.category != null) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        effect.category!,
                                        style: TextStyle(
                                          color: isSelected
                                              ? Colors.white70
                                              : Colors.white38,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.deepPurple,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EffectParameterSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _EffectParameterSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.purpleAccent,
            inactiveTrackColor: Colors.purpleAccent.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.purple.withOpacity(0.2),
            trackHeight: 4.0,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 8.0,
              pressedElevation: 8.0,
            ),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0),
            trackShape: const RoundedRectSliderTrackShape(),
          ),
          child: Slider(
            value: value,
            min: 0,
            max: 255,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
