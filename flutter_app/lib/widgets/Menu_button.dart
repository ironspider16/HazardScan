import 'package:flutter/material.dart';
import '../Design/style_constant.dart';

class MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
  final IconData? icon;
  final bool isMini;
  final bool isDelete;

  const MenuButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isPrimary = false,
    this.isMini = false,
    this.isDelete = false,
    this.icon,
  });

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    // Determine colors based on isPrimary and _pressed state

    final Color backgroundColor = widget.isDelete
        ? (_pressed ? Colors.red[100]! : Colors.red[50]!)
        : (widget.isPrimary
              ? (_pressed ? AppColors.primaryBlue : AppColors.primaryBlueLight)
              :  (_pressed ? AppColors.primaryTint : AppColors.backgroundWhite));

    final Color contentColor = widget.isDelete
        ? (_pressed ? Colors.red[700]! : Colors.red)
        : (widget.isPrimary
              ? Colors.white
              : (_pressed ? AppColors.primaryBlue : AppColors.textMain));

    final Color borderColor = widget.isDelete
        ? (_pressed ? Colors.red : Colors.red[300]!)
        : (widget.isPrimary
              ? Colors.transparent
              : (_pressed ? AppColors.primaryBlue : AppColors.borderGrey));

    // Color backgroundColor = widget.isPrimary
    //     ? (_pressed ? AppColors.primaryBlue : AppColors.primaryBlueLight)
    //     : (_pressed ? AppColors.primaryTint : AppColors.backgroundWhite);

    // final Color contentColor = widget.isPrimary
    //     ? Colors.white
    //     : (_pressed ? AppColors.primaryBlue : AppColors.textMain);

    // final Color borderColor = widget.isPrimary
    //     ? Colors.transparent
    //     : (_pressed ? AppColors.primaryBlue : AppColors.borderGrey);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: double.infinity,
        height: widget.isMini ? 40 : 52, // Standardized touch target height
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(
            AppDimensions.radiusMedium,
          ), // 12.0 from your constants
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: widget.isPrimary && !_pressed
              ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, size: 20, color: contentColor),
              const SizedBox(
                width: AppPadding.tight,
              ), // 8.0 from your constants
            ],
            Text(
              widget.label,
              style: AppTypography.body.copyWith(
                // Using AppTypography
                color: contentColor,
                fontWeight: FontWeight.w600,
                fontSize: widget.isMini ? 12 : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
