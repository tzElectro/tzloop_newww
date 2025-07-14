import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Data class for WLED palette
class WledPalette {
  final int id;
  final String name;
  final List<ColorStop> colors;
  final bool isSymbolic;

  WledPalette({
    required this.id,
    required this.name,
    required this.colors,
    this.isSymbolic = false,
  });

  factory WledPalette.fromJson(Map<String, dynamic> json) {
    return WledPalette(
      id: json['id'],
      name: json['name'],
      colors: (json['colors'] as List)
          .map((colorJson) => ColorStop.fromJson(colorJson))
          .toList(),
    );
  }

  factory WledPalette.fromNameAndData(
    int id,
    String name,
    dynamic data,
    List<List<int>> colorSlots,
  ) {
    if (data is List && data.isNotEmpty) {
      if (data[0] is List && data[0].length == 4) {
        // RGB stops
        final colors =
            data.map<ColorStop>((e) => ColorStop.fromJson(e)).toList();
        return WledPalette(
            id: id, name: name, colors: colors, isSymbolic: false);
      } else if (data[0] is String) {
        // Symbolic palette like ["c1", "r"]
        final Map<String, Color> currentColors = {
          'c1': _getColorOrFallback(colorSlots, 0),
          'c2': _getColorOrFallback(colorSlots, 1),
          'c3': _getColorOrFallback(colorSlots, 2),
        };
        final List<ColorStop> resolvedStops = [];
        final int count = data.length;
        for (int i = 0; i < count; i++) {
          final symbol = data[i];
          Color color;
          if (symbol == 'r') {
            color = Colors.grey; // fallback for 'r' (random)
          } else {
            color = currentColors[symbol] ?? Colors.black;
          }
          resolvedStops.add(ColorStop(
            position: (255.0 * (i / count)).round(),
            color: color,
          ));
        }
        return WledPalette(
          id: id,
          name: name,
          colors: resolvedStops,
          isSymbolic: true,
        );
      }
    }
    return WledPalette(id: id, name: name, colors: [], isSymbolic: true);
  }

  static Color _getColorOrFallback(List<List<int>> slots, int index) {
    if (index < slots.length && slots[index].length == 3) {
      return Color.fromRGBO(
          slots[index][0], slots[index][1], slots[index][2], 1.0);
    }
    return Colors.black;
  }
}

// Data class for color stop in a palette
class ColorStop {
  final int position; // 0-255
  final Color color;

  ColorStop({
    required this.position,
    required this.color,
  });

  factory ColorStop.fromJson(List<dynamic> json) {
    // JSON format is [position, r, g, b]
    return ColorStop(
      position: json[0],
      color: Color.fromRGBO(json[1], json[2], json[3], 1.0),
    );
  }
}

@RoutePage()
class PalettePage extends StatefulWidget {
  final String ipAddress;
  const PalettePage({Key? key, required this.ipAddress}) : super(key: key);

  @override
  State<PalettePage> createState() => _PalettePageState();
}

class _PalettePageState extends State<PalettePage> {
  List<WledPalette> palettes = [];
  bool isLoading = true;
  String? error;
  String? selectedPaletteName;

  @override
  void initState() {
    super.initState();
    _fetchPalettes();
  }

  Future<void> _fetchPalettes() async {
    setState(() {
      isLoading = true;
      error = null;
      palettes = [];
    });
    try {
      final String deviceIp = widget.ipAddress;

      // Fetch palette names
      final namesResponse =
          await http.get(Uri.parse('http://$deviceIp/json/pal'));
      if (namesResponse.statusCode != 200) {
        throw Exception(
            'Failed to load palette names: \\${namesResponse.statusCode}');
      }
      final List<dynamic> paletteNamesData = json.decode(namesResponse.body);
      final List<String> paletteNames = List<String>.from(paletteNamesData);

      // Fetch palette color data
      final palxResponse =
          await http.get(Uri.parse('http://$deviceIp/json/palx'));
      if (palxResponse.statusCode != 200) {
        throw Exception(
            'Failed to load palette color data: \\${palxResponse.statusCode}');
      }
      final Map<String, dynamic> palxData = json.decode(palxResponse.body);
      final Map<String, dynamic> paletteColorsData = palxData['p'];

      // Fetch current segment colors (color slots)
      final stateResponse =
          await http.get(Uri.parse('http://$deviceIp/json/state'));
      if (stateResponse.statusCode != 200) {
        throw Exception('Failed to load device state');
      }
      final stateData = json.decode(stateResponse.body);
      final List<dynamic> colorSlotsRaw = stateData['seg']?[0]?['col'] ??
          [
            [255, 0, 0],
            [0, 255, 0],
            [0, 0, 255]
          ];
      final List<List<int>> colorSlots =
          colorSlotsRaw.map<List<int>>((e) => List<int>.from(e)).toList();

      // Combine names and color data
      final List<WledPalette> fetchedPalettes = [];
      for (int i = 0; i < paletteNames.length; i++) {
        final paletteId = i;
        final paletteName = paletteNames[i];
        final colorData = paletteColorsData[paletteId.toString()];
        fetchedPalettes.add(WledPalette.fromNameAndData(
            paletteId, paletteName, colorData, colorSlots));
      }

      setState(() {
        palettes = fetchedPalettes;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Error fetching palettes: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _selectPalette(int index) async {
    // Optimistically update the UI
    setState(() {
      selectedPaletteName = palettes[index].name;
    });

    try {
      // TODO: Replace with actual device IP
      final response = await http.post(
        Uri.parse('http://${widget.ipAddress}/json/state'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'seg': [
            {'pal': palettes[index].id}
          ]
        }), // Use palette ID
      );

      if (response.statusCode != 200) {
        // If the API call fails, revert the UI update and show an error
        setState(() {
          selectedPaletteName = null; // Or the previous selected palette
          // Optionally show a temporary error message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to set palette'),
              backgroundColor: Colors.redAccent,
            ),
          );
        });
        print('Failed to set palette: ${response.statusCode}');
      } else {
        print('Palette set successfully');
        // Optionally show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Palette set successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // If an error occurs, revert the UI update and show an error
      setState(() {
        selectedPaletteName = null; // Or the previous selected palette
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error setting palette: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      });
      print('Error selecting palette: $e');
    }
  }

  LinearGradient? _buildPaletteGradient(dynamic colorsData) {
    if (colorsData is List &&
        colorsData.isNotEmpty &&
        colorsData[0] is List &&
        colorsData[0].length == 4) {
      try {
        final List<ColorStop> colorStops =
            colorsData.map((csJson) => ColorStop.fromJson(csJson)).toList();
        if (colorStops.length < 2) {
          if (colorStops.isNotEmpty) {
            return LinearGradient(
                colors: [colorStops.first.color, colorStops.first.color]);
          }
          return null;
        }
        colorStops.sort((a, b) => a.position.compareTo(b.position));
        final List<Color> colors = colorStops.map((cs) => cs.color).toList();
        final List<double> stops =
            colorStops.map((cs) => cs.position / 255.0).toList();
        return LinearGradient(
          colors: colors,
          stops: stops,
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        );
      } catch (e) {
        return null;
      }
    }
    // Fallback for palettes with string codes or unknown format
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Color Palette'),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchPalettes,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? Center(
                    child:
                        Text(error!, style: const TextStyle(color: Colors.red)))
                : ListView.builder(
                    padding: const EdgeInsets.all(8), // Adjusted padding
                    itemCount: palettes.length,
                    itemBuilder: (context, index) {
                      final palette = palettes[index];
                      final isSelected = selectedPaletteName == palette.name;

                      // Convert ColorStop list to a list of Color and Stop for LinearGradient
                      final List<Color> colors =
                          palette.colors.map((cs) => cs.color).toList();
                      final List<double> stops = palette.colors
                          .map((cs) => cs.position / 255.0)
                          .toList();

                      // Ensure colors and stops lists are not empty and have the same length
                      if (colors.isEmpty ||
                          stops.isEmpty ||
                          colors.length != stops.length) {
                        // Fallback to a simple grey bar or handle error
                        return Card(
                          elevation: isSelected ? 8 : 4,
                          margin: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: isSelected
                                ? const BorderSide(
                                    color: Colors.blueAccent, width: 2)
                                : BorderSide.none,
                          ),
                          child: InkWell(
                            onTap: () => _selectPalette(index),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    palette.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.blueAccent
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    height: 8,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(4),
                                      color: Colors.grey, // Fallback color
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }

                      return Card(
                        elevation: isSelected ? 8 : 4,
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8), // Adjusted margin
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(20), // More rounded corners
                          side: isSelected
                              ? const BorderSide(
                                  color: Colors.blueAccent, width: 2)
                              : BorderSide.none,
                        ),
                        child: InkWell(
                          onTap: () => _selectPalette(index),
                          borderRadius:
                              BorderRadius.circular(20), // More rounded corners
                          child: Padding(
                            padding:
                                const EdgeInsets.all(12.0), // Inner padding
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  palette.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : Colors.black87, // Darker text
                                  ),
                                ),
                                const SizedBox(
                                    height:
                                        8), // Space between text and color bar
                                Container(
                                  height: 8, // Height of the color bar
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        4), // Rounded ends for the bar
                                    gradient: LinearGradient(
                                      colors: colors,
                                      stops: stops,
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
