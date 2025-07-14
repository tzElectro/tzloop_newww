// lib/features/deviceInstance/color_pallete/widgets/pallete_grid_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:tzloop_newww/features/Main_Shell/domain/models/device_provider.dart';
import 'package:tzloop_newww/core/services/palette_cache.dart';

// PaletteGridItem widget for displaying individual palettes
class PaletteGridItem extends StatelessWidget {
  final String paletteName;
  final bool isSelected;
  final VoidCallback onTap;
  final List<Color>? previewColors;

  const PaletteGridItem({
    super.key,
    required this.paletteName,
    required this.isSelected,
    required this.onTap,
    this.previewColors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: previewColors != null && previewColors!.isNotEmpty
              ? LinearGradient(
                  colors: previewColors!,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: previewColors == null ? Colors.grey[800] : null,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.purpleAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              paletteName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}

class PaletteGrid extends ConsumerStatefulWidget {
  final ValueChanged<Color>? onColorSelected;

  const PaletteGrid({
    super.key,
    this.onColorSelected,
  });

  @override
  ConsumerState<PaletteGrid> createState() => _PaletteGridState();
}

class _PaletteGridState extends ConsumerState<PaletteGrid> {
  List<String> _paletteNames = [];
  final Map<String, List<Color>> _palettePreviewColors = {};
  String? _selectedPaletteName;
  bool _isLoading = true;
  String? _error;
  static const int maxRetries = 3;
  int _retryCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchPalettes();
  }

  Future<void> _fetchPalettes() async {
    final devices = ref.read(deviceProvider);
    final currentDevice = devices.isNotEmpty ? devices.first : null;

    if (currentDevice == null) {
      setState(() {
        _error = 'No WLED device connected';
        _isLoading = false;
      });
      return;
    }

    final cacheService = ref.read(paletteCacheProvider);
    final deviceIp = currentDevice.info.ip;

    // Check cache first
    if (cacheService.isCacheValid(deviceIp)) {
      final cachedData = cacheService.getCachedData(deviceIp);
      if (cachedData != null) {
        setState(() {
          _paletteNames = cachedData.names;
          _palettePreviewColors.clear();
          _palettePreviewColors.addAll(cachedData.previewColors);
          _selectedPaletteName = cachedData.selectedName;
          _isLoading = false;
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final namesResponse =
          await http.get(Uri.parse('http://$deviceIp/json/pal'));
      if (namesResponse.statusCode != 200) {
        throw Exception('Failed to load palette names');
      }
      _paletteNames = List<String>.from(json.decode(namesResponse.body));

      // Then get the full state to get current palette
      final stateResponse =
          await http.get(Uri.parse('http://$deviceIp/json/state'));
      if (stateResponse.statusCode != 200) {
        throw Exception('Failed to load device state');
      }
      final stateData = json.decode(stateResponse.body);
      final currentPaletteId = stateData['seg']?[0]?['pal'] ?? 0;

      // Finally get the palette color data
      final palxResponse =
          await http.get(Uri.parse('http://$deviceIp/json/palx'));
      if (palxResponse.statusCode != 200) {
        throw Exception('Failed to load palette colors');
      }
      final palxData = json.decode(palxResponse.body);

      // Clear existing preview colors
      _palettePreviewColors.clear();

      // Process each palette's color data
      for (var i = 0; i < _paletteNames.length; i++) {
        final paletteName = _paletteNames[i];
        final paletteData = palxData[i.toString()];

        if (paletteData != null) {
          List<Color> colors = [];

          // Handle different palette data formats
          if (paletteData is List) {
            for (var colorPoint in paletteData) {
              if (colorPoint is List && colorPoint.length >= 3) {
                // RGB format
                colors.add(Color.fromRGBO(
                  colorPoint[0],
                  colorPoint[1],
                  colorPoint[2],
                  1.0,
                ));
              }
            }
          }

          if (colors.isNotEmpty) {
            _palettePreviewColors[paletteName] = colors;
          }
        }
      }

      // Set the currently selected palette
      if (currentPaletteId >= 0 && currentPaletteId < _paletteNames.length) {
        _selectedPaletteName = _paletteNames[currentPaletteId];
      }

      // Cache successful response
      cacheService.cachePaletteData(
        deviceIp,
        _paletteNames,
        _palettePreviewColors,
        _selectedPaletteName,
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error loading palettes: $e';
        _isLoading = false;
      });
      // Trigger retry if needed
      if (_retryCount < maxRetries) {
        _retryCount++;
        await Future.delayed(
            Duration(seconds: _retryCount * 2)); // Exponential backoff
        await _fetchPalettes();
      }
    }
  }

  Future<void> _applyPalette(String paletteName) async {
    final devices = ref.read(deviceProvider);
    final currentDevice = devices.isNotEmpty ? devices.first : null;
    if (currentDevice == null) return;

    final cacheService = ref.read(paletteCacheProvider);
    cacheService
        .clearCache(currentDevice.info.ip); // Clear cache for this device

    final paletteIndex = _paletteNames.indexOf(paletteName);
    if (paletteIndex == -1) return;

    try {
      // Update UI optimistically
      setState(() => _selectedPaletteName = paletteName);

      // Send command to device
      final deviceNotifier = ref.read(deviceProvider.notifier);
      deviceNotifier.sendCommand(
        currentDevice.info.mac,
        {
          'seg': [
            {'pal': paletteIndex}
          ]
        },
      );
    } catch (e) {
      // Revert UI on error
      setState(() => _selectedPaletteName = null);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply palette: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                _retryCount = 0; // Reset retry count
                _fetchPalettes();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.0,
        mainAxisSpacing: 12.0,
        childAspectRatio: 1.5,
      ),
      itemCount: _paletteNames.length,
      itemBuilder: (context, index) {
        final paletteName = _paletteNames[index];
        return PaletteGridItem(
          paletteName: paletteName,
          isSelected: _selectedPaletteName == paletteName,
          onTap: () => _applyPalette(paletteName),
          previewColors: _palettePreviewColors[paletteName],
        );
      },
    );
  }
}
