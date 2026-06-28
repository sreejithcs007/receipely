import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class TagChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;

  const TagChip({
    required this.label,
    this.icon,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = backgroundColor ?? context.grey.c100;
    final Color foreground = textColor ?? context.grey.c700;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space10,
        vertical: Dimensions.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12.0, color: foreground),
            const SizedBox(width: Dimensions.space4),
          ],
          Text(
            label,
            style: context.typography.textXs.semibold.copyWith(
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
