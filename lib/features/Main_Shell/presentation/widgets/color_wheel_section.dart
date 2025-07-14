import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tzloop_newww/core/widgets/color_picker_widget.dart';
import '../../../../core/theme/app_colors.dart';

class ColorWheelSection extends StatelessWidget {
  final Color initialColor;
  final Function(Color) onColorChanged;

  const ColorWheelSection({
    Key? key,
    required this.initialColor,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.palette, color: AppColors.primary),
                const SizedBox(width: 12),
                Text(
                  'Color Wheel',
                  style: GoogleFonts.poppins(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          RepaintBoundary(
            child: SizedBox(
              height: MediaQuery.of(context).size.width * 0.9,
              child: Center(
                child: ColorWheelPicker(
                  initialColor: initialColor,
                  size: MediaQuery.of(context).size.width * 0.8,
                  onColorChanged: onColorChanged,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
