import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logger/logger.dart';
import 'dart:async';

class WifiService {
  final _connectivity = Connectivity();
  final _networkInfo = NetworkInfo();
  final _logger = Logger();

  // ESP device AP mode configuration
  static const List<String> _validIpPrefixes = [
    '4.2.3.',
    '4.3.2.'
  ]; // Support both IP ranges
  static const int _provisionTimeout = 30; // Timeout in seconds

  Future<bool> isConnectedToWLED() async {
    _logger.d('Checking WLED connection...');
    final connectivityResult = await _connectivity.checkConnectivity();
    _logger.d('Connectivity result: $connectivityResult');

    if (connectivityResult != ConnectivityResult.wifi) {
      _logger.d('Not on WiFi');
      return false;
    }

    final wifiIP = await _networkInfo.getWifiIP();
    _logger.d('Current WiFi IP: $wifiIP');

    return _validIpPrefixes
        .any((prefix) => wifiIP?.startsWith(prefix) ?? false);
  }

  Future<bool> isConnectedToEspAP() async {
    try {
      _logger.d('Checking ESP AP connection...');

      final connectivityResult = await _connectivity.checkConnectivity();
      _logger.d('Connectivity result: $connectivityResult');

      if (connectivityResult != ConnectivityResult.wifi) {
        _logger.d('Not on WiFi network');
        return false;
      }

      final wifiIP = await _networkInfo.getWifiIP();
      _logger.d('Current WiFi IP: $wifiIP');

      if (wifiIP == null) {
        _logger.d('No WiFi IP detected');
        return false;
      }

      // Check if we're in any of the valid IP ranges
      final isValidIp =
          _validIpPrefixes.any((prefix) => wifiIP.startsWith(prefix));
      if (!isValidIp) {
        _logger.d('Not in valid IP range');
        return false;
      }

      _logger.d('Connected to ESP AP network');
      return true;
    } catch (e) {
      _logger.d('Error checking ESP AP connection: $e');
      return false;
    }
  }

  Future<void> _sendFormCredentials(
      String espIp, String ssid, String password) async {
    // Create JSON string first
    final jsonString = jsonEncode({
      "ssid": ssid,
      "password": password,
    });

    // Wrap in plain field
    final body = {
      'plain': jsonString,
    };

    _logger.d('Form Request body: $body');

    final response = await http
        .post(
          Uri.parse('http://$espIp/provision'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
            'User-Agent': 'TzLoop-App',
            'Accept': '*/*',
            'Connection': 'keep-alive',
            'Host': espIp,
          },
          body: body,
        )
        .timeout(const Duration(seconds: _provisionTimeout));

    _logger.d('Form response status: ${response.statusCode}');
    _logger.d('Form response headers: ${response.headers}');
    _logger.d('Form response body: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to send credentials: ${response.statusCode}. Response: ${response.body}');
    }
  }

  Future<void> configureWLED({
    required String ssid,
    required String password,
  }) async {
    _logger.d('Starting WLED configuration...');
    _logger.d('Target SSID: $ssid');

    // First verify we're connected to the ESP AP
    if (!await isConnectedToEspAP()) {
      _logger.e('Not connected to ESP AP');
      throw Exception(
          'Not connected to ESP device. Please connect to the ESP\'s WiFi network first.');
    }

    try {
      // Get the current WiFi IP to determine the ESP's IP
      final wifiIP = await _networkInfo.getWifiIP();
      _logger.d('Current WiFi IP: $wifiIP');

      final espIpPrefix = _validIpPrefixes.firstWhere(
        (prefix) => wifiIP?.startsWith(prefix) ?? false,
        orElse: () => _validIpPrefixes[0],
      );
      final espIp = espIpPrefix + '1';
      _logger.d('Using ESP IP for configuration: $espIp');

      // Try with form-urlencoded format only since we know the format now
      await _sendFormCredentials(espIp, ssid, password);
    } catch (e) {
      _logger.e('WiFi configuration failed', error: e);
      throw Exception('Failed to configure WiFi: $e');
    }
  }
}
