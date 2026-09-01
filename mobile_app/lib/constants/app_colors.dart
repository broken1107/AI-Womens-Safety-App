import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand & Accent Colors
  static const Color primary = Color(0xFFC6234A);
  static const Color primaryDark = Color(0xFFA01738);
  static const Color primaryLight = Color(0xFFFF5277);
  static const Color primaryContainer = Color(0xFFFFD9E1);
  static const Color onPrimaryContainer = Color(0xFF3F0013);

  static const Color secondary = Color(0xFF6D5A80);
  static const Color secondaryContainer = Color(0xFFF1DEFA);
  static const Color onSecondaryContainer = Color(0xFF271739);

  // Safety & Risk Status Colors (Accessibility-compliant)
  static const Color riskLow = Color(0xFF2E7D32); // Deep Green
  static const Color riskLowContainer = Color(0xFFE8F5E9);
  static const Color riskMedium = Color(0xFFE65100); // Deep Amber/Orange
  static const Color riskMediumContainer = Color(0xFFFFF3E0);
  static const Color riskHigh = Color(0xFFC62828); // Vivid Alert Red
  static const Color riskHighContainer = Color(0xFFFFEBEE);

  // Emergency Services Colors
  static const Color policeBlue = Color(0xFF1565C0);
  static const Color hospitalTeal = Color(0xFF00796B);
  static const Color fireOrange = Color(0xFFD84315);
  static const Color sosRed = Color(0xFFD32F2F);

  // UI Surfaces & Text Neutrals
  static const Color backgroundLight = Color(0xFFF9F9FB);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  static const Color backgroundDark = Color(0xFF121216);
  static const Color surfaceDark = Color(0xFF1E1E24);
  static const Color cardDark = Color(0xFF25252D);

  static const Color textPrimaryLight = Color(0xFF1C1B1F);
  static const Color textSecondaryLight = Color(0xFF49454F);
  static const Color textPrimaryDark = Color(0xFFE6E1E5);
  static const Color textSecondaryDark = Color(0xFFCAC4D0);

  // Status & Utility
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFE65100);
  static const Color danger = Color(0xFFC62828);
  static const Color info = Color(0xFF0288D1);
  static const Color mapBlue = Color(0xFF1976D2);
  static const Color divider = Color(0xFFE0E0E0);
}
