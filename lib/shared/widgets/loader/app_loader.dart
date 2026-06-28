import 'package:flutter/material.dart';
import '../../utils/extension/context_extension.dart';

class AppLoader extends StatelessWidget {
  final double size;
  const AppLoader({this.size = 32.0, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: 3.0,
          valueColor: AlwaysStoppedAnimation<Color>(context.primary.c500),
        ),
      ),
    );
  }
}
