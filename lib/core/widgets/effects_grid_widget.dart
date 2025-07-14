import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tzloop_newww/core/services/effects_cache_service.dart';
import 'package:tzloop_newww/core/services/wled_effect_service.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/device_provider.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';

// EffectGridItem widget for displaying individual effects
class EffectGridItem extends StatelessWidget {
  final WLEDEffect effect;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;

  const EffectGridItem({
    super.key,
    required this.effect,
    required this.isSelected,
    required this.onTap,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 4,
      margin: const EdgeInsets.all(4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.purpleAccent : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? Colors.purpleAccent : Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                effect.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.purpleAccent : Colors.grey[800],
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (effect.category != null) ...[
                const SizedBox(height: 4),
                Text(
                  effect.category!,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EffectsGrid extends ConsumerStatefulWidget {
  final ValueChanged<WLEDEffect>? onEffectSelected;
  final String? deviceMac;

  const EffectsGrid({
    super.key,
    this.onEffectSelected,
    this.deviceMac,
  });

  @override
  ConsumerState<EffectsGrid> createState() => _EffectsGridState();
}

class _EffectsGridState extends ConsumerState<EffectsGrid> {
  final _effectService = WledEffectService();
  List<WLEDEffect> _effects = [];
  int? _selectedEffectId;
  bool _isLoading = true;
  String? _error;
  String _selectedCategory = 'All';
  static const int maxRetries = 3;
  int _retryCount = 0;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _loadEffects();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadEffects() async {
    if (_isDisposed) return;

    List devices = [];
    try {
      devices = ref.read(deviceProvider);
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        _error = 'Error accessing device provider';
        _isLoading = false;
      });
      return;
    }

    final currentDevice = devices.isNotEmpty ? devices.first : null;

    if (currentDevice == null) {
      if (_isDisposed) return;
      setState(() {
        _error = 'No WLED device connected';
        _isLoading = false;
      });
      return;
    }

    EffectsCacheService? cacheService;
    try {
      cacheService = ref.read(effectsCacheProvider);
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        _error = 'Error accessing cache service';
        _isLoading = false;
      });
      return;
    }

    final deviceIp = currentDevice.info.ip;

    // Check cache first
    if (cacheService?.isCacheValid(deviceIp) ?? false) {
      final cachedData = cacheService?.getCachedData(deviceIp);
      if (cachedData != null && !_isDisposed) {
        setState(() {
          _effects = cachedData.effects;
          _selectedEffectId = cachedData.selectedEffectId;
          _isLoading = false;
        });
        return;
      }
    }

    if (_isDisposed) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final effects = await _effectService.getEffectsWithCategories(deviceIp);
      final currentState =
          await _effectService.getEffectParameters(deviceIp, 0);
      final currentEffectId = currentState['fx'] ?? 0;

      if (_isDisposed) return;

      // Cache the fetched data
      cacheService?.cacheEffectData(
        deviceIp,
        effects,
        {}, // Initialize empty parameters map
        currentEffectId,
      );

      setState(() {
        _effects = effects;
        _selectedEffectId = currentEffectId;
        _isLoading = false;
      });
    } catch (e) {
      if (_isDisposed) return;
      setState(() {
        _error = 'Error loading effects: $e';
        _isLoading = false;
      });

      // Implement retry logic
      if (_retryCount < maxRetries && !_isDisposed) {
        _retryCount++;
        await Future.delayed(Duration(seconds: _retryCount * 2));
        await _loadEffects();
      }
    }
  }

  Future<void> _selectEffect(WLEDEffect effect) async {
    if (widget.deviceMac == null || _isDisposed) return;

    EffectsCacheService? cacheService;
    List devices = [];
    try {
      cacheService = ref.read(effectsCacheProvider);
      devices = ref.read(deviceProvider);
    } catch (e) {
      if (_isDisposed) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accessing providers: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentDevice = devices.isNotEmpty ? devices.first : null;
    if (currentDevice == null) return;

    try {
      // Update UI optimistically
      if (!_isDisposed) {
        setState(() => _selectedEffectId = effect.id);
      }

      // Update cache
      cacheService?.updateSelectedEffect(currentDevice.info.ip, effect.id);

      // Send command to device
      final deviceNotifier = ref.read(deviceProvider.notifier);
      await deviceNotifier.sendCommand(
        widget.deviceMac!,
        {
          'seg': [
            {'fx': effect.id}
          ]
        },
      );

      // Notify parent if callback is provided
      widget.onEffectSelected?.call(effect);
    } catch (e) {
      // Revert UI on error
      if (!_isDisposed) {
        setState(() => _selectedEffectId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply effect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _retryCount = 0;
                _loadEffects();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Categories filter
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: categories.map((category) {
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(category),
                  onSelected: (selected) {
                    setState(() => _selectedCategory = category);
                  },
                  selectedColor: Colors.purpleAccent.withOpacity(0.2),
                  checkmarkColor: Colors.purpleAccent,
                ),
              );
            }).toList(),
          ),
        ),
        // Effects grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: filteredEffects.length,
            itemBuilder: (context, index) {
              final effect = filteredEffects[index];
              return EffectGridItem(
                effect: effect,
                isSelected: effect.id == _selectedEffectId,
                onTap: () => _selectEffect(effect),
                icon: _effectService.getEffectIcon(effect.category ?? 'Other'),
              );
            },
          ),
        ),
      ],
    );
  }
}
