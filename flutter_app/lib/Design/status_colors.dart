import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class SafetyStatusHelper {
  static Color getColor(String? status) {
    if (status == null) return Colors.grey.shade600;

    final String upperStatus = status.toUpperCase();

    if (upperStatus == 'DANGEROUS') {
      return Colors.red.shade700;
    } else if (upperStatus == 'PARTIALLY COMPLIANT') {
      return Colors.orange.shade700;
    } else if (upperStatus == 'COMPLIANT') {
      return AppColors.primaryBlue;
    } else if (upperStatus == 'SAFE') {
      return Colors.green.shade700;
    }
    return Colors.grey.shade600;
  }
}
