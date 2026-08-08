import 'package:flutter/material.dart';

/// Centralized color design tokens for Mocuply (Light Glassmorphism + Jungle Theme).
class AppColors {
  AppColors._();

  // Backgrounds & Base Palette
  static const Color creamSoda = Color(0xFFFFF4CC);
  static const Color background = Color(0xFFFAF6E8); // Off-white cream soda base
  static const Color surface = Color(0xB3FFFFFF);    // Semi-transparent frosted white
  static const Color surfaceBorder = Color(0x3D1A4731); // Soft jungle green glass border
  static const Color surfaceSelected = Color(0x241A4731);
  static const Color canvasViewport = Color(0xFFF3EEDC); // Slightly warmer viewport background

  // Glassmorphism Tokens
  static const Color glassFill = Color(0x99FFFFFF);
  static const Color glassFillHover = Color(0xC8FFFFFF);
  static const Color glassBorder = Color(0x471A4731);
  static const Color glassBorderLight = Color(0x99FFFFFF);
  static const Color glassShadow = Color(0x1F1A4731);

  // Jungle Green Palette (Primary & Secondary)
  static const Color primary = Color(0xFF1A4731);      // Deep Jungle Green
  static const Color primaryDark = Color(0xFF0D281C);  // Darker Jungle Green
  static const Color primaryLight = Color(0xFF2D6A4F); // Vibrant Sage / Light Jungle
  static const Color secondary = Color(0xFF40916C);    // Medium Emerald / Mint

  // Accent Ambient Orbs for Glass Reflection Background
  static const Color orbJungle = Color(0x351A4731);
  static const Color orbCream = Color(0x60FFE899);
  static const Color orbSage = Color(0x3552B788);

  // Semantic
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // Badges
  static const Color badgeBg = Color(0x1F1A4731);

  // Text High-Contrast Colors
  static const Color textPrimary = Color(0xFF1A4731);
  static const Color textSecondary = Color(0xFF2D6A4F);
  static const Color textMuted = Color(0xFF5A7B6C);
  static const Color textOnPrimary = Colors.white;

  // Device Frames
  static const Color frameIphone = Color(0xFF1A4731);
  static const Color frameSamsung = Color(0xFF2D6A4F);
}
