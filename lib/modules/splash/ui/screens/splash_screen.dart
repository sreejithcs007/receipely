import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipe_flutter/shared/core/constants/asset_constants.dart';
import '../../../../router/routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to onboarding after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted) const OnboardingRoute().go(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
          children: [
            /// Background
            Positioned.fill(
              child: Image.asset(
                AppImages.splashBg,
                fit: BoxFit.cover,
                // Gradient fallback until the file is present
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFAEFE0),
                        Color(0xFFF5E3C8),
                        Color(0xFFEDD5B0),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            /// Text overlay
            SafeArea(
              child: Align(
                alignment: const Alignment(0, 0.45),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Recipely",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 52,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3A2818),
                        letterSpacing: -.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      "Delicious recipes, made simple",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFF28C28),
                        letterSpacing: .2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
