import 'package:flutter/material.dart';
import '../../utils/extension/context_extension.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title; // String or Widget
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;

  const AppAppBar({
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.bottom,
    this.backgroundColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    Widget? titleWidget;
    if (title is String) {
      titleWidget = Text(
        title as String,
        style: context.typography.displayXs.semibold.copyWith(
          color: context.grey.c900,
        ),
      );
    } else if (title is Widget) {
      titleWidget = title as Widget;
    }

    return AppBar(
      title: titleWidget,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ?? Colors.transparent,
      leading:
          showBackButton && Navigator.canPop(context)
              ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: context.grey.c900),
                onPressed: () => Navigator.pop(context),
              )
              : null,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}
