import 'package:flutter/material.dart';
import 'package:tzloop_newww/features/Main_Shell/domain/models/wled_effect.dart';
import 'package:tzloop_newww/features/Main_Shell/presentation/widgets/effect_card.dart';

class EffectList extends StatelessWidget {
  final List<WLEDEffect> effects;
  final int? selectedEffectId;
  final Map<int, double> effectSpeeds;
  final Map<int, double> effectIntensities;
  final void Function(WLEDEffect effect) onEffectTap;
  final void Function(int effectId, double speed) onSpeedChange;
  final void Function(int effectId, double intensity) onIntensityChange;

  const EffectList({
    super.key,
    required this.effects,
    required this.selectedEffectId,
    required this.effectSpeeds,
    required this.effectIntensities,
    required this.onEffectTap,
    required this.onSpeedChange,
    required this.onIntensityChange,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(    
      itemCount: effects.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final effect = effects[index];
        final isSelected = selectedEffectId == effect.id;

        return BentoEffectCard(
          effect: effect,
          isSelected: isSelected,
          speed: effectSpeeds[effect.id] ?? 0.5,
          intensity: effectIntensities[effect.id] ?? 0.5,
          onTap: () => onEffectTap(effect),
          onSpeedChanged: (value) => onSpeedChange(effect.id, value),
          onIntensityChanged: (value) => onIntensityChange(effect.id, value),
        );
      },
    );
  }
} 