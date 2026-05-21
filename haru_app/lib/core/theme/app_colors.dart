import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF659B5E);
  static const primaryLight = Color(0xFF8BBF84);
  static const primarySurface = Color(0xFFE8F0E7);
  static const secondary = Color(0xFF556F44);
  static const dark = Color(0xFF283F3B);

  // Backgrounds
  static const background = Color(0xFFF7F6F2);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceVariant = Color(0xFFF0EFEB);
  static const card = Color(0xFFFFFFFF);

  // Text
  static const textPrimary = Color(0xFF1A1A18);
  static const textSecondary = Color(0xFF6B6B67);
  static const textHint = Color(0xFFAEAEA8);
  static const textOnPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const error = Color(0xFFD94F4F);
  static const success = Color(0xFF4CAF50);

  // Emotion tag palette
  static const emotionJoy = Color(0xFFFFF3CD);
  static const emotionSad = Color(0xFFD6E9FF);
  static const emotionAnger = Color(0xFFFFD6D6);
  static const emotionCalm = Color(0xFFD4F0E0);
  static const emotionAnxiety = Color(0xFFE8D5F5);
  static const emotionTired = Color(0xFFE8E4DF);

  // Habit heatmap shades (light → dark)
  static const heatmap0 = Color(0xFFEEEDE9);
  static const heatmap1 = Color(0xFFD4E8CF);
  static const heatmap2 = Color(0xFFA8D5A0);
  static const heatmap3 = Color(0xFF78BF6E);
  static const heatmap4 = Color(0xFF4A9940);

  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF78BF6E), Color(0xFF4A9940)],
  );

  static const splashGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF283F3B), Color(0xFF3A5A42), Color(0xFF4A7A52)],
  );
}
