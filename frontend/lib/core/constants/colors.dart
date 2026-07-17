import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFF4F46E5);      // Premium Indigo
  static const Color secondary = Color(0xFF7C3AED);    // Premium Purple
  static const Color accent = Color(0xFF06B6D4);       // Premium Cyan
  
  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Slate 50
  static const Color backgroundDark = Color(0xFF0F172A);  // Slate 900
  
  // Surface / Cards
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E293B);     // Slate 800
  
  // Semantic Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  
  // Text Colors
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF64748B); // Slate 500
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);  // Slate 400

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0); // Slate 200
  static const Color borderDark = Color(0xFF334155);  // Slate 700

  // Modern Gradients
  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient accentGradient = LinearGradient(
    colors: [secondary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassBorderGradient = LinearGradient(
    colors: [
      Color(0x33FFFFFF),
      Color(0x0DFFFFFF),
      Color(0x0DFFFFFF),
      Color(0x33FFFFFF),
    ],
    stops: [0.0, 0.25, 0.75, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Gradient glassBorderDarkGradient = LinearGradient(
    colors: [
      Color(0x1AFFFFFF),
      Color(0x05FFFFFF),
      Color(0x05FFFFFF),
      Color(0x1AFFFFFF),
    ],
    stops: [0.0, 0.25, 0.75, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
