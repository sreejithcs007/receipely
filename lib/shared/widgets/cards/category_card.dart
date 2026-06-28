import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class CategoryCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;
  final Color? activeColor;

  const CategoryCard({
    required this.label,
    required this.icon,
    this.isActive = false,
    required this.onTap,
    this.activeColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final Color primaryActiveColor = activeColor ?? context.primary.c500;
    final Color cardBackground =
        isActive
            ? primaryActiveColor.withValues(alpha: 0.12)
            : context.grey.c50;
    final Color contentColor = isActive ? primaryActiveColor : context.grey.c600;
    final Border? cardBorder =
        isActive ? Border.all(color: primaryActiveColor, width: 1.5) : null;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60.0,
            height: 60.0,
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(Dimensions.radiusMd),
              border: cardBorder,
            ),
            child: Icon(icon, color: contentColor, size: 28.0),
          ),
          const SizedBox(height: Dimensions.space8),
          Text(
            label,
            style: context.typography.textXs.medium.copyWith(
              color: isActive ? context.grey.c900 : context.grey.c600,
            ),
          ),
        ],
      ),
    );
  }
}
