import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

enum PremiumButtonVariant {
  primary,
  secondary,
  outline,
  text,
}

enum PremiumButtonSize {
  small,
  medium,
  large,
}

class PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final PremiumButtonVariant variant;
  final PremiumButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double? width;

  const PremiumButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant = PremiumButtonVariant.primary,
    this.size = PremiumButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.width,
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    if (widget.variant == PremiumButtonVariant.primary) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      _scaleController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _handleTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = !widget.isDisabled && !widget.isLoading && widget.onPressed != null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: _buildButton(isEnabled),
          );
        },
      ),
    );
  }

  Widget _buildButton(bool isEnabled) {
    final buttonHeight = _getButtonHeight();
    final padding = _getPadding();
    final textStyle = _getTextStyle(isEnabled);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: widget.width,
      height: buttonHeight,
      decoration: _getDecoration(isEnabled),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading) ...[
                SizedBox(
                  width: _getIconSize(),
                  height: _getIconSize(),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getContentColor(isEnabled),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ] else if (widget.icon != null) ...[
                Icon(
                  widget.icon,
                  size: _getIconSize(),
                  color: _getContentColor(isEnabled),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.text,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getButtonHeight() {
    switch (widget.size) {
      case PremiumButtonSize.small:
        return 40;
      case PremiumButtonSize.medium:
        return 48;
      case PremiumButtonSize.large:
        return 56;
    }
  }

  EdgeInsets _getPadding() {
    switch (widget.size) {
      case PremiumButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case PremiumButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 12);
      case PremiumButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
    }
  }

  double _getIconSize() {
    switch (widget.size) {
      case PremiumButtonSize.small:
        return 16;
      case PremiumButtonSize.medium:
        return 20;
      case PremiumButtonSize.large:
        return 24;
    }
  }

  TextStyle _getTextStyle(bool isEnabled) {
    final fontSize = widget.size == PremiumButtonSize.small ? 14.0 : 
                    widget.size == PremiumButtonSize.medium ? 16.0 : 18.0;
    
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: _getContentColor(isEnabled),
    );
  }

  Color _getContentColor(bool isEnabled) {
    if (!isEnabled) {
      return AppColors.onSurfaceVariant.withOpacity(0.5);
    }

    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return Colors.white;
      case PremiumButtonVariant.secondary:
        return Colors.white;
      case PremiumButtonVariant.outline:
        return AppColors.primary;
      case PremiumButtonVariant.text:
        return AppColors.primary;
    }
  }

  BoxDecoration _getDecoration(bool isEnabled) {
    final borderRadius = BorderRadius.circular(
      widget.size == PremiumButtonSize.small ? 12 : 
      widget.size == PremiumButtonSize.medium ? 16 : 20,
    );

    if (!isEnabled) {
      return BoxDecoration(
        borderRadius: borderRadius,
        color: AppColors.outline.withOpacity(0.3),
        border: Border.all(
          color: AppColors.outline.withOpacity(0.5),
          width: 1,
        ),
      );
    }

    switch (widget.variant) {
      case PremiumButtonVariant.primary:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.primary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.surface.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        );

      case PremiumButtonVariant.secondary:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.secondary,
              AppColors.secondary.withOpacity(0.8),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.secondary.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case PremiumButtonVariant.outline:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Colors.transparent,
          border: Border.all(
            color: AppColors.primary,
            width: 2,
          ),
        );

      case PremiumButtonVariant.text:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: AppColors.primary.withOpacity(0.1),
        );
    }
  }
}
