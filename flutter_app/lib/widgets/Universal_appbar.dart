import 'package:flutter/material.dart';
import 'package:kkhazardscan/Design/style_constant.dart';

class UniversalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;

  const UniversalAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.backgroundWhite,
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
        style: AppTypography.Bluesubheading,
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