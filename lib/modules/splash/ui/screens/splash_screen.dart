import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _controller.forward();

    Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        const OnboardingRoute().go(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [context.primary.c50, context.white.c50],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(Dimensions.space24),
                  decoration: BoxDecoration(
                    color: context.primary.c500,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: context.primary.c500.withValues(alpha: 0.3),
                        blurRadius: 24.0,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    AppImages.splashLogo,
                    width: 64.0,
                    height: 64.0,
                    color: context.white.c50,
                  ),
                ),
                Dimensions.v24,
                Text(
                  context.l10n.appTitle,
                  style: context.typography.displayMd.bold.copyWith(
                    color: context.grey.c900,
                    letterSpacing: -1.0,
                  ),
                ),
                Dimensions.v8,
                Text(
                  context.l10n.splashTagline,
                  style: context.typography.textLg.medium.copyWith(
                    color: context.primary.c500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
