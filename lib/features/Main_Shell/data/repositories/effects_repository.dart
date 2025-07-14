import 'dart:async';
import '../../../../core/services/wled_api_service.dart';
import '../../domain/models/wled_effect.dart';

class EffectsRepository {
  final UnifiedWledService _apiService;
  final Map<String, List<WLEDEffect>> _cache = {};
  final Map<String, DateTime> _cacheTimestamp = {};
  static const _cacheDuration = Duration(minutes: 5);

  EffectsRepository() : _apiService = UnifiedWledService();

  Future<List<WLEDEffect>> getEffects(String ip) async {
    if (ip.isEmpty) {
      throw Exception('Invalid IP address');
    }

    // Check cache first
    if (_cache.containsKey(ip)) {
      final timestamp = _cacheTimestamp[ip];
      if (timestamp != null &&
          DateTime.now().difference(timestamp) < _cacheDuration) {
        return _cache[ip]!;
      }
    }

    try {
      // Get effects using the API service
      final effectNames = await _apiService.getEffects(ip);
      final effects = _createEffectsList(effectNames);
      _cacheResults(ip, effects);
      return effects;
    } catch (e) {
      print('Error fetching effects: $e');
      throw Exception('Failed to fetch effects: $e');
    }
  }

  List<WLEDEffect> _createEffectsList(List<String> effectNames) {
    final effects = <WLEDEffect>[];
    for (var i = 0; i < effectNames.length; i++) {
      // Skip reserved effects
      if (effectNames[i] == 'RSVD' || effectNames[i] == '-') {
        continue;
      }
      effects.add(WLEDEffect(
        id: i,
        name: effectNames[i],
        category: _categorizeEffect(effectNames[i]),
      ));
    }
    return effects;
  }

  void _cacheResults(String ip, List<WLEDEffect> effects) {
    _cache[ip] = effects;
    _cacheTimestamp[ip] = DateTime.now();
  }

  String _categorizeEffect(String effectName) {
    final name = effectName.toLowerCase();
    if (name.contains('solid') || name.contains('static')) {
      return 'Static';
    } else if (name.contains('rainbow') || name.contains('spectrum')) {
      return 'Rainbow';
    } else if (name.contains('chase') || name.contains('run')) {
      return 'Movement';
    } else if (name.contains('twinkle') || name.contains('sparkle')) {
      return 'Sparkle';
    } else if (name.contains('fire') || name.contains('flame')) {
      return 'Fire';
    } else if (name.contains('noise') || name.contains('cloud')) {
      return 'Noise';
    } else {
      return 'Other';
    }
  }

  Future<Map<String, int>> getEffectParameters(
      String ipAddress, int effectId) async {
    try {
      final state = await _apiService.getState(ipAddress);
      return {
        'sx': state['seg']?[0]?['sx'] ?? 128,
        'ix': state['seg']?[0]?['ix'] ?? 128,
        'pal': state['seg']?[0]?['pal'] ?? 0,
      };
    } catch (e) {
      return {
        'sx': 128,
        'ix': 128,
        'pal': 0,
      };
    }
  }

  void clearCache(String ipAddress) {
    _cache.remove(ipAddress);
    _cacheTimestamp.remove(ipAddress);
    _apiService.clearCache();
  }
}
