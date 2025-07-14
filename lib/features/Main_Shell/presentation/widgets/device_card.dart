import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
// Import the generated router file to access DeviceDetailShellRoute
import 'package:tzloop_newww/core/router/app_router.dart';
// import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class DeviceCard extends StatelessWidget {
  final String title;
  final String deviceIp;
  final bool isOn;
  final double brightness;
  final Function(bool) onToggle;
  final Function(double) onBrightnessChange;
  final VoidCallback onTap;
  // final Function()? onLongPress;
  // final Color? backgroundColor;
  // final bool isDraggable;
  // final Function(DragUpdateDetails)? onDragUpdate;
  // final VoidCallback? onDragEnd;
  final int? index;

  const DeviceCard({
    super.key,
    required this.title,
    required this.deviceIp,
    required this.isOn,
    required this.brightness,
    required this.onToggle,
    required this.onBrightnessChange,
    required this.onTap,
    // this.onLongPress,
    // this.backgroundColor,
    // this.isDraggable = false,
    // this.onDragUpdate,
    // this.onDragEnd,
    this.index,
  });

  void _onTap(BuildContext context) {
    Logger().d('Device card tapped');
    // Correctly push the generated route
    context.router
        .push(DeviceDetailShellRoute(deviceName: title, deviceIp: deviceIp));
  }

  @override
  Widget build(BuildContext context) {
    final currentBrightness = brightness.clamp(0.0, 100.0);
    final currentIsOn = isOn;

    return GestureDetector(
      onTap: () => _onTap(context),
      // FIX: Changed to onVerticalDragUpdate for vertical brightness control
      onVerticalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final height = box.size.height; // Get the height of the widget
        final localPosition = box.globalToLocal(details.globalPosition);

        // Calculate new brightness based on vertical position
        // Dragging down (increasing dy) should decrease brightness,
        // dragging up (decreasing dy) should increase brightness.
        // So we invert the y-axis calculation: (1 - (localPosition.dy / height))
        final newBrightness = (1 - (localPosition.dy / height)) * 100.0;
        onBrightnessChange(newBrightness.clamp(0.0, 100.0));
      },
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(
          side: BorderSide(
            color: isOn ? Colors.greenAccent : Colors.redAccent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image with color filter
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withAlpha(
                      ((0.5 - (brightness / 100) * 0.4) * 255).round()),
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/dummy_bg.jpeg',
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Brightness overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(
                    (currentIsOn ? 0 : 179).round(),
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top: link + toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Icon(Icons.link, color: Colors.white),
                      Switch(
                        value: currentIsOn,
                        onChanged: onToggle,
                        activeColor: Colors.purpleAccent,
                      ),
                    ],
                  ),

                  // Middle: icons
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Icon(Icons.change_history, color: Colors.white38),
                      Icon(Icons.settings, color: Colors.white38),
                      Icon(Icons.brightness_6, color: Colors.white38),
                    ],          
                  ),

                  // Bottom: title and brightness
                  Column(
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Brightness: ${currentBrightness.toInt()}%',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

           




// import 'package:flutter/material.dart';
// import 'package:untitled4/app/router/app_router.dart';
// import 'package:auto_route/auto_route.dart';
// class DeviceCard extends StatefulWidget {
//   final String title;
//   final bool isOn;
//   final double brightness; // Expecting 0–100 now
//   final Function(bool) onToggle;
//   final Function(double) onBrightnessChange;
//
//   const DeviceCard({
//     super.key,
//     required this.title,
//     required this.isOn,
//     required this.brightness,
//     required this.onToggle,
//     required this.onBrightnessChange,
//   });
//
//   @override
//   State<DeviceCard> createState() => _DeviceCardState();
// }
//
// class _DeviceCardState extends State<DeviceCard> {
//   late bool isOn;
//   late double brightness; // Range: 0–100
//
//   @override
//   void initState() {
//     super.initState();
//     isOn = widget.isOn;
//     brightness = widget.brightness;
//   }
//
//   void _handleToggle(bool value) {
//     setState(() => isOn = value);
//     widget.onToggle(value);
//   }
//
//   void _handleBrightnessChange(double value) {
//     setState(() => brightness = value);
//     widget.onBrightnessChange(value);
//   }
//   void _onTap() {
//     print('Tap');
//     context.router.push(DeviceDetailShellRoute(deviceName : widget.title));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _onTap,
//       onHorizontalDragUpdate: (details) {
//         final box = context.findRenderObject() as RenderBox;
//         final width = box.size.width;
//         final localPosition = box.globalToLocal(details.globalPosition);
//         final newBrightness = (localPosition.dx / width * 100).clamp(0.0, 100.0);
//         _handleBrightnessChange(newBrightness);
//       },
//       child: Card(
//         elevation: 4,
//         margin: const EdgeInsets.all(8),
//         shape: RoundedRectangleBorder(
//           side: const BorderSide(color: Colors.redAccent, width: 2),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: Stack(
//           children: [
//             // Background image
//             Positioned.fill(
//               child: Image.asset(
//                 'assets/dummy_bg.jpg',
//                 fit: BoxFit.cover,
//               ),
//             ),
//
//             // Brightness overlay
//             Positioned.fill(
//               child: Container(
//                 decoration: BoxDecoration(
//                   color: Colors.black.withOpacity(
//                     0.5 + 0.4 * (1 - (brightness / 100)),
//                   ),
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//               ),
//             ),
//
//             // Main content
//             Padding(
//               padding: const EdgeInsets.all(12.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   // Top: link + toggle
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Icon(Icons.link, color: Colors.white),
//                       Switch(
//                         value: isOn,
//                         onChanged: _handleToggle,
//                         activeColor: Colors.purpleAccent,
//                       ),
//                     ],
//                   ),
//
//                   // Middle: icons
//                   const Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       Icon(Icons.change_history, color: Colors.white38),
//                       Icon(Icons.settings, color: Colors.white38),
//                       Icon(Icons.brightness_6, color: Colors.white38),
//                     ],
//                   ),
//
//                   // Bottom: title and brightness
//                   Column(
//                     children: [
//                       Text(
//                         widget.title,
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       const SizedBox(height: 4),
//                       Text(
//                         'Brightness: ${brightness.toInt()}%',
//                         style: const TextStyle(color: Colors.white70),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

