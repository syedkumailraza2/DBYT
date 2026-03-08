import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primaryDark = Color(0xFF0B1215);
  static const Color primaryTeal = Color(0xFF18424E);
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // CTA Colors
  static const Color ctaRed = Color(0xFFFF383C);
  static const Color ctaOrange = Color(0xFFFF8D28);
  static const Color ctaGreen = Color(0xFF34C759);
  static const Color ctaBlue = Color(0xFF0088FF);

  // Neutral Colors
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryDark],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ctaOrange, ctaRed],
  );

  // Shimmer gradient for animations
  static const LinearGradient shimmerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF18424E),
      Color(0xFF2A5A68),
      Color(0xFF18424E),
    ],
    stops: [0.0, 0.5, 1.0],
  );
}
