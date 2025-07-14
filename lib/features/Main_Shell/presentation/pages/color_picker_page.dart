import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:auto_route/auto_route.dart';
import 'package:tzloop_newww/core/widgets/brightness_slider.dart';
import 'package:tzloop_newww/core/services/wled_api_service.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/device_provider.dart';
import 'package:tzloop_newww/core/services/wled_effect_service.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';
import 'package:tzloop_newww/core/utils/debouncer.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/color_wheel_section.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/effects_list_section.dart';
import 'package:collection/collection.dart';
import '../../../../core/theme/app_colors.dart';

// View Model for Color Picker
class ColorPickerViewModel {
  final List<WLEDEffect> effects;
  final int? selectedEffectId;
  final bool isLoading;
  final bool effectsExpanded;
  final double currentBrightness;
  final Color currentColor;
  final Map<int, double> effectSpeeds;
  final Map<int, double> effectIntensities;

  const ColorPickerViewModel({
    required this.effects,
    this.selectedEffectId,
    required this.isLoading,
    required this.effectsExpanded,
    required this.currentBrightness,
    required this.currentColor,
    required this.effectSpeeds,
    required this.effectIntensities,
  });

  ColorPickerViewModel copyWith({
    List<WLEDEffect>? effects,
    int? selectedEffectId,
    bool? isLoading,
    bool? effectsExpanded,
    double? currentBrightness,
    Color? currentColor,
    Map<int, double>? effectSpeeds,
    Map<int, double>? effectIntensities,
  }) {
    return ColorPickerViewModel(
      effects: effects ?? this.effects,
      selectedEffectId: selectedEffectId ?? this.selectedEffectId,
      isLoading: isLoading ?? this.isLoading,
      effectsExpanded: effectsExpanded ?? this.effectsExpanded,
      currentBrightness: currentBrightness ?? this.currentBrightness,
      currentColor: currentColor ?? this.currentColor,
      effectSpeeds: effectSpeeds ?? this.effectSpeeds,
      effectIntensities: effectIntensities ?? this.effectIntensities,
    );
  }

  static ColorPickerViewModel initial() {
    return const ColorPickerViewModel(
      effects: [],
      selectedEffectId: null,
      isLoading: true,
      effectsExpanded: true,
      currentBrightness: 1.0, // Changed from 100.0 to 1.0 (0-1 range)
      currentColor: Colors.red,
      effectSpeeds: {},
      effectIntensities: {},
    );
  }
}

// State Notifier for Color Picker
class ColorPickerStateNotifier extends StateNotifier<ColorPickerViewModel> {
  final WledEffectService _effectService;
  ColorPickerStateNotifier(this._effectService)
      : super(ColorPickerViewModel.initial());

  Future<void> loadEffects(String deviceIp) async {
    try {
      final effects = await _effectService.getEffectsWithCategories(deviceIp);
      state = state.copyWith(effects: effects, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      ErrorHandler.showError('Error loading effects: $e');
    }
  }

  void toggleEffectsExpanded() {
    state = state.copyWith(effectsExpanded: !state.effectsExpanded);
  }

  void updateBrightness(double value) {
    state = state.copyWith(currentBrightness: value);
  }

  void updateColor(Color color) {
    state = state.copyWith(currentColor: color);
  }

  void updateEffectSpeed(int effectId, double speed) {
    final newSpeeds = Map<int, double>.from(state.effectSpeeds);
    newSpeeds[effectId] = speed;
    state = state.copyWith(effectSpeeds: newSpeeds);
  }

  void updateEffectIntensity(int effectId, double intensity) {
    final newIntensities = Map<int, double>.from(state.effectIntensities);
    newIntensities[effectId] = intensity;
    state = state.copyWith(effectIntensities: newIntensities);
  }
}

// Error Handler
class ErrorHandler {
  static void showError(String message,
      {BuildContext? context, VoidCallback? onRetry}) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: onRetry != null
              ? SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: onRetry,
                )
              : null,
        ),
      );
    }
  }
}

// Provider for ColorPickerStateNotifier
final colorPickerProvider =
    StateNotifierProvider<ColorPickerStateNotifier, ColorPickerViewModel>(
        (ref) {
  return ColorPickerStateNotifier(
    WledEffectService(),
  );
});

@RoutePage()
class ColorPage extends ConsumerStatefulWidget {
  const ColorPage({super.key});

  @override
  ConsumerState<ColorPage> createState() => _ColorPageState();
}

class _ColorPageState extends ConsumerState<ColorPage> {
  final _brightnessDebouncer = Debouncer(milliseconds: 100);
  final _colorDebouncer = Debouncer(milliseconds: 100);
  final _speedDebouncer = Debouncer(milliseconds: 100);
  final _intensityDebouncer = Debouncer(milliseconds: 100);
  final _apiService = UnifiedWledService();

  bool _isValidDeviceIp(String? ip) {
    return ip != null &&
        ip.isNotEmpty &&
        ip != "0.0.0.0" &&
        ip != "localhost" &&
        RegExp(r'^\d{1,3}(\.\d{1,3}){3}$').hasMatch(ip);
  }

  void _logDeviceState() {
    final devices = ref.read(deviceProvider);
    print("📋 Current device state:");
    if (devices.isEmpty) {
      print("   ❌ No devices found");
    } else {
      for (int i = 0; i < devices.length; i++) {
        final device = devices[i];
        print("   📱 Device $i: ${device.info.name}");
        print("      📍 IP: ${device.info.ip}");
        print("      🔗 MAC: ${device.info.mac}");
        print("      💡 Power: ${device.state.on ? 'ON' : 'OFF'}");
        print("      🌟 Brightness: ${device.state.bri}");
      }
    }
  }

