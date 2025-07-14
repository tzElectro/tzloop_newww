import 'package:flutter/material.dart';

class SegmentInstance {
  final int id;
  final String name;
  final int start;
  final int stop;
  Color color;
  int effectId;
  int brightness;
  bool isActive;
  Map<String, dynamic> effectParameters;

  SegmentInstance({
    required this.id,
    this.name = '',
    required this.start,
    required this.stop,
    this.color = Colors.white,
    this.effectId = 0,
    this.brightness = 255,
    this.isActive = true,
    this.effectParameters = const {},
  });

  // Create from JSON
  factory SegmentInstance.fromJson(Map<String, dynamic> json) {
    return SegmentInstance(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      start: json['start'] ?? 0,
      stop: json['stop'] ?? 0,
      color: Color.fromRGBO(
        json['col']?[0]?[0] ?? 255,
        json['col']?[0]?[1] ?? 255,
        json['col']?[0]?[2] ?? 255,
        1,
      ),
      effectId: json['fx'] ?? 0,
      brightness: json['bri'] ?? 255,
      isActive: json['on'] ?? true,
      effectParameters: {
        'speed': json['sx'] ?? 128,
        'intensity': json['ix'] ?? 128,
        'palette': json['pal'] ?? 0,
        'reverse': json['rev'] ?? false,
        'mirror': json['mi'] ?? false,
      },
    );
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start,
      'stop': stop,
      'col': [
        [color.red, color.green, color.blue]
      ],
      'fx': effectId,
      'bri': brightness,
      'on': isActive,
      'sx': effectParameters['speed'],
      'ix': effectParameters['intensity'],
      'pal': effectParameters['palette'],
      'rev': effectParameters['reverse'],
      'mi': effectParameters['mirror'],
    };
  }

  // Create a copy with modified properties
  SegmentInstance copyWith({
    int? id,
    String? name,
    int? start,
    int? stop,
    Color? color,
    int? effectId,
    int? brightness,
    bool? isActive,
    Map<String, dynamic>? effectParameters,
  }) {
    return SegmentInstance(
      id: id ?? this.id,
      name: name ?? this.name,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      color: color ?? this.color,
      effectId: effectId ?? this.effectId,
      brightness: brightness ?? this.brightness,
      isActive: isActive ?? this.isActive,
      effectParameters: effectParameters ?? Map.from(this.effectParameters),
    );
  }

  // Get total number of LEDs in this segment
  int get totalLeds => stop - start;

  // Check if this is the master segment
  bool get isMaster => id == 0;

  @override
  String toString() {
    return 'SegmentInstance(id: $id, name: $name, start: $start, stop: $stop, totalLeds: $totalLeds)';
  }
} 