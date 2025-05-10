import 'package:flutter/material.dart';

class AppGradients {
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [
      Color(0x80FF512F), // 50% opacity for Vibrant Orange
      Color(0x80DD2476), // 50% opacity for Hot Pink
    ], // Dark teal to blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0x80FF512F), // 50% opacity for Hot Pink
      Color(0x80DD2476), // 50% opacity for Vibrant Orange
    ], // Light blue to green
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
