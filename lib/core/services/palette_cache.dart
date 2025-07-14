import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final paletteCacheProvider =
    Provider<PaletteCacheService>((ref) => PaletteCacheService());

class PaletteCacheService {
  final Map<String, CachedPaletteData> _cache = {};

  bool isCacheValid(String deviceIp) {
    final cached = _cache[deviceIp];
    if (cached == null) return false;

    final cacheAge = DateTime.now().difference(cached.timestamp);
    return cacheAge < const Duration(minutes: 5); // Cache valid for 5 minutes
  }

  void cachePaletteData(String deviceIp, List<String> names,
      Map<String, List<Color>> previewColors, String? selectedName) {
    _cache[deviceIp] = CachedPaletteData(
      names: names,
      previewColors: previewColors,
      selectedName: selectedName,
      timestamp: DateTime.now(),
    );
  }

  CachedPaletteData? getCachedData(String deviceIp) => _cache[deviceIp];

  void clearCache(String? deviceIp) {
    if (deviceIp != null) {
      _cache.remove(deviceIp);
    } else {
      _cache.clear();
    }
  }
}

class CachedPaletteData {
  final List<String> names;
  final Map<String, List<Color>> previewColors;
  final String? selectedName;
  final DateTime timestamp;

  CachedPaletteData({
    required this.names,
    required this.previewColors,
    required this.selectedName,
    required this.timestamp,
  });
}
