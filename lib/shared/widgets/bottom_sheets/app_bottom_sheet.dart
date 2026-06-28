import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class AppBottomSheet extends StatelessWidget {
  final String title;
  final Widget child;

  const AppBottomSheet({required this.title, required this.child, super.key});

  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AppBottomSheet(title: title, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 40.0),
      decoration: BoxDecoration(
        color: context.white.c50,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(Dimensions.radiusXl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Dimensions.v12,
          Container(
            width: 40.0,
            height: 5.0,
            decoration: BoxDecoration(
              color: context.grey.c300,
              borderRadius: BorderRadius.circular(Dimensions.radiusFull),
            ),
          ),
          Dimensions.v16,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Dimensions.space16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: context.typography.textLg.bold.copyWith(
                      color: context.grey.c900,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1.0),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: Dimensions.space16,
                right: Dimensions.space16,
                top: Dimensions.space16,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom +
                    Dimensions.space24,
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
