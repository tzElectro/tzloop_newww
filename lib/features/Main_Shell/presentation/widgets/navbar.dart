import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool mainNav;

  const CustomBottomNavBar({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.mainNav = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.onSurfaceVariant,
      currentIndex: currentIndex,
      onTap: onTap,
      showSelectedLabels: true,
      showUnselectedLabels: true,
      selectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
      items: mainNav
          ? const [
              BottomNavigationBarItem(
                icon: Icon(Icons.devices, size: 28),
                label: 'Devices',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.layers, size: 28),
                label: 'Scenes',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.mic, size: 28),
                label: 'Sound Sync',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today, size: 28),
                label: 'Schedule',
              ),
            ]
          : const [
              BottomNavigationBarItem(
                icon: Icon(Icons.palette, size: 28),
                label: 'Color Picker',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings, size: 28),
                label: 'Settings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_module, size: 28),
                label: 'Instances',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.view_module, size: 28),
                label: 'More', // Changed label to avoid duplication
              ),
            ],
    );
  }
}
