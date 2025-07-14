import 'package:flutter/material.dart';

class WLEDPreset {
  final String name;
  final int brightness;
  final List<WLEDSegment> segments;

  const WLEDPreset({
    required this.name,
    required this.brightness,
    required this.segments,
  });

  Map<String, dynamic> toJson() {
    return {
      'on': true,
      'bri': brightness,
      'seg': segments.map((s) => s.toJson()).toList(),
    };
  }

  factory WLEDPreset.fromJson(Map<String, dynamic> json) {
    return WLEDPreset(
      name: json['name'] ?? 'Preset',
      brightness: json['bri'] as int,
      segments: (json['seg'] as List)
          .map((s) => WLEDSegment.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class WLEDSegment {
  final int id;
  final int start;
  final int stop;
  final Color color;
  final Color? color2;
  final Color? color3;
  final int effectId;
  final int? paletteId;
  final bool selected;
  final bool reversed;
  final bool mirrored;
  final int? speed;
  final int? intensity;
  final Map<String, int>? effectParameters;

  const WLEDSegment({
    required this.id,
    required this.start,
    required this.stop,
    required this.color,
    this.color2,
    this.color3,
    required this.effectId,
    this.paletteId,
    this.selected = false,
    this.reversed = false,
    this.mirrored = false,
    this.speed,
    this.intensity,
    this.effectParameters,
  });

  WLEDSegment copyWith({
    int? id,
    int? start,
    int? stop,
    Color? color,
    Color? color2,
    Color? color3,
    int? effectId,
    int? paletteId,
    bool? selected,
    bool? reversed,
    bool? mirrored,
    int? speed,
    int? intensity,
    Map<String, int>? effectParameters,
  }) {
    return WLEDSegment(
      id: id ?? this.id,
      start: start ?? this.start,
      stop: stop ?? this.stop,
      color: color ?? this.color,
      color2: color2 ?? this.color2,
      color3: color3 ?? this.color3,
      effectId: effectId ?? this.effectId,
      paletteId: paletteId ?? this.paletteId,
      selected: selected ?? this.selected,
      reversed: reversed ?? this.reversed,
      mirrored: mirrored ?? this.mirrored,
      speed: speed ?? this.speed,
      intensity: intensity ?? this.intensity,
      effectParameters: effectParameters ?? this.effectParameters,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start': start,
      'stop': stop,
      'col': [
        [color.red, color.green, color.blue],
        if (color2 != null) [color2!.red, color2!.green, color2!.blue],
        if (color3 != null) [color3!.red, color3!.green, color3!.blue],
      ],
      'fx': effectId,
      if (paletteId != null) 'pal': paletteId,
      if (selected) 'sel': true,
      if (reversed) 'rev': true,
      if (mirrored) 'mi': true,
      if (speed != null) 'sx': speed,
      if (intensity != null) 'ix': intensity,
      if (effectParameters != null) ...effectParameters!,
    };
  }

  factory WLEDSegment.fromJson(Map<String, dynamic> json) {
    final colorList = (json['col'] as List).cast<List<int>>();
    return WLEDSegment(
      id: json['id'] ?? 0,
      start: json['start'] as int,
      stop: json['stop'] as int,
      color: Color.fromARGB(255, colorList[0][0], colorList[0][1], colorList[0][2]),
      color2: colorList.length > 1 ? Color.fromARGB(255, colorList[1][0], colorList[1][1], colorList[1][2]) : null,
      color3: colorList.length > 2 ? Color.fromARGB(255, colorList[2][0], colorList[2][1], colorList[2][2]) : null,
      effectId: json['fx'] as int,
      paletteId: json['pal'] as int?,
      selected: json['sel'] as bool? ?? false,
      reversed: json['rev'] as bool? ?? false,
      mirrored: json['mi'] as bool? ?? false,
      speed: json['sx'] as int?,
      intensity: json['ix'] as int?,
      effectParameters: json['sx'] != null || json['ix'] != null || json['pal'] != null
          ? {
              if (json['sx'] != null) 'sx': json['sx'] as int,
              if (json['ix'] != null) 'ix': json['ix'] as int,
              if (json['pal'] != null) 'pal': json['pal'] as int,
            }
          : null,
    );
  }
}
