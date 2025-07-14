import 'package:flutter/material.dart';
import '../../../../core/widgets/premium_status_indicators.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final IconData? rightIcon;
  final VoidCallback? onRightTap;
  final bool? showConnectionStatus;
  final bool? isConnected;
  final String? deviceName;
  final VoidCallback? onRetryConnection;

  const CustomAppBar({
    super.key,
    required this.title,
    this.rightIcon,
    this.onRightTap,
    this.showConnectionStatus = false,
    this.isConnected = false,
    this.deviceName,
    this.onRetryConnection,
  });

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return AppBar(
      backgroundColor: Colors.black,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Main app bar content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Builder(
                  builder: (context) => IconButton(
                    icon: Icon(
                      canPop ? Icons.arrow_back : Icons.menu,
                      color: Colors.white,
                    ),
                    onPressed: canPop
                        ? () => Navigator.of(context).maybePop()
                        : () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                if (rightIcon != null)
                  IconButton(
                    icon: Icon(rightIcon, color: Colors.white),
                    onPressed: onRightTap,
                  )
                else
                  const SizedBox(width: 48), // For layout spacing
              ],
            ),
          ),
          // Connection status indicator (optional)
          if (showConnectionStatus == true)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: ConnectionStatusIndicator(
                isConnected: isConnected ?? false,
                deviceName: deviceName,
                onRetry: onRetryConnection,
              ),
            ),
        ],
      ),
    );
  }
}
