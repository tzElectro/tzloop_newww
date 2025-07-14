import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';
import '../../../../core/theme/app_colors.dart';

class BentoEffectCard extends StatelessWidget {
  final WLEDEffect effect;
  final bool isSelected;
  final double speed;
  final double intensity;
  final VoidCallback onTap;
  final ValueChanged<double> onSpeedChanged;
  final ValueChanged<double> onIntensityChanged;

  const BentoEffectCard({
    super.key,
    required this.effect,
    required this.isSelected,
    required this.speed,
    required this.intensity,
    required this.onTap,
    required this.onSpeedChanged,
    required this.onIntensityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ]
            : [],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      effect.name,
                      style: GoogleFonts.poppins(
                        color: AppColors.onSurface,
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.check,
                          size: 16, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          if (isSelected)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant.withOpacity(0.06),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    _buildSlider(
                      context,
                      label: "Speed",
                      icon: Icons.speed,
                      value: speed,
                      onChanged: onSpeedChanged,
                    ),
                    const SizedBox(height: 12),
                    _buildSlider(
                      context,
                      label: "Intensity",
                      icon: Icons.brightness_medium,
                      value: intensity,
                      onChanged: onIntensityChanged,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSlider(
    BuildContext context, {
    required String label,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: AppColors.onSurface,
                fontSize: 14,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: GoogleFonts.poppins(
                color: AppColors.onSurfaceVariant,
                fontSize: 13,
              ),
            )
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.outline,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.2),
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
