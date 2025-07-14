import 'package:flutter/material.dart';
import 'premium_status_indicators.dart';

/// Global feedback manager for showing status messages
class FeedbackManager {
  static final FeedbackManager _instance = FeedbackManager._internal();
  factory FeedbackManager() => _instance;
  FeedbackManager._internal();

  OverlayEntry? _currentOverlay;

  /// Show a success message
  static void showSuccess(BuildContext context, String message,
      {Duration? duration}) {
    _instance._showFeedback(
      context,
      SuccessFeedback(
        message: message,
        duration: duration ?? const Duration(seconds: 3),
        onDismiss: () => _instance._removeFeedback(),
      ),
    );
  }

  /// Show an error message
  static void showError(BuildContext context, String message,
      {VoidCallback? onRetry}) {
    _instance._showFeedback(
      context,
      ErrorFeedback(
        message: message,
        onRetry: onRetry,
        onDismiss: () => _instance._removeFeedback(),
      ),
    );
  }

  /// Show a loading message
  static void showLoading(BuildContext context, String message) {
    _instance._showFeedback(
      context,
      Container(
        color: Colors.black54,
        child: Center(
          child: PremiumLoadingIndicator(
            message: message,
            size: 48,
          ),
        ),
      ),
    );
  }

  /// Hide current feedback
  static void hide() {
    _instance._removeFeedback();
  }

  void _showFeedback(BuildContext context, Widget feedback) {
    _removeFeedback();

    final overlay = Overlay.of(context, rootOverlay: true);

    _currentOverlay = OverlayEntry(
      builder: (context) => Directionality(
        textDirection: TextDirection.ltr,
        child: Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: feedback,
          ),
        ),
      ),
    );

    overlay.insert(_currentOverlay!);
  }

  void _removeFeedback() {
    if (_currentOverlay != null) {
      try {
        _currentOverlay?.remove();
      } catch (e) {
        // Ignore errors when removing overlay
      }
      _currentOverlay = null;
    }
  }
}

/// Widget wrapper for providing feedback manager context
class FeedbackProvider extends StatelessWidget {
  final Widget child;

  const FeedbackProvider({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

/// Utility extension for BuildContext to show feedback easily
extension FeedbackContext on BuildContext {
  void showSuccess(String message) =>
      FeedbackManager.showSuccess(this, message);
  void showError(String message, {VoidCallback? onRetry}) =>
      FeedbackManager.showError(this, message, onRetry: onRetry);
  void showLoading(String message) =>
      FeedbackManager.showLoading(this, message);
  void hideFeedback() => FeedbackManager.hide();
}
