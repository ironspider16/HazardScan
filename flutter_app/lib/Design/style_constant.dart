import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color primaryBlueLight = Color(0xFF3366CC);

  static const Color primaryTint = Color.fromARGB(22, 37, 100, 235);

  // Neutral colors
  static const Color textMain = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF9E9E9E);
  static const Color borderGrey = Color(0xFFBDBDBD);
  static const Color backgroundWhite = Colors.white;
}

class AppDimensions {
  // Standardised border radii used throughout the app
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 20.0;
}

class AppPadding {
  static const double tight = 8.0;
  static const double medium = 16.0;
  static const double large = 24.0;
  static const double extraLarge = 32.0;
  static const double Largest = 40.0;
  static const double page = 24.0;
}

class AppTypography {
  // Standard heading style for page titles
  static const TextStyle Blueheading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue,
  );

  static const TextStyle Blackheading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain,
  );

  static const TextStyle Bluesubheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue,
  );

  static const TextStyle Blacksubheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain,
  );

  // Standard body text for labels and inputs
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMain,
  );

  static const TextStyle faintbody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