  Future<String?> _getValidDeviceIp({int retryCount = 0}) async {
    final devices = ref.read(deviceProvider);
    final currentDevice =
        devices.firstWhereOrNull((d) => _isValidDeviceIp(d.info.ip));

    if (currentDevice != null) {
      print("⚡ Using device IP: ${currentDevice.info.ip}"); // Debug log
      return currentDevice.info.ip;
    }

    // Log current device state for debugging
    _logDeviceState();

    // Try to discover devices if no valid IP found
    if (retryCount < 3) {
      print(
          "⚡ No valid device IP found, attempting discovery (attempt ${retryCount + 1})");
      await ref.read(deviceProvider.notifier).discoverDevices();
      await Future.delayed(Duration(seconds: 1 * (retryCount + 1)));
      return _getValidDeviceIp(retryCount: retryCount + 1);
    }

    if (mounted) {
      ErrorHandler.showError(
        'No valid device found. Please check your device connection and WiFi settings.',
        context: context,
        onRetry: () async {
          await ref.read(deviceProvider.notifier).discoverDevices();
          final ip = await _getValidDeviceIp();
          if (ip != null) {
            _loadEffects();
          }
        },
      );
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _initializeDevice();
  }

  Future<void> _initializeDevice() async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp != null) {
      await _loadEffects();
    }
  }

  Future<void> _loadEffects() async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp != null) {
      try {
        await ref.read(colorPickerProvider.notifier).loadEffects(deviceIp);
      } catch (e) {
        if (mounted) {
          ErrorHandler.showError(
            'Failed to load effects: $e',
            context: context,
            onRetry: _loadEffects,
          );
        }
      }
    }
  }

  Future<void> _sendBrightnessCommand(double value) async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp == null) {
      print("⚡ Failed to get valid device IP for brightness command");
      return;
    }

    try {
      print("⚡ Sending brightness command to IP: $deviceIp");
      final normalizedValue = value.clamp(0.0, 1.0);
      final brightness = (normalizedValue * 255).round();

      // ✅ Add detailed logging before sending command
      print("🔍 About to send brightness command:");
      print("   📍 Device IP: $deviceIp");
      print(
          "   📊 Brightness value: $brightness (normalized: $normalizedValue)");
      print("   📦 Command: {'bri': $brightness, 'transition': 1}");

      await ref.read(deviceProvider.notifier).sendCommand(
        deviceIp,
        {'bri': brightness, 'transition': 1},
      );

      // Update local state only after successful command
      if (mounted) {
        ref
            .read(colorPickerProvider.notifier)
            .updateBrightness(normalizedValue);
      }

      // Refresh device state using the new method
      await ref.read(deviceProvider.notifier).refreshDevice(deviceIp);
    } catch (e) {
      print("⚡ Error sending brightness command: $e");
      if (mounted) {
        ErrorHandler.showError(
          'Failed to update brightness. Please check your device connection.',
          context: context,
          onRetry: () => _sendBrightnessCommand(value),
        );
      }

      // If connection failed, try to rediscover devices
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        await ref.read(deviceProvider.notifier).discoverDevices();
      }
    }
  }

  Future<void> _sendColorCommand(Color color) async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp == null) {
      print("⚡ Failed to get valid device IP for color command");
      return;
    }

    try {
      print("⚡ Sending color command to IP: $deviceIp");
      final command = {
        'seg': [
          {
            'col': [
              [color.red, color.green, color.blue]
            ]
          }
        ],
        'transition': 1
      };

      // ✅ Add detailed logging before sending command
      print("🔍 About to send color command:");
      print("   📍 Device IP: $deviceIp");
      print("   🎨 Color: RGB(${color.red}, ${color.green}, ${color.blue})");
      print("   📦 Command: $command");

      await ref.read(deviceProvider.notifier).sendCommand(deviceIp, command);

      // Update local state only after successful command
      if (mounted) {
        ref.read(colorPickerProvider.notifier).updateColor(color);
      }

      // Refresh device state using the new method
      await ref.read(deviceProvider.notifier).refreshDevice(deviceIp);
    } catch (e) {
      print("⚡ Error sending color command: $e");
      if (mounted) {
        ErrorHandler.showError(
          'Failed to update color. Please check your device connection.',
          context: context,
          onRetry: () => _sendColorCommand(color),
        );
      }

      // If connection failed, try to rediscover devices
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        await ref.read(deviceProvider.notifier).discoverDevices();
      }
    }
  }

  Future<void> _setEffect(WLEDEffect effect, {int retryCount = 0}) async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp == null) {
      print("⚡ Failed to get valid device IP for effect command");
      return;
    }

    try {
      print("⚡ Setting effect on IP: $deviceIp");

      // ✅ Add detailed logging before sending command
      print("🔍 About to set effect:");
      print("   📍 Device IP: $deviceIp");
      print("   🎭 Effect: ${effect.name} (ID: ${effect.id})");

      await ref.read(colorPickerProvider.notifier)._effectService.setEffect(
            deviceIp: deviceIp,
            effectId: effect.id,
            speed: ((ref.read(colorPickerProvider).effectSpeeds[effect.id] ??
                        0.5) *
                    255)
                .round(),
            intensity:
                ((ref.read(colorPickerProvider).effectIntensities[effect.id] ??
                            0.5) *
                        255)
                    .round(),
          );

      // Refresh device state using the new method
      await ref.read(deviceProvider.notifier).refreshDevice(deviceIp);
    } catch (e) {
      print("⚡ Error setting effect: $e");
      if (e.toString().contains('503') && retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return _setEffect(effect, retryCount: retryCount + 1);
      }

      if (mounted) {
        ErrorHandler.showError(
          e.toString().contains('503')
              ? 'Device is busy, please try again'
              : 'Failed to set effect. Please check your device connection.',
          context: context,
          onRetry: () => _setEffect(effect),
        );
      }

      // If connection failed, try to rediscover devices
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Connection timed out')) {
        await ref.read(deviceProvider.notifier).discoverDevices();
      }
    }
  }

  Future<void> _updateEffectParameters(int effectId,
      {int retryCount = 0}) async {
    final deviceIp = await _getValidDeviceIp();
    if (deviceIp == null) return;

    final state = ref.read(colorPickerProvider);
    final speed = (state.effectSpeeds[effectId] ?? 0.5) * 255;
    final intensity = (state.effectIntensities[effectId] ?? 0.5) * 255;

    try {
      final command = {
        'seg': [
          {
            'fx': effectId,
            'sx': speed.round(),
            'ix': intensity.round(),
          }
        ],
        'transition': 2
      };
      await ref.read(deviceProvider.notifier).sendCommand(deviceIp, command);
    } catch (e) {
      if (e.toString().contains('503') && retryCount < 3) {
        await Future.delayed(Duration(milliseconds: 500 * (retryCount + 1)));
        return _updateEffectParameters(effectId, retryCount: retryCount + 1);
      }

      if (mounted && !e.toString().contains('No IP found')) {
        ErrorHandler.showError(
          e.toString().contains('503')
              ? 'Device is busy, please try again'
              : 'Failed to update effect',
          context: context,
          onRetry: () => _updateEffectParameters(effectId),
        );
      }
    }
  }

  @override
  void dispose() {
    _brightnessDebouncer.dispose();
    _colorDebouncer.dispose();
    _speedDebouncer.dispose();
    _intensityDebouncer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(deviceProvider);
    final currentDevice =
        devices.firstWhereOrNull((d) => _isValidDeviceIp(d.info.ip));
    final state = ref.watch(colorPickerProvider);

    // Get current color from device state or use the one from our local state
    Color displayColor = state.currentColor;
    if (currentDevice != null &&
        currentDevice.state.seg.isNotEmpty &&
        currentDevice.state.seg[0].col.isNotEmpty &&
        currentDevice.state.seg[0].col[0].length >= 3) {
      final rgb = currentDevice.state.seg[0].col[0];
      displayColor = Color.fromRGBO(rgb[0], rgb[1], rgb[2], 1.0);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: BrightnessSlider(
                value: currentDevice?.state.bri != null
                    ? currentDevice!.state.bri / 255.0
                    : 1.0,
                onChanged: (val) =>
                    _brightnessDebouncer.run(() => _sendBrightnessCommand(val)),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ColorWheelSection(
                      initialColor: displayColor,
                      onColorChanged: (color) =>
                          _colorDebouncer.run(() => _sendColorCommand(color)),
                    ),
                    const SizedBox(height: 24),
                    EffectsListSection(
                      isExpanded: state.effectsExpanded,
                      onToggleExpanded: () => ref
                          .read(colorPickerProvider.notifier)
                          .toggleEffectsExpanded(),
                      isLoading: state.isLoading,
                      effects: state.effects,
                      selectedEffectId: state.selectedEffectId,
                      effectSpeeds: state.effectSpeeds,
                      effectIntensities: state.effectIntensities,
                      onEffectTap: (effect) async {
                        if (currentDevice != null) {
                          await _setEffect(
                            effect,
                          );
                        }
                      },
                      onSpeedChanged: (effectId, speed) {
                        ref
                            .read(colorPickerProvider.notifier)
                            .updateEffectSpeed(effectId, speed);
                        if (currentDevice != null) {
                          _speedDebouncer.run(() => _updateEffectParameters(
                                effectId,
                              ));
                        }
                      },
                      onIntensityChanged: (effectId, intensity) {
                        ref
                            .read(colorPickerProvider.notifier)
                            .updateEffectIntensity(effectId, intensity);
                        if (currentDevice != null) {
                          _intensityDebouncer.run(() => _updateEffectParameters(
                                effectId,
                              ));
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
