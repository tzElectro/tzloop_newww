import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';

final effectsCacheProvider =
    Provider<EffectsCacheService>((ref) => EffectsCacheService());

class EffectsCacheService {
  final Map<String, CachedEffectData> _cache = {};

  bool isCacheValid(String deviceIp) {
    final cached = _cache[deviceIp];
    if (cached == null) return false;

    final cacheAge = DateTime.now().difference(cached.timestamp);
    return cacheAge < const Duration(minutes: 5); // Cache valid for 5 minutes
  }

  void cacheEffectData(
    String deviceIp,
    List<WLEDEffect> effects,
    Map<String, Map<String, int>> parameters,
    int? selectedEffectId,
  ) {
    _cache[deviceIp] = CachedEffectData(
      effects: effects,
      parameters: parameters,
      selectedEffectId: selectedEffectId,
      timestamp: DateTime.now(),
    );
  }

  CachedEffectData? getCachedData(String deviceIp) => _cache[deviceIp];

  void clearCache(String? deviceIp) {
    if (deviceIp != null) {
      _cache.remove(deviceIp);
    } else {
      _cache.clear();
    }
  }

  // Helper method to update just the selected effect
  void updateSelectedEffect(String deviceIp, int effectId) {
    final cached = _cache[deviceIp];
    if (cached != null) {
      _cache[deviceIp] = CachedEffectData(
        effects: cached.effects,
        parameters: cached.parameters,
        selectedEffectId: effectId,
        timestamp: cached.timestamp,
      );
    }
  }

  // Helper method to update effect parameters
  void updateEffectParameters(
    String deviceIp,
    int effectId,
    Map<String, int> parameters,
  ) {
    final cached = _cache[deviceIp];
    if (cached != null) {
      final updatedParameters =
          Map<String, Map<String, int>>.from(cached.parameters);
      updatedParameters[effectId.toString()] = parameters;

      _cache[deviceIp] = CachedEffectData(
        effects: cached.effects,
        parameters: updatedParameters,
        selectedEffectId: cached.selectedEffectId,
        timestamp: cached.timestamp,
      );
    }
  }
}

class CachedEffectData {
  final List<WLEDEffect> effects;
  final Map<String, Map<String, int>> parameters;
  final int? selectedEffectId;
  final DateTime timestamp;

  CachedEffectData({
    required this.effects,
    required this.parameters,
    required this.selectedEffectId,
    required this.timestamp,
  });
}
