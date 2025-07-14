import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/Main_Shell/domain/models/wled_preset.dart';

class PresetService {
  static const String _presetsKey = 'wled_presets';
  final SharedPreferences _prefs;

  PresetService(this._prefs);

  Future<List<WLEDPreset>> getPresets() async {
    final presetsJson = _prefs.getStringList(_presetsKey) ?? [];
    return presetsJson
        .map((json) => WLEDPreset.fromJson(jsonDecode(json)))
        .toList();
  }

  Future<void> savePreset(WLEDPreset preset) async {
    final presets = await getPresets();
    presets.add(preset);
    await _savePresets(presets);
  }

  Future<void> deletePreset(String name) async {
    final presets = await getPresets();
    presets.removeWhere((p) => p.name == name);
    await _savePresets(presets);
  }

  Future<void> _savePresets(List<WLEDPreset> presets) async {
    final presetsJson = presets
        .map((preset) => jsonEncode(preset.toJson()))
        .toList();
    await _prefs.setStringList(_presetsKey, presetsJson);
  }
} 