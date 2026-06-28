import 'package:flutter/material.dart';
import '../../../../router/routes.dart';
import '../../../../shared/core/constants/asset_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Per-slide theme data
// ─────────────────────────────────────────────────────────────────────────────
class _SlideTheme {
  final Color bg;
  final Color textTitle;
  final Color btnBg;
  final Color btnText;
  final Color dotActive;
  final Color dotInactive;

  const _SlideTheme({
    required this.bg,
    required this.textTitle,
    required this.btnBg,
    required this.btnText,
    required this.dotActive,
    required this.dotInactive,
  });
}

const _slide1 = _SlideTheme(
  // Screenshot 02 – cream/warm white
  bg: Color(0xFFFAF3E8),
  textTitle: Color(0xFF1E1208),
  btnBg: Color(0xFFF47B20),
  btnText: Color(0xFFFFFFFF),
  dotActive: Color(0xFFF47B20),
  dotInactive: Color(0xFFDDC9A8),
);

const _slide2 = _SlideTheme(
  // Screenshot 03 – sage green tint
  bg: Color(0xFFF0F5EC),
  textTitle: Color(0xFF1B4332),
  btnBg: Color(0xFF1B4332),
  btnText: Color(0xFFFFFFFF),
  dotActive: Color(0xFF1B4332),
  dotInactive: Color(0xFFBED4B8),
);

const _slide3 = _SlideTheme(
  // Screenshot 04 – warm pink/blush
  bg: Color(0xFFFBEFE8),
  textTitle: Color(0xFF1E1208),
  btnBg: Color(0xFFD63838),
  btnText: Color(0xFFFFFFFF),
  dotActive: Color(0xFFD63838),
  dotInactive: Color(0xFFEDC5B5),
);

// ─────────────────────────────────────────────────────────────────────────────
// Slide model
// ─────────────────────────────────────────────────────────────────────────────
class _SlideData {
  final String title;
  final String subtitle;
  final String imagePath;
  final String buttonLabel;
  final _SlideTheme theme;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.buttonLabel,
    required this.theme,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _bgController;
  int _currentPage = 0;

  static const _slides = [
    _SlideData(
      title: 'Discover\nDelicious Recipes',
      subtitle:
          'Explore a world of tasty recipes\nand cook your favorites with ease.',
      imagePath: AppImages.onboardingDiscover,
      buttonLabel: 'Next',
      theme: _slide1,
    ),
    _SlideData(
      title: 'Smart AI\nRecommendations',
      subtitle: 'Get personalized recipe ideas\nyou\'ll love, every time.',
      imagePath: AppImages.onboardingAi,
      buttonLabel: 'Next',
      theme: _slide2,
    ),
    _SlideData(
      title: 'Save Favorites\n& Plan Meals',
      subtitle: 'Bookmark recipes you love and\nplan your meals with ease.',
      imagePath: AppImages.onboardingPlan,
      buttonLabel: 'Get Started',
      theme: _slide3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) => setState(() => _currentPage = page);

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      const LoginRoute().go(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = _slides[_currentPage].theme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      color: theme.bg,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // ── Skip button ──────────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 20, top: 8),
                  child: TextButton(
                    onPressed: () => const LoginRoute().go(context),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: theme.textTitle.withValues(alpha: 0.45),
                        // fontSize: 15,
                        // fontWeight: FontWeight.w500,
                        fontFamily: 'PlusJakartaSans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        // color: Color(0xFF8A8A8A),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Page content ─────────────────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, i) => _SlidePage(slide: _slides[i]),
                ),
              ),

              // ── Dots ─────────────────────────────────────────────────
              _DotsIndicator(
                count: _slides.length,
                current: _currentPage,
                activeColor: theme.dotActive,
                inactiveColor: theme.dotInactive,
              ),
              const SizedBox(height: 28),

              // ── CTA button ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _OnboardingButton(
                  label: _slides[_currentPage].buttonLabel,
                  isLast: _currentPage == _slides.length - 1,
                  bgColor: theme.btnBg,
                  textColor: theme.btnText,
                  onPressed: _next,
                ),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual slide page
// ─────────────────────────────────────────────────────────────────────────────
class _SlidePage extends StatelessWidget {
  final _SlideData slide;
  const _SlidePage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),

          // Illustration area – fills most of the card
          Expanded(
            flex: 6,
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: slide.theme.textTitle.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(32),
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.asset(
                slide.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Center(
                  child: Icon(
                    Icons.restaurant_menu,
                    size: 96,
                    color: slide.theme.textTitle.withValues(alpha: 0.2),
                  ),
                ),
              ),
            ),
          ),

          // Text block
          Expanded(
            flex: 4,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // fontSize: 30,
                    // fontWeight: FontWeight.w800,
                    // color: slide.theme.textTitle,
                    // height: 1.20,
                    // letterSpacing: -0.3,
                    // fontStyle:
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                    color: slide.theme.textTitle,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    // fontSize: 14.5,
                    // fontWeight: FontWeight.w400,
                    // color: slide.theme.textTitle.withValues(alpha: 0.55),
                    // height: 1.55,
                    fontFamily: 'PlusJakartaSans',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    // color: Color(0xFF7B7B7B),
                    color: slide.theme.textTitle.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dot indicator
// ─────────────────────────────────────────────────────────────────────────────
class _DotsIndicator extends StatelessWidget {
  final int count, current;
  final Color activeColor, inactiveColor;
  const _DotsIndicator({
    required this.count,
    required this.current,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? activeColor : inactiveColor,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA button
// ─────────────────────────────────────────────────────────────────────────────
class _OnboardingButton extends StatelessWidget {
  final String label;
  final bool isLast;
  final Color bgColor, textColor;
  final VoidCallback onPressed;
  const _OnboardingButton({
    required this.label,
    required this.isLast,
    required this.bgColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
            if (isLast) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}
