// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:collection/collection.dart';
// import 'device_card.dart';

// class DraggableDeviceGrid extends StatefulWidget {
//   final List<DeviceCardData> devices;
//   final Function(List<DeviceCardData>) onReorder;
//   final int crossAxisCount;
//   final double spacing;
//   final double runSpacing;
//   final EdgeInsets padding;
//   final Function(DeviceCardData)? onDeviceTap;

//   const DraggableDeviceGrid({
//     super.key,
//     required this.devices,
//     required this.onReorder,
//     this.crossAxisCount = 2,
//     this.spacing = 16.0,
//     this.runSpacing = 16.0,
//     this.padding = const EdgeInsets.all(16.0),
//     this.onDeviceTap,
//   });

//   @override
//   State<DraggableDeviceGrid> createState() => _DraggableDeviceGridState();
// }

// class _DraggableDeviceGridState extends State<DraggableDeviceGrid> {
//   int? draggedIndex;
//   int? targetIndex;
//   List<DeviceCardData> _devices = [];

//   @override
//   void initState() {
//     super.initState();
//     _devices = List.from(widget.devices);
//   }

//   @override
//   void didUpdateWidget(DraggableDeviceGrid oldWidget) {
//     super.didUpdateWidget(oldWidget);
//     if (!const ListEquality().equals(widget.devices, oldWidget.devices)) {
//       _devices = List.from(widget.devices);
//     }
//   }

//   void _handleReorder(int oldIndex, int newIndex) {
//     setState(() {
//       final item = _devices.removeAt(oldIndex);
//       _devices.insert(newIndex, item);
//       widget.onReorder(_devices);
//     });
//   }

//   void _updateTargetIndex(Offset globalPosition) {
//     final RenderBox box = context.findRenderObject() as RenderBox;
//     final localPosition = box.globalToLocal(globalPosition);

//     final double itemWidth = (box.size.width -
//             (widget.spacing * 2) - // Only 1 spacing between left and right
//             widget.padding.horizontal) /
//         2; // Split into left and right halves
//     final double itemHeight = itemWidth * (4 / 3); // 0.75 aspect ratio = 4:3

//     // Determine if we're in left or right column
//     final isLeftColumn =
//         localPosition.dx < (box.size.width - widget.padding.horizontal) / 2;

//     // Calculate row based on Y position
//     final row = (localPosition.dy / (itemHeight + widget.runSpacing)).floor();

//     // Calculate target index based on column and row
//     int newTargetIndex;
//     if (isLeftColumn) {
//       newTargetIndex = row * 2; // Even indices for left column
//     } else {
//       newTargetIndex = row * 2 + 1; // Odd indices for right column
//     }

//     // Clamp to valid range
//     newTargetIndex = newTargetIndex.clamp(0, _devices.length - 1);

//     if (targetIndex != newTargetIndex) {
//       setState(() {
//         targetIndex = newTargetIndex;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final itemWidth = (constraints.maxWidth -
//                 (widget.spacing * 2) - // Only 1 spacing between left and right
//                 widget.padding.horizontal) /
//             2; // Split into left and right halves
//         final itemHeight = itemWidth * (4 / 3); // 0.75 aspect ratio = 4:3

//         // Split devices into left and right columns
//         final leftDevices = <DeviceCardData>[];
//         final rightDevices = <DeviceCardData>[];

//         for (int i = 0; i < _devices.length; i++) {
//           if (i % 2 == 0) {
//             leftDevices.add(_devices[i]);
//           } else {
//             rightDevices.add(_devices[i]);
//           }
//         }

//         return Padding(
//           padding: widget.padding,
//           child: Row(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Left column
//               Expanded(
//                 child: Column(
//                   children: leftDevices.mapIndexed((index, device) {
//                     final actualIndex = index * 2; // Map back to original index
//                     final isBeingDragged = actualIndex == draggedIndex;
//                     final shouldShift = targetIndex != null &&
//                         draggedIndex != null &&
//                         actualIndex > draggedIndex! &&
//                         actualIndex <= targetIndex!;

