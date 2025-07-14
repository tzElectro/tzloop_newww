import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class ColorWheelPicker extends StatefulWidget {
  final void Function(Color) onColorChanged;
  final double size; // 👈 Add this line
  final Color initialColor;

  const ColorWheelPicker({
    super.key,
    required this.onColorChanged,
    this.size = 300, // 👈 Optional default size
    required this.initialColor,
  });

  @override
  State<ColorWheelPicker> createState() => _ColorWheelPickerState();
}

class _ColorWheelPickerState extends State<ColorWheelPicker> {
  Offset _thumbPos = Offset.zero;
  late Offset _center;
  late double _radius;
  ui.Image? _wheelImage;
  bool _isLoading = true;
  late Color _currentColor;

  @override
  void initState() {
    super.initState();
    _currentColor = widget.initialColor;
    _generateWheelImage();
  }

  @override
  void didUpdateWidget(ColorWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _currentColor = widget.initialColor;
      _updateThumbPosition();
    }
  }

  void _updateThumbPosition() {
    if (_center == null || _radius == null) return;

    final hsv = HSVColor.fromColor(_currentColor);
    final angle = hsv.hue * pi / 180;
    final distance = hsv.saturation * _radius;

    final dx = cos(angle) * distance;
    final dy = sin(angle) * distance;

    setState(() {
      _thumbPos = Offset(_center.dx + dx, _center.dy + dy);
    });
  }

  Future<void> _generateWheelImage() async {
    final int size = widget.size.toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    final paint = Paint();
    for (int x = 0; x < size; x++) {
      for (int y = 0; y < size; y++) {
        final dx = x - center.dx;
        final dy = y - center.dy;
        final distance = sqrt(dx * dx + dy * dy);
        if (distance > radius) continue;

        final angle = atan2(dy, dx);
        final hue = (angle * 180 / pi + 360) % 360;
        final saturation = distance / radius;
        paint.color = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();
        canvas.drawRect(Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1), paint);
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);

    setState(() {
      _wheelImage = image;
      _center = center;
      _radius = radius;
      _isLoading = false;
      _updateThumbPosition(); // Initialize thumb position based on initial color
    });
  }

  void _handleTouch(Offset position) {
    final dx = position.dx - _center.dx;
    final dy = position.dy - _center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > _radius) return;

    final angle = atan2(dy, dx);
    final hue = (angle * 180 / pi + 360) % 360;
    final saturation = distance / _radius;
    final color = HSVColor.fromAHSV(1.0, hue, saturation, 1.0).toColor();

    setState(() {
      _thumbPos = position;
      _currentColor = color;
    });

    widget.onColorChanged(color);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.size / 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.primary.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: GestureDetector(
        onPanDown: (details) => _handleTouch(details.localPosition),
        onPanUpdate: (details) => _handleTouch(details.localPosition),
        child: CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _ColorWheelPainter(_wheelImage!),
          foregroundPainter: _PremiumThumbPainter(_thumbPos),
        ),
      ),
    );
  }
}

class _ColorWheelPainter extends CustomPainter {
  final ui.Image image;

  _ColorWheelPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    canvas.drawImage(image, Offset.zero, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PremiumThumbPainter extends CustomPainter {
  final Offset position;

  _PremiumThumbPainter(this.position);

  @override
  void paint(Canvas canvas, Size size) {
    // Outer glow
    final glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary.withOpacity(0.4);
    canvas.drawCircle(position, 16, glowPaint);

    // Main thumb with gradient
    final thumbRect = Rect.fromCircle(center: position, radius: 12);
    final thumbPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white,
          AppColors.surface.withOpacity(0.9),
        ],
      ).createShader(thumbRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(position, 12, thumbPaint);

    // Inner ring
    final innerPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.primary
      ..strokeWidth = 3;
    canvas.drawCircle(position, 8, innerPaint);

    // Border
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = AppColors.surface
      ..strokeWidth = 2;
    canvas.drawCircle(position, 12, borderPaint);

    // Center dot
    final centerPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.primary;
    canvas.drawCircle(position, 3, centerPaint);
  }

  @override
  bool shouldRepaint(covariant _PremiumThumbPainter oldDelegate) {
    return oldDelegate.position != position;
  }
}

class ColorPickerWidget extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPickerWidget({
    Key? key,
    required this.color,
    required this.onColorChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface,
            AppColors.surface.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.palette,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Color Palette',
                style: GoogleFonts.poppins(
                  color: AppColors.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Enhanced Color Picker
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: ColorPicker(
              pickerColor: color,
              onColorChanged: onColorChanged,
              colorPickerWidth: 280,
              pickerAreaHeightPercent: 0.7,
              enableAlpha: false,
              displayThumbColor: true,
              paletteType: PaletteType.hsvWithHue,
              labelTypes: const [],
              pickerAreaBorderRadius:
                  const BorderRadius.all(Radius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }
}
