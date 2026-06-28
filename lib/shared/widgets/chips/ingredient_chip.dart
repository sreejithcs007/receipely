import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class IngredientChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const IngredientChip({required this.label, required this.onDeleted, super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.space12,
        vertical: Dimensions.space6,
      ),
      decoration: BoxDecoration(
        color: context.primary.c50,
        borderRadius: BorderRadius.circular(Dimensions.radiusFull),
        border: Border.all(color: context.primary.c100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: context.typography.textSm.medium.copyWith(
              color: context.primary.c600,
            ),
          ),
          const SizedBox(width: Dimensions.space4),
          GestureDetector(
            onTap: onDeleted,
            child: Icon(
              Icons.close,
              size: 14.0,
              color: context.primary.c600,
            ),
          ),
        ],
      ),
    );
  }
}
