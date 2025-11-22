import 'package:flutter/material.dart';

class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
}

class AppRadii {
  static const sm = Radius.circular(8);
  static const md = Radius.circular(12);
  static const lg = Radius.circular(16);
}

class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
}

class AppElevations {
  static const card = 2.0;
  static const cardRaised = 6.0;
}

class AppShadows {
  static List<BoxShadow> card(BuildContext context) => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}
