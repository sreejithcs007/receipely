import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterPressed;
  final String? hintText;
  final bool autofocus;
  final FocusNode? focusNode;

  const AppSearchBar({
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onFilterPressed,
    this.hintText,
    this.autofocus = false,
    this.focusNode,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.white.c50,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
        border: Border.all(color: context.grey.c200),
        boxShadow: [
          BoxShadow(
            color: context.grey.c900.withValues(alpha: 0.02),
            blurRadius: 10.0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        autofocus: autofocus,
        focusNode: focusNode,
        style: context.typography.textMd.regular.copyWith(
          color: context.grey.c900,
        ),
        decoration: InputDecoration(
          hintText: hintText ?? context.l10n.searchPlaceholder,
          hintStyle: context.typography.textMd.regular.copyWith(
            color: context.grey.c400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: context.grey.c500,
            size: 20.0,
          ),
          suffixIcon:
              onFilterPressed != null
                  ? IconButton(
                    icon: Icon(
                      Icons.tune,
                      color: context.primary.c500,
                      size: 20.0,
                    ),
                    onPressed: onFilterPressed,
                  )
                  : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: Dimensions.space16,
          ),
        ),
      ),
    );
  }
}