//                     return Padding(
//                       padding: EdgeInsets.only(bottom: widget.runSpacing),
//                       child: SizedBox(
//                         width: itemWidth,
//                         height: itemHeight,
//                         child: AnimatedSlide(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                           offset:
//                               shouldShift ? const Offset(-1, 0) : Offset.zero,
//                           child: AnimatedOpacity(
//                             duration: const Duration(milliseconds: 200),
//                             opacity: isBeingDragged ? 0.0 : 1.0,
//                             child: DeviceCard(
//                               key: ValueKey(device.id),
//                               isDraggable: true,
//                               index: actualIndex,
//                               title: device.name,
//                               deviceIp: device.ip,
//                               isOn: device.isOn,
//                               brightness: device.brightness,
//                               onToggle: (value) {
//                                 final updatedDevice =
//                                     device.copyWith(isOn: value);
//                                 final newDevices =
//                                     List<DeviceCardData>.from(_devices);
//                                 newDevices[actualIndex] = updatedDevice;
//                                 widget.onReorder(newDevices);
//                               },
//                               onBrightnessChange: (value) {
//                                 final updatedDevice =
//                                     device.copyWith(brightness: value);
//                                 final newDevices =
//                                     List<DeviceCardData>.from(_devices);
//                                 newDevices[actualIndex] = updatedDevice;
//                                 widget.onReorder(newDevices);
//                               },
//                               onTap: () => widget.onDeviceTap?.call(device),
//                               onDragUpdate: (details) {
//                                 _updateTargetIndex(details.globalPosition);
//                               },
//                               onDragEnd: () {
//                                 if (draggedIndex != null &&
//                                     targetIndex != null) {
//                                   _handleReorder(draggedIndex!, targetIndex!);
//                                 }
//                                 setState(() {
//                                   draggedIndex = null;
//                                   targetIndex = null;
//                                 });
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),

//               // Spacing between columns
//               SizedBox(width: widget.spacing),

//               // Right column
//               Expanded(
//                 child: Column(
//                   children: rightDevices.mapIndexed((index, device) {
//                     final actualIndex =
//                         index * 2 + 1; // Map back to original index
//                     final isBeingDragged = actualIndex == draggedIndex;
//                     final shouldShift = targetIndex != null &&
//                         draggedIndex != null &&
//                         actualIndex > draggedIndex! &&
//                         actualIndex <= targetIndex!;

//                     return Padding(
//                       padding: EdgeInsets.only(bottom: widget.runSpacing),
//                       child: SizedBox(
//                         width: itemWidth,
//                         height: itemHeight,
//                         child: AnimatedSlide(
//                           duration: const Duration(milliseconds: 300),
//                           curve: Curves.easeInOut,
//                           offset:
//                               shouldShift ? const Offset(-1, 0) : Offset.zero,
//                           child: AnimatedOpacity(
//                             duration: const Duration(milliseconds: 200),
//                             opacity: isBeingDragged ? 0.0 : 1.0,
//                             child: DeviceCard(
//                               key: ValueKey(device.id),
//                               isDraggable: true,
//                               index: actualIndex,
//                               title: device.name,
//                               deviceIp: device.ip,
//                               isOn: device.isOn,
//                               brightness: device.brightness,
//                               onToggle: (value) {
//                                 final updatedDevice =
//                                     device.copyWith(isOn: value);
//                                 final newDevices =
//                                     List<DeviceCardData>.from(_devices);
//                                 newDevices[actualIndex] = updatedDevice;
//                                 widget.onReorder(newDevices);
//                               },
//                               onBrightnessChange: (value) {
//                                 final updatedDevice =
//                                     device.copyWith(brightness: value);
//                                 final newDevices =
//                                     List<DeviceCardData>.from(_devices);
//                                 newDevices[actualIndex] = updatedDevice;
//                                 widget.onReorder(newDevices);
//                               },
//                               onTap: () => widget.onDeviceTap?.call(device),
//                               onDragUpdate: (details) {
//                                 _updateTargetIndex(details.globalPosition);
//                               },
//                               onDragEnd: () {
//                                 if (draggedIndex != null &&
//                                     targetIndex != null) {
//                                   _handleReorder(draggedIndex!, targetIndex!);
//                                 }
//                                 setState(() {
//                                   draggedIndex = null;
//                                   targetIndex = null;
//                                 });
//                               },
//                             ),
//                           ),
//                         ),
//                       ),
//                     );
//                   }).toList(),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// // Data class for device information
// class DeviceCardData {
//   final String id;
//   final String name;
//   final String ip;
//   final bool isOn;
//   final double brightness;

//   const DeviceCardData({
//     required this.id,
//     required this.name,
//     required this.ip,
//     required this.isOn,
//     required this.brightness,
//   });

//   DeviceCardData copyWith({
//     String? id,
//     String? name,
//     String? ip,
//     bool? isOn,
//     double? brightness,
//   }) {
//     return DeviceCardData(
//       id: id ?? this.id,
//       name: name ?? this.name,
//       ip: ip ?? this.ip,
//       isOn: isOn ?? this.isOn,
//       brightness: brightness ?? this.brightness,
//     );
//   }
// }
