import 'package:flutter/material.dart';

class AppGradients {
  // Subtle professional gradient (light): Sky blue to Indigo with ~15% opacity
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0x260EA5E9), // Sky blue (alpha 0x26 ~ 15%)
      Color(0x266366F1), // Indigo (alpha 0x26 ~ 15%)
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0x330EA5E9), // Slightly stronger for buttons (alpha ~ 20%)
      Color(0x336366F1),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
