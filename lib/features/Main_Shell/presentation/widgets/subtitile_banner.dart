import 'package:flutter/material.dart';

class SubtitleBanner extends StatelessWidget {
  final String subtitle;

  const SubtitleBanner({super.key, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1C1C1E),
      padding: const EdgeInsets.only(bottom: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            subtitle.toUpperCase(),
            style: TextStyle(
              color: Colors.white.withOpacity(0.95),
              fontWeight: FontWeight.w500,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}
