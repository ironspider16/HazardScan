import 'package:flutter/material.dart';
import '../Design/style_constant.dart';

class SwpCategoryCard extends StatelessWidget {
  final String CategoryName;
  final bool isSelected;
  final VoidCallback onTap;

  const SwpCategoryCard({
    super.key,
    required this.isSelected,
    required this.CategoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.primaryTint,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(AppPadding.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  width: AppPadding.medium,
                  height: AppPadding.medium,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? AppColors.primaryBlue
                        : Colors.transparent,
                    border: isSelected
                        ? Border.all(color: AppColors.backgroundWhite, width: 2)
                        : Border.all(color: AppColors.textSecondary, width: 1),
                  ),
                ),
                const SizedBox(width: AppPadding.tight),
                Expanded(
                  child: Text(
                    CategoryName,
                    style: AppTypography.body,
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
