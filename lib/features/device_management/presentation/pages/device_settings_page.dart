import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:auto_route/auto_route.dart';

import '../../../../core/services/wled_api_service.dart';
import '../../../Main_Shell/presentation/widgets/subtitile_banner.dart';

@RoutePage()
class DeviceSettingsPage extends StatefulWidget {
  final String deviceId;
  final String currentName;

  const DeviceSettingsPage({
    Key? key,
    @PathParam('deviceIp') required this.deviceId,
    required this.currentName,
  }) : super(key: key);

  @override
  State<DeviceSettingsPage> createState() => _DeviceSettingsPageState();
}

class _DeviceSettingsPageState extends State<DeviceSettingsPage> {
  late TextEditingController _nameController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSystemCommand(
    BuildContext context,
    String title,
    String message,
    Future<Map<String, dynamic>> Function() action,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await action();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Command sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleNameUpdate(BuildContext context) async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final api = context.read<UnifiedWledService>();
      await api.setDeviceName(widget.deviceId, newName);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Device name updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update name: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<UnifiedWledService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Settings'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SubtitleBanner(
                subtitle: 'Device Name',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'Enter device name',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isLoading
                            ? null
                            : () => _handleNameUpdate(context),
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const SubtitleBanner(
                subtitle: 'System Actions',
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text('Reboot Device'),
                      subtitle: const Text('Restart the device'),
                      onTap: _isLoading
                          ? null
                          : () => _handleSystemCommand(
                                context,
                                'Reboot Device',
                                'Are you sure you want to reboot the device? It will be temporarily unavailable.',
                                () => api.rebootDevice(widget.deviceId),
                              ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.wifi_off),
                      title: const Text('Clear Wi-Fi Settings'),
                      subtitle: const Text('Remove saved Wi-Fi credentials'),
                      onTap: _isLoading
                          ? null
                          : () => _handleSystemCommand(
                                context,
                                'Clear Wi-Fi Settings',
                                'Are you sure you want to clear all Wi-Fi settings? The device will need to be reconfigured.',
                                () => api.clearWiFiSettings(widget.deviceId),
                              ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: const Text('Factory Reset'),
                      subtitle: const Text('Reset all settings to defaults'),
                      onTap: _isLoading
                          ? null
                          : () => _handleSystemCommand(
                                context,
                                'Factory Reset',
                                'Are you sure you want to reset all settings to factory defaults? This cannot be undone.',
                                () => api.factoryReset(widget.deviceId),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}
