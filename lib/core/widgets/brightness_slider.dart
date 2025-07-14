import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class CustomSliderThumbShape extends SliderComponentShape {
  final double enabledThumbRadius;
  final double pressedElevation;

  const CustomSliderThumbShape({
    required this.enabledThumbRadius,
    this.pressedElevation = 6.0,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(enabledThumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;

    // Outer ring with premium glow
    final Paint glowPaint = Paint()
      ..color = AppColors.secondary.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius + 4, glowPaint);

    // Main thumb with gradient
    final Rect thumbRect = Rect.fromCircle(
      center: center,
      radius: enabledThumbRadius,
    );
    final Paint thumbPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          AppColors.secondary,
          AppColors.secondary.withOpacity(0.8),
        ],
      ).createShader(thumbRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius, thumbPaint);

    // Inner highlight
    final Paint highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, enabledThumbRadius * 0.6, highlightPaint);

    // Border
    final Paint borderPaint = Paint()
      ..color = AppColors.surface
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, enabledThumbRadius, borderPaint);
  }
}

class BrightnessSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final bool showLabel;
  final Widget Function(BuildContext context, double value)? overlayBuilder;
  final Widget Function(BuildContext context, double value, bool isActive)?
      thumbBuilder;

  const BrightnessSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.showLabel = true,
    this.overlayBuilder,
    this.thumbBuilder,
  });

  @override
  State<BrightnessSlider> createState() => _BrightnessSliderState();
}

class _BrightnessSliderState extends State<BrightnessSlider> {
  late double _currentValue;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(BrightnessSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging && oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.outline.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.brightness_6,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Brightness',
                      style: GoogleFonts.poppins(
                        color: AppColors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(_currentValue * 100).round()}%',
                    style: GoogleFonts.poppins(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        Container(
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface,
                AppColors.surface.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppColors.outline.withOpacity(0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.secondary,
                  inactiveTrackColor: AppColors.outline,
                  thumbColor: AppColors.secondary,
                  overlayColor: AppColors.secondary.withOpacity(0.2),
                  trackHeight: 6.0,
                  thumbShape: widget.thumbBuilder == null
                      ? const CustomSliderThumbShape(
                          enabledThumbRadius: 12.0,
                          pressedElevation: 8.0,
                        )
                      : const RoundSliderThumbShape(
                          enabledThumbRadius: 0.1,
                        ),
                  overlayShape: widget.overlayBuilder == null
                      ? const RoundSliderOverlayShape(overlayRadius: 20.0)
                      : const RoundSliderOverlayShape(overlayRadius: 0.1),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: _currentValue,
                  min: 0,
                  max: 1,
                  divisions: 100,
                  onChangeStart: (_) {
                    setState(() {
                      _isDragging = true;
                    });
                  },
                  onChanged: (value) {
                    setState(() {
                      _currentValue = value;
                    });
                    widget.onChanged(value);
                  },
                  onChangeEnd: (_) {
                    setState(() {
                      _isDragging = false;
                    });
                  },
                ),
              ),
              if (widget.thumbBuilder != null)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final sliderWidth = constraints.maxWidth - 16;
                    final thumbPosition = 8 + (_currentValue * sliderWidth);
                    return Positioned(
                      left: thumbPosition - 12,
                      child: widget.thumbBuilder!(
                          context, _currentValue, _isDragging),
                    );
                  },
                ),
              if (widget.overlayBuilder != null && _isDragging)
                Positioned(
                  left: (_currentValue *
                          MediaQuery.of(context).size.width *
                          0.8) -
                      12,
                  child:
                      widget.thumbBuilder!(context, _currentValue, _isDragging),
                ),
              // Custom overlay
              if (widget.overlayBuilder != null && _isDragging)
                Positioned(
                  top: -40,
                  child: widget.overlayBuilder!(context, _currentValue),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
