import 'package:flutter/material.dart';
import '../../features/Main_Shell/domain/models/wled_effect.dart';
import 'wled_api_service.dart';
import 'package:hive/hive.dart';
import 'dart:convert';

class WledEffectService {
  final UnifiedWledService _apiService;
  final Box<String> _effectsBox;
  static const cacheDuration = Duration(minutes: 5);

  WledEffectService({UnifiedWledService? apiService})
      : _apiService = apiService ?? UnifiedWledService(),
        _effectsBox = Hive.box<String>('effects_cache');

  // Direct effect categorization
  String categorizeEffect(String effectName) {
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

  // Get effect icon based on category
  IconData getEffectIcon(String category) {
    switch (category.toLowerCase()) {
      case 'static':
        return Icons.lightbulb_outline;
      case 'dynamic':
        return Icons.animation;
      case 'rainbow':
        return Icons.gradient;
      case 'special':
        return Icons.star_outline;
      case 'holiday':
        return Icons.celebration;
      case 'music':
        return Icons.music_note;
      case 'chase':
        return Icons.directions_run;
      case 'strobe':
        return Icons.flash_on;
      case 'fade':
        return Icons.opacity;
      case 'fire':
        return Icons.local_fire_department;
      default:
        return Icons.auto_fix_high;
    }
  }

  // Direct API calls for effects
  Future<void> setEffect({
    required String deviceIp,
    required int effectId,
    int? speed,
    int? intensity,
    int? paletteId,
    bool? reversed,
    bool? mirrored,
  }) async {
    try {
      // Normalize speed and intensity values
      final normalizedSpeed =
          speed != null ? (speed / 255.0).clamp(0.0, 1.0) * 255 : null;
      final normalizedIntensity =
          intensity != null ? (intensity / 255.0).clamp(0.0, 1.0) * 255 : null;

      await _apiService.setEffect(
        target: deviceIp,
        effectId: effectId,
        speed: normalizedSpeed?.round(),
        intensity: normalizedIntensity?.round(),
        paletteId: paletteId,
        reversed: reversed,
        mirrored: mirrored,
      );

      // Verify the effect was set correctly
      final state = await _apiService.getState(deviceIp);
      final currentEffect = state['seg']?[0]?['fx'];
      if (currentEffect != effectId) {
        throw Exception(
            'Failed to set effect: Device returned different effect ID');
      }
    } catch (e) {
      print('Error setting effect: $e');
      rethrow;
    }
  }

  // Get all effects with categories
  Future<List<WLEDEffect>> getEffectsWithCategories(String deviceIp) async {
    try {
      // Try to get fresh data first
      try {
        final effects = await _fetchEffects(deviceIp);
        // Update cache with new data
        await _effectsBox.put(
          deviceIp,
          jsonEncode({
            'timestamp': DateTime.now().toIso8601String(),
            'effects': effects.map((e) => e.toJson()).toList(),
          }),
        );
        return effects;
      } catch (e) {
        print('Failed to fetch fresh effects: $e');
        // On failure, try to use cache
        final cached = _effectsBox.get(deviceIp);
        if (cached != null) {
          final Map<String, dynamic> decodedData = jsonDecode(cached);
          final timestamp = DateTime.parse(decodedData['timestamp'] as String);
          final age = DateTime.now().difference(timestamp);

          if (age < cacheDuration) {
            final List<dynamic> effectsData = decodedData['effects'] as List;
            return effectsData.map((effectData) {
              if (effectData is Map<String, dynamic>) {
                return WLEDEffect.fromJson(effectData);
              } else {
                throw Exception('Invalid cached effect data format');
              }
            }).toList();
          }
        }
        // If cache is too old or invalid, rethrow the original error
        rethrow;
      }
    } catch (e) {
      print('Error getting effects with categories: $e');
      rethrow;
    }
  }

  // Get effect parameters
  Future<Map<String, int>> getEffectParameters(
      String deviceIp, int effectId) async {
    final state = await _apiService.getState(deviceIp);
    return {
      'sx': state['seg']?[0]?['sx'] ?? 128,
      'ix': state['seg']?[0]?['ix'] ?? 128,
      'pal': state['seg']?[0]?['pal'] ?? 0,
    };
  }

  // Update effect parameters
  Future<void> updateEffectParameters(
      String deviceIp, int effectId, Map<String, int> parameters) async {
    await _apiService.setState(deviceIp, {
      'seg': [
        {
          'fx': effectId,
          'sx': parameters['sx'],
          'ix': parameters['ix'],
          'pal': parameters['pal'],
        }
      ]
    });
  }

  Future<List<WLEDEffect>> _fetchEffects(String deviceIp) async {
    try {
      final effectNames = await _apiService.getEffects(deviceIp);

      // Handle response as list of strings
      return effectNames
          .asMap()
          .entries
          .map((entry) => WLEDEffect(
                id: entry.key,
                name: entry.value,
                category: categorizeEffect(entry.value),
              ))
          .toList();
    } catch (e) {
      print('Error fetching effects: $e');
      rethrow;
    }
  }
}
