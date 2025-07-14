// lib/models/wled_device.dart
import 'package:tzloop_newww/core/models/wled_state.dart';
import 'package:tzloop_newww/core/models/wled_info.dart';

class WledDevice {
  final WledState state;
  final WledInfo info;
  final List<String> effects;
  final List<String> palettes;

  WledDevice({
    required this.state,
    required this.info,
    required this.effects,
    required this.palettes,
  });

  factory WledDevice.fromJson(Map<String, dynamic> json) {
    return WledDevice(
      // Ensure null-safety for potentially missing top-level keys
      state: WledState.fromJson(json['state'] as Map<String, dynamic>? ?? {}),
      info: WledInfo.fromJson(json['info'] as Map<String, dynamic>? ?? {}),
      // Handle potentially null lists by providing an empty list as fallback
      effects: List<String>.from(json['effects'] as List? ?? []),
      palettes: List<String>.from(json['palettes'] as List? ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'state': state.toJson(),
      'info': info.toJson(),
      'effects': effects,
      'palettes': palettes,
    };
  }

  WledDevice copyWith({
    WledState? state,
    WledInfo? info,
    List<String>? effects,
    List<String>? palettes,
  }) {
    return WledDevice(
      state: state ?? this.state,
      info: info ?? this.info,
      effects: effects ?? this.effects,
      palettes: palettes ?? this.palettes,
    );
  }
}
