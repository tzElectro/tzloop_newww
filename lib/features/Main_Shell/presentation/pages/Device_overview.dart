import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/brightness_slider.dart';
import '../../../../core/services/wled_api_service.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/appbar.dart';

@RoutePage()
class DeviceOverviewPage extends StatefulWidget {
  final String ipAddress;
  const DeviceOverviewPage(
      {super.key, @PathParam('ipAddress') required this.ipAddress});

  @override
  State<DeviceOverviewPage> createState() => _DeviceOverviewPageState();
}

class _DeviceOverviewPageState extends State<DeviceOverviewPage> {
  final _apiService = UnifiedWledService();
  bool _isOn = false;
  int _brightness = 128;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDeviceState();
  }

  Future<void> _loadDeviceState() async {
    try {
      setState(() => _loading = true);
      final state = await _apiService.getState(widget.ipAddress);
      if (!mounted) return;
      setState(() {
        _isOn = state['on'] ?? false;
        _brightness = state['bri'] ?? 128;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to fetch device state: $e'),
            backgroundColor: Colors.red),
      );
      setState(() => _loading = false);
    }
  }

  Future<void> _togglePower() async {
    try {
      setState(() => _isOn = !_isOn);
      await _apiService.setPower(target: widget.ipAddress, on: _isOn);
    } catch (e) {
      setState(() => _isOn = !_isOn);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Power toggle failed: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _setBrightness(int bri) async {
    try {
      setState(() => _brightness = bri);
      await _apiService.setBrightness(
          target: widget.ipAddress, brightness: bri);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Brightness update failed: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Device Overview'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Power'),
                  subtitle: Text(_isOn ? 'ON' : 'OFF'),
                  value: _isOn,
                  onChanged: (_) => _togglePower(),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: BrightnessSlider(
                    value: _brightness / 255.0,
                    onChanged: (value) => _setBrightness((value * 255).round()),
                  ),
                ),
                const SizedBox(height: 12),
                Text('${(_brightness / 255.0 * 100).round()}%',
                    style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          AutoTabsRouter.of(context).setActiveIndex(1),
                      child: const Text('Color'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          AutoTabsRouter.of(context).setActiveIndex(2),
                      child: const Text('Effects'),
                    ),
                    ElevatedButton(
                      onPressed: () =>
                          AutoTabsRouter.of(context).setActiveIndex(3),
                      child: const Text('Segments'),
                    ),
                    ElevatedButton(
                      onPressed: () => context.router
                          .pushNamed('/palette/${widget.ipAddress}'),
                      child: const Text('Palette'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }
}
