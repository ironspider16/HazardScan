import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Color? titleColor;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;

  const UniversalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor = AppColors.backgroundWhite,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: centerTitle,
      leading: leading ?? (_shouldShowBackButton(context)
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context),
            )
          : null),
      title: Text(
        title,
        style: AppTypography.Bluesubheading.copyWith(color: titleColor ?? null),
      ),
      actions: actions,
    );
  }

  bool _shouldShowBackButton(BuildContext context) {
    final ModalRoute<dynamic>? parentRoute = ModalRoute.of(context);
    return parentRoute?.canPop ?? false;
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}