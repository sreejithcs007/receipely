import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import '../../../../shared/core/constants/dimensions.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../../../shared/widgets/buttons/secondary_button.dart';
import '../../../../shared/utils/extension/context_extension.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _slides = [
    OnboardingSlideData(
      titleKey: (context) => context.l10n.onboarding1Title,
      description: 'Search from thousands of user-reviewed recipes and chef picks with custom nutrition stats.',
      imagePath: AppImages.onboardingDiscover,
      colorBuilder: (context) => context.primary.c500,
    ),
    OnboardingSlideData(
      titleKey: (context) => context.l10n.onboarding2Title,
      description: 'Input ingredients from your pantry and let our AI suggest creative chef-level recipes.',
      imagePath: AppImages.onboardingAi,
      colorBuilder: (context) => context.secondary.c500,
    ),
    OnboardingSlideData(
      titleKey: (context) => context.l10n.onboarding3Title,
      description: 'Easily set up your weekly planner slots and sync lists for grocery shopping in realtime.',
      imagePath: AppImages.onboardingPlan,
      colorBuilder: (context) => Colors.amber,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      const LoginRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.white.c50,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space16,
                vertical: Dimensions.space12,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => const LoginRoute().go(context),
                  child: Text(
                    'Skip',
                    style: context.typography.textMd.medium.copyWith(
                      color: context.grey.c500,
                    ),
                  ),
                ),
              ),
            ),
            // Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Dimensions.space24,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Onboarding Graphic
                        Container(
                          width: 240.0,
                          height: 240.0,
                          decoration: BoxDecoration(
                            color: slide.colorBuilder(context).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(Dimensions.space24),
                          child: Image.asset(
                            slide.imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: Dimensions.space40),
                        Text(
                          slide.titleKey(context),
                          textAlign: TextAlign.center,
                          style: context.typography.displayXs.bold.copyWith(
                            color: context.grey.c900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: Dimensions.space16),
                        Text(
                          slide.description,
                          textAlign: TextAlign.center,
                          style: context.typography.textMd.regular.copyWith(
                            color: context.grey.c500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color:
                        _currentPage == index
                            ? context.primary.c500
                            : context.grey.c300,
                    borderRadius: BorderRadius.circular(Dimensions.radiusFull),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Dimensions.space40),
            // Action buttons
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.space24,
                vertical: Dimensions.space32,
              ),
              child: Row(
                children: [
                  if (_currentPage > 0) ...[
                    Expanded(
                      child: SecondaryButton(
                        label: 'Back',
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: Dimensions.space16),
                  ],
                  Expanded(
                    child: PrimaryButton(
                      label:
                          _currentPage == _slides.length - 1
                              ? 'Get Started'
                              : 'Next',
                      onPressed: _nextPage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingSlideData {
  final String Function(BuildContext) titleKey;
  final String description;
  final String imagePath;
  final Color Function(BuildContext) colorBuilder;

  OnboardingSlideData({
    required this.titleKey,
    required this.description,
    required this.imagePath,
    required this.colorBuilder,
  });
}
