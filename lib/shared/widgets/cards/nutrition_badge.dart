import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class NutritionBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? textColor;

  const NutritionBadge({
    required this.label,
    required this.value,
    this.backgroundColor,
    this.textColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color background = backgroundColor ?? context.secondary.c50;
    final Color foreground = textColor ?? context.secondary.c600;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space12,
        vertical: Dimensions.space8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(Dimensions.radiusMd),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: context.typography.textSm.bold.copyWith(color: foreground),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: context.typography.textXs.medium.copyWith(
              color: context.grey.c500,
            ),
          ),
        ],
      ),
    );
  }
}
