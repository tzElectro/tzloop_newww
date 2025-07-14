// import 'package:flutter/material.dart';
// import '../core/widgets/premium_status_indicators.dart';
// import '../core/widgets/feedback_manager.dart';

// /// Example showing how to use premium status indicators in a device page
// class DevicePageExample extends StatefulWidget {
//   @override
//   State<DevicePageExample> createState() => _DevicePageExampleState();
// }

// class _DevicePageExampleState extends State<DevicePageExample> {
//   bool isConnected = false;
//   bool isDiscovering = false;
//   bool isLoading = false;
//   double uploadProgress = 0.0;
//   String discoveryStatus = 'Ready to discover devices';

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Device Control'),
//         // Example: Add connection status to app bar
//         bottom: PreferredSize(
//           preferredSize: Size.fromHeight(40),
//           child: ConnectionStatusIndicator(
//             isConnected: isConnected,
//             deviceName: isConnected ? 'Living Room LEDs' : null,
//             onRetry: () => _connectToDevice(),
//           ),
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Discovery Status
//             DiscoveryStatus(
//               status: discoveryStatus,
//               isLoading: isDiscovering,
//             ),
//             SizedBox(height: 20),

//             // Action Buttons Row
//             Row(
//               children: [
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: _discoverDevices,
//                     child: Text('Discover Devices'),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 Expanded(
//                   child: ElevatedButton(
//                     onPressed: isConnected ? _disconnectDevice : _connectToDevice,
//                     child: Text(isConnected ? 'Disconnect' : 'Connect'),
//                   ),
//                 ),
//               ],
//             ),
//             SizedBox(height: 20),

//             // Upload Progress (only shown when uploading)
//             if (uploadProgress > 0 && uploadProgress < 1)
//               Column(
//                 children: [
//                   PremiumProgressIndicator(
//                     progress: uploadProgress,
//                     label: 'Uploading firmware',
//                   ),
//                   SizedBox(height: 20),
//                 ],
//               ),

//             // Local Loading Indicator
//             if (isLoading)
//               Column(
//                 children: [
//                   PremiumLoadingIndicator(
//                     message: 'Processing request...',
//                     size: 48,
//                   ),
//                   SizedBox(height: 20),
//                 ],
//               ),

//             // More Action Buttons
//             ElevatedButton(
//               onPressed: _simulateSuccess,
//               child: Text('Test Success Message'),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _simulateError,
//               child: Text('Test Error Message'),
//             ),
//             SizedBox(height: 10),
//             ElevatedButton(
//               onPressed: _simulateUpload,
//               child: Text('Simulate Firmware Upload'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   void _discoverDevices() async {
//     setState(() {
//       isDiscovering = true;
//       discoveryStatus = 'Searching for devices...';
//     });

//     // Show global loading
//     context.showLoading('Discovering WLED devices...');

//     try {
//       // Simulate discovery process
//       await Future.delayed(Duration(seconds: 3));
      
//       setState(() {
//         isDiscovering = false;
//         discoveryStatus = 'Found 3 devices';
//       });

//       // Hide loading and show success
//       context.hideFeedback();
//       context.showSuccess('Discovered 3 WLED devices!');
      
//     } catch (e) {
//       setState(() {
//         isDiscovering = false;
//         discoveryStatus = 'Discovery failed';
//       });

//       context.hideFeedback();
//       context.showError('Failed to discover devices', onRetry: _discoverDevices);
//     }
//   }

//   void _connectToDevice() async {
//     setState(() => isLoading = true);
    
//     context.showLoading('Connecting to device...');

//     try {
//       // Simulate connection
//       await Future.delayed(Duration(seconds: 2));
      
//       setState(() {
//         isConnected = true;
//         isLoading = false;
//       });

//       context.hideFeedback();
//       context.showSuccess('Connected to Living Room LEDs!');
      
//     } catch (e) {
//       setState(() => isLoading = false);
      
//       context.hideFeedback();
//       context.showError('Failed to connect to device', onRetry: _connectToDevice);
//     }
//   }

//   void _disconnectDevice() async {
//     setState(() => isLoading = true);

//     try {
//       // Simulate disconnection
//       await Future.delayed(Duration(seconds: 1));
      
//       setState(() {
//         isConnected = false;
//         isLoading = false;
//       });

//       context.showSuccess('Disconnected from device');
      
//     } catch (e) {
//       setState(() => isLoading = false);
//       context.showError('Failed to disconnect');
//     }
//   }

//   void _simulateSuccess() {
//     context.showSuccess('Settings saved successfully!');
//   }

//   void _simulateError() {
//     context.showError('Something went wrong. Please try again.', onRetry: () {
//       // Handle retry
//       print('User clicked retry');
//     });
//   }

//   void _simulateUpload() async {
//     setState(() => uploadProgress = 0.1);

//     // Simulate upload progress
//     for (double progress = 0.1; progress <= 1.0; progress += 0.1) {
//       await Future.delayed(Duration(milliseconds: 500));
//       setState(() => uploadProgress = progress);
//     }

//     // Show completion
//     context.showSuccess('Firmware uploaded successfully!');
    
//     // Reset progress after a delay
//     Future.delayed(Duration(seconds: 1), () {
//       setState(() => uploadProgress = 0.0);
//     });
//   }
// }

// /*
// =======================================================================
//                          USAGE SUMMARY
// =======================================================================

// HOW TO USE IN YOUR EXISTING FILES:

// 1. IMPORT THE EXTENSIONS:
//    import '../core/widgets/feedback_manager.dart';
//    import '../core/widgets/premium_status_indicators.dart';

// 2. GLOBAL FEEDBACK (anywhere with BuildContext):
//    - context.showSuccess('Message')
//    - context.showError('Error message', onRetry: () {})
//    - context.showLoading('Loading message')
//    - context.hideFeedback()

// 3. LOCAL INDICATORS:
//    - ConnectionStatusIndicator(isConnected: bool, deviceName: string)
//    - PremiumLoadingIndicator(message: string, size: double)
//    - PremiumProgressIndicator(progress: 0.0-1.0, label: string)
//    - DiscoveryStatus(status: string, isLoading: bool)

// 4. REPLACE IN YOUR FILES:
//    - Replace CircularProgressIndicator with PremiumLoadingIndicator
//    - Replace LinearProgressIndicator with PremiumProgressIndicator
//    - Add connection status to device-related pages
//    - Use global feedback for user actions

// =======================================================================
// */
