import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:app_settings/app_settings.dart';
import '../../../../features/core/services/wifi_service.dart';

@RoutePage()
class NewDeviceSetupPage extends StatefulWidget {
  const NewDeviceSetupPage({super.key});

  @override
  State<NewDeviceSetupPage> createState() => _NewDeviceSetupPageState();
}

class _NewDeviceSetupPageState extends State<NewDeviceSetupPage> {
  final _connectivity = Connectivity();
  final _wifiService = WifiService();
  bool _isConnectedToWLED = false;

  @override
  void initState() {
    super.initState();
    _checkWLEDConnection();
    _connectivity.onConnectivityChanged.listen((result) {
      _checkWLEDConnection();
    });
  }

  Future<void> _checkWLEDConnection() async {
    final isConnected = await _wifiService.isConnectedToWLED();
    setState(() {
      _isConnectedToWLED = isConnected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Set Up New Device'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StepIndicator(
                currentStep: _isConnectedToWLED ? 2 : 1,
                totalSteps: 3,
              ).animate().fadeIn(),
              const SizedBox(height: 32),
              if (!_isConnectedToWLED) ...[
                _buildConnectToWLEDStep(),
              ] else ...[
                _buildConfigureWiFiStep(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectToWLEDStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Connect to WLED',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        Text(
          'Follow these steps to connect to your WLED device:',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 24),
        const _InstructionStep(
          number: 1,
          title: 'Power on your WLED device',
          description: 'Make sure your WLED device is powered on and in setup mode.',
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        _InstructionStep(
          number: 2,
          title: 'Open WiFi Settings',
          description: 'Go to your device\'s WiFi settings and look for a network named "WLED-XXXXXX".',
          action: TextButton.icon(
            onPressed: () async {
              await AppSettings.openAppSettings(type: AppSettingsType.wifi);
            },
            icon: const Icon(Icons.wifi),
            label: const Text('Open WiFi Settings'),
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        const _InstructionStep(
          number: 3,
          title: 'Connect to WLED',
          description: 'Connect to the WLED network using password: wled1234',
        ).animate().fadeIn().slideX(begin: -0.2),
        const Spacer(),
        ElevatedButton(
          onPressed: () {
            _checkWLEDConnection();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('I\'m Connected'),
        ).animate().fadeIn().slideY(begin: 0.2),
      ],
    );
  }

  Widget _buildConfigureWiFiStep() {
    final wifiNameController = TextEditingController();
    final wifiPasswordController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Configure WiFi',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 16),
        Text(
          'Now let\'s connect your WLED device to your home WiFi network.',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white70,
          ),
        ).animate().fadeIn().slideX(begin: -0.2),
        const SizedBox(height: 24),
        Card(
          color: Colors.grey[900],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: wifiNameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'WiFi Network Name',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    prefixIcon: Icon(Icons.wifi, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: wifiPasswordController,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'WiFi Password',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white24),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const Spacer(),
        ElevatedButton(
          onPressed: () async {
            final wifiName = wifiNameController.text;
            final wifiPassword = wifiPasswordController.text;
            
            if (wifiName.isEmpty || wifiPassword.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter both WiFi name and password'),
                  backgroundColor: Colors.red,
                ),
              );
              return;
            }

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(
                child: CircularProgressIndicator(),
              ),
            );

            try {
              await _wifiService.configureWLED(
                ssid: wifiName,
                password: wifiPassword,
              );
              
              Navigator.pop(context); // Close loading indicator
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('WiFi configuration successful!'),
                  backgroundColor: Colors.green,
                ),
              );
              
              context.router.pushNamed('/devices');
            } catch (e) {
              Navigator.pop(context); // Close loading indicator
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error configuring WiFi: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.all(16),
          ),
          child: const Text('Configure WiFi'),
        ).animate().fadeIn().slideY(begin: 0.2),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(totalSteps, (index) {
        final isActive = index < currentStep;
        return Expanded(
          child: Container(
            height: 4,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isActive ? Colors.blue : Colors.grey[800],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      }),
    );
  }
}

class _InstructionStep extends StatelessWidget {
  final int number;
  final String title;
  final String description;
  final Widget? action;

  const _InstructionStep({
    required this.number,
    required this.title,
    required this.description,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Colors.blue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              if (action != null) ...[
                const SizedBox(height: 8),
                action!,
              ],
            ],
          ),
        ),
      ],
    );
  }
} 