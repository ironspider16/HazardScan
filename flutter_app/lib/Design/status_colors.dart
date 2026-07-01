import 'package:flutter/material.dart';

class SafetyStatusHelper {
  static Color getColor(String status) {
    final String upperStatus = status.toUpperCase();

    if (upperStatus.contains('PARTIALLY')) {
      return Colors.orange;
    } else if (upperStatus == 'COMPLIANT' || upperStatus == 'SAFE') {
      return Colors.green;
    } else if (upperStatus == 'DANGEROUS' || upperStatus.contains('NON')) {
      return Colors.red;
    }
    return Colors.grey;
  }
}
