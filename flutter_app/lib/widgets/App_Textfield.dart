import 'package:flutter/material.dart';
import '../Design/style_constant.dart';

class AppTextfield extends StatelessWidget {
  final String label;
  final String? Function(String?)? validator;
  final String hint;
  final TextEditingController controller;
  final bool obscureText;
  final bool enabled;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int? Maxlines;

  const AppTextfield({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.Maxlines,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label using the standard body style but slightly bolder
        Text(
          label,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            color: enabled ? AppColors.textMain : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppPadding.tight),
        TextFormField(
          // Using TextFormField for better integration with Forms
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          maxLines: Maxlines ?? 1,
          style: AppTypography.body.copyWith(
            color: enabled ? AppColors.textMain : AppColors.textSecondary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20) : null,
            suffixIcon: suffixIcon,
            // If disabled, we can subtly change the fill color
            fillColor: enabled
                ? AppColors.backgroundWhite
                : AppColors.borderGrey.withValues(alpha: 0.5),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
