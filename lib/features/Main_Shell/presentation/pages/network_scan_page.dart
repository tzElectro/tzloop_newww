import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:auto_route/auto_route.dart';
import '../../../core/services/wifi_service.dart';

@RoutePage()
class NetworkScanPage extends StatefulWidget {
  const NetworkScanPage({super.key});

  @override
  State<NetworkScanPage> createState() => _NetworkScanPageState();
}

class _NetworkScanPageState extends State<NetworkScanPage> {
  final _wifiService = WifiService();
  final _logger = Logger();
  bool _isLoading = true;
  bool _isConnectedToEsp = false;
  String? _selectedNetwork;
  final _passwordController = TextEditingController();
  String? _errorMessage;
  List<WiFiAccessPoint> _networks = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    _logger.d('Checking ESP connection...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final isConnected = await _wifiService.isConnectedToEspAP();
      _logger.d('ESP connection status: $isConnected');

      setState(() {
        _isConnectedToEsp = isConnected;
        _isLoading = false;
      });

      if (!isConnected) {
        setState(() {
          _errorMessage =
              'Please connect to the ESP device\'s WiFi network (TzLED-AP)';
        });
      } else {
        // Start scanning for networks when connected
        _startScan();
      }
    } catch (e) {
      _logger.e('Connection check failed', error: e);
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to check connection: $e';
      });
    }
  }

  Future<void> _startScan() async {
    _logger.d('Starting WiFi scan...');
    setState(() {
      _isScanning = true;
      _networks = [];
      _errorMessage = null;
    });

    try {
      // Check if we can scan
      final can = await WiFiScan.instance.canStartScan();
      _logger.d('Can start scan result: $can');

      if (can != CanStartScan.yes) {
        if (can == CanStartScan.notSupported) {
          throw Exception('WiFi scanning not supported on this device');
        } else {
          throw Exception(
              'Cannot start WiFi scan: $can. Please check location permissions and services.');
        }
      }

      // Start scan
      _logger.d('Requesting scan start...');
      final isScanning = await WiFiScan.instance.startScan();
      _logger.d('Scan started: $isScanning');

      if (!isScanning) {
        throw Exception('Failed to start scan');
      }

      // Wait a bit for the scan to complete
      await Future.delayed(const Duration(seconds: 2));

      // Get results
      _logger.d('Getting scan results...');
      final results = await WiFiScan.instance.getScannedResults();
      _logger.d('Scan complete. Found ${results.length} networks');

      setState(() {
        _networks = results;
        _isScanning = false;
      });
    } catch (e) {
      _logger.e('Scan failed', error: e);
      setState(() {
        _isScanning = false;
        _errorMessage = e.toString();
      });

      // Show error dialog with more details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('WiFi Scan Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(e.toString()),
                const SizedBox(height: 16),
                if (e.toString().contains('permission'))
                  const Text(
                    'This app requires location permission to scan for WiFi networks. Please grant the permission in your device settings.',
                  )
                else if (e.toString().contains('location services'))
                  const Text(
                    'Location services must be enabled to scan for WiFi networks. Please enable location in your device settings.',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _configureWifi() async {
    if (_selectedNetwork == null) {
      _logger.w('No network selected');
      setState(() {
        _errorMessage = 'Please select a network';
      });
      return;
    }

    if (_passwordController.text.isEmpty) {
      _logger.w('No password entered');
      setState(() {
        _errorMessage = 'Please enter the network password';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _logger.d('Configuring WiFi...');
      _logger.d('Selected network: $_selectedNetwork');

      await _wifiService.configureWLED(
        ssid: _selectedNetwork!,
        password: _passwordController.text,
      );

      _logger.i('WiFi configuration successful');
      if (mounted) {
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      _logger.e('WiFi configuration failed', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to configure WiFi: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isConnectedToEsp) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Connect Device'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Not connected to ESP device',
                style: TextStyle(fontSize: 18),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ElevatedButton(
                onPressed: _checkConnection,
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configure WiFi'),
        actions: [
          if (_isScanning)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isScanning ? null : _startScan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select WiFi Network:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_networks.isEmpty && !_isScanning)
              const Center(
                child: Text('No networks found. Tap refresh to scan again.'),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _networks.length,
                  itemBuilder: (context, index) {
                    final network = _networks[index];
                    final isSelected = network.ssid == _selectedNetwork;

                    return ListTile(
                      leading: Icon(
                        Icons.wifi,
                        color:
                            isSelected ? Theme.of(context).primaryColor : null,
                      ),
                      title: Text(network.ssid),
                      subtitle: Text('Signal: ${network.level} dBm'),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedNetwork = network.ssid;
                        });
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'WiFi Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ElevatedButton(
              onPressed: _configureWifi,
              child: const Text('Configure WiFi'),
            ),
          ],
        ),
      ),
    );
  }
}
