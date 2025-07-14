// import 'package:flutter/material.dart';

// class DeviceCardWidget extends StatelessWidget {
//   final String ipAddress;
//   final String deviceName;
//   final bool isOn;
//   final VoidCallback onTogglePower;
//   final VoidCallback onTap;

//   const DeviceCardWidget({
//     Key? key,
//     required this.ipAddress,
//     required this.deviceName,
//     required this.isOn,
//     required this.onTogglePower,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Card(
//         elevation: 2,
//         margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(12),
//           side: BorderSide(
//             color: isOn ? Colors.green : Colors.grey,
//             width: 1,
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Row(
//             children: [
//               // Device info
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       deviceName,
//                       style: const TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       ipAddress,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[600],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               // Toggle switch
//               Switch(
//                 value: isOn,
//                 onChanged: (value) => onTogglePower(),
//                 activeColor: Colors.green,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
