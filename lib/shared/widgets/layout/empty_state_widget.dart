import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';
import '../buttons/primary_button.dart';

class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyStateWidget({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onActionPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Dimensions.space32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(Dimensions.space24),
              decoration: BoxDecoration(
                color: context.grey.c50,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48.0, color: context.grey.c400),
            ),
            Dimensions.v24,
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.typography.textLg.bold.copyWith(
                color: context.grey.c900,
              ),
            ),
            Dimensions.v8,
            Text(
              description,
              textAlign: TextAlign.center,
              style: context.typography.textSm.regular.copyWith(
                color: context.grey.c500,
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              Dimensions.v24,
              PrimaryButton(
                label: actionLabel!,
                onPressed: onActionPressed,
                width: 180.0,
                height: 44.0,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
