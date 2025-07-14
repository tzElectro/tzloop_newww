import 'package:flutter/material.dart';

/// Premium brand color palette for WLED controller app
/// Teal + Amber combination for modern, premium feel
class AppColors {
  // Prevent instantiation
  AppColors._();

  // Primary Brand Colors
  static const Color background = Color(0xFF272727);      // Raisin black - main background
  static const Color primary = Color(0xFF00D4AA);         // Teal - primary accent
  static const Color secondary = Color(0xFFF59E0B);       // Amber - secondary accent
  static const Color success = Color(0xFF10B981);         // Emerald - success states
  static const Color warning = Color(0xFFFF6B35);         // Orange - warnings/alerts
  static const Color error = Color(0xFFEF4444);           // Red - error states

  // Surface Colors (for cards, containers, etc.)
  static const Color surface = Color(0xFF3A3A3A);         // Card backgrounds
  static const Color surfaceVariant = Color(0xFF4A4A4A);  // Elevated surfaces
  static const Color surfaceDim = Color(0xFF2A2A2A);      // Dimmed surfaces

  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);       // White text on primary
  static const Color onSecondary = Color(0xFF000000);     // Black text on secondary
  static const Color onBackground = Color(0xFFE5E5E5);    // Light text on background
  static const Color onSurface = Color(0xFFE5E5E5);       // Light text on surface
  static const Color onSurfaceVariant = Color(0xFFB0B0B0); // Muted text

  // Outline Colors
  static const Color outline = Color(0xFF5A5A5A);         // Borders, dividers
  static const Color outlineVariant = Color(0xFF4A4A4A);  // Subtle borders

  // Device Status Colors
  static const Color deviceOnline = Color(0xFF00D4AA);    // Device connected
  static const Color deviceOffline = Color(0xFF6B7280);   // Device offline
  static const Color deviceConnecting = Color(0xFFF59E0B); // Device connecting

  // Gradient Colors for premium effects
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00D4AA), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEAB308)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Brand color variants for different states
  static const Color primaryLight = Color(0xFF33E0BB);    // Lighter teal
  static const Color primaryDark = Color(0xFF00A085);     // Darker teal
  static const Color secondaryLight = Color(0xFFFBBF24);  // Lighter amber
  static const Color secondaryDark = Color(0xFFD97706);   // Darker amber

  // Utility method to get color with opacity
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Semantic color getters for easier usage
  static Color get cardBackground => surface;
  static Color get cardElevated => surfaceVariant;
  static Color get textPrimary => onBackground;
  static Color get textSecondary => onSurfaceVariant;
  static Color get accent => primary;
  static Color get accentSecondary => secondary;
}
