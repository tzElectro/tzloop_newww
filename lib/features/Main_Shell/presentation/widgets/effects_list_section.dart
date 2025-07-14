import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/effect_card.dart';
import '../../../../core/theme/app_colors.dart';

class EffectsListSection extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final bool isLoading;
  final List<WLEDEffect> effects;
  final int? selectedEffectId;
  final Map<int, double> effectSpeeds;
  final Map<int, double> effectIntensities;
  final Function(WLEDEffect) onEffectTap;
  final Function(int, double) onSpeedChanged;
  final Function(int, double) onIntensityChanged;

  const EffectsListSection({
    Key? key,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.isLoading,
    required this.effects,
    required this.selectedEffectId,
    required this.effectSpeeds,
    required this.effectIntensities,
    required this.onEffectTap,
    required this.onSpeedChanged,
    required this.onIntensityChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onToggleExpanded,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withAlpha(25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withAlpha(77),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.secondary),
                const SizedBox(width: 12),
                Text(
                  'Light Effects',
                  style: GoogleFonts.poppins(
                    color: AppColors.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.secondary),
                    ),
                  )
                else
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down),
                  ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          child: isExpanded
              ? Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: isLoading
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Loading effects...',
                                  style: TextStyle(
                                    color: AppColors.onSurface,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : effects.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      color: AppColors.error,
                                      size: 48,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No effects available',
                                      style: TextStyle(
                                        color: AppColors.onSurface,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'Please check your device connection',
                                      style: TextStyle(
                                        color: AppColors.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : AnimationLimiter(
                                key: const ValueKey('effectList'),
                                child: ListView.builder(
                                  itemCount: effects.length,
                                  padding: const EdgeInsets.only(top: 8),
                                  itemBuilder: (context, index) {
                                    final effect = effects[index];
                                    return AnimationConfiguration.staggeredList(
                                      position: index,
                                      delay: const Duration(milliseconds: 80),
                                      child: SlideAnimation(
                                        verticalOffset: 30.0,
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeOutCubic,
                                        child: FadeInAnimation(
                                          duration:
                                              const Duration(milliseconds: 400),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 6),
                                            child: BentoEffectCard(
                                              effect: effect,
                                              isSelected:
                                                  selectedEffectId == effect.id,
                                              speed: effectSpeeds[effect.id] ??
                                                  0.5,
                                              intensity: effectIntensities[
                                                      effect.id] ??
                                                  0.5,
                                              onTap: () => onEffectTap(effect),
                                              onSpeedChanged: (val) =>
                                                  onSpeedChanged(
                                                      effect.id, val),
                                              onIntensityChanged: (val) =>
                                                  onIntensityChanged(
                                                      effect.id, val),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
