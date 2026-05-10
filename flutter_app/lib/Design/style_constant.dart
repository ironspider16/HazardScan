import 'package:flutter/material.dart';

class AppColors {
  // Primary blue used for buttons, icons, and focus states
  static const Color primaryBlue = Color(0xFF2563EB); // [2, 5-7]
  static const Color primaryBlueLight = Color(0xFF3366CC); // [3]
  
  // Light blue tint used for backgrounds of chips and list rows
  static const Color primaryTint = Color.fromARGB(22, 37, 100, 235); // [4, 7-9]
  
  // Neutral colors
  static const Color textMain = Color(0xFF333333); // [10, 11]
  static const Color textSecondary = Color(0xFF9E9E9E); // [2, 12]
  static const Color borderGrey = Color(0xFFBDBDBD); // [3]
  static const Color backgroundWhite = Colors.white; // [13-15]
}

class AppDimensions {
  // Standardised border radii used throughout the app
  static const double radiusSmall = 8.0; // [4, 7]
  static const double radiusMedium = 12.0; // [7, 9, 16, 17]
  static const double radiusLarge = 20.0;

}

class AppPadding {
  static const double tight = 8.0; // [8, 18]
  static const double medium = 16.0; // [1, 3, 4, 7, 9, 12, 16]
  static const double large = 24.0; // [2, 5, 10]
  static const double extraLarge = 32.0; 
  static const double Largest = 40.0;
  static const double page = 24.0;
}


class AppTypography {
  // Standard heading style for page titles
  static const TextStyle Blueheading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBlue, // [6, 15, 19]
  );

  static const TextStyle Blackheading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textMain, // [6, 15, 19]
  );

  static const TextStyle Bluesubheading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryBlue, // [6, 15, 19]
  );

  static const TextStyle Blacksubheading = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textMain, // [6, 15, 19]
  );

  // Standard body text for labels and inputs
  static const TextStyle body = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textMain, // [1, 10, 11]
  );

  static const TextStyle faintbody = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, // [1, 10, 11]
  );
}