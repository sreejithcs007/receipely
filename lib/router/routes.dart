import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../shared/services/haptic_service.dart';
import '../modules/splash/ui/screens/splash_screen.dart';
import '../modules/onboarding/ui/screens/onboarding_screen.dart';
import '../modules/auth/ui/screens/login_screen.dart';
import '../modules/auth/ui/screens/sign_up_screen.dart';
import '../modules/home/ui/screens/home_screen.dart';
import '../modules/recipe_detail/ui/screens/recipe_detail_screen.dart';
import '../modules/search/ui/screens/search_screen.dart';
import '../modules/categories/ui/screens/categories_screen.dart';
import '../modules/favorites/ui/screens/favorites_screen.dart';
import '../modules/meal_planner/ui/screens/meal_planner_screen.dart';
import '../modules/shopping_list/ui/screens/shopping_list_screen.dart';
import '../modules/ai_generator/ui/screens/ai_generator_screen.dart';
import '../modules/profile/ui/screens/profile_screen.dart';
import '../modules/settings/ui/screens/settings_screen.dart';

part 'routes.g.dart';

@TypedGoRoute<SplashRoute>(path: '/')
class SplashRoute extends GoRouteData {
  const SplashRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeThrough(state, const SplashScreen());
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData {
  const OnboardingRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeThrough(state, const OnboardingScreen());
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeThrough(state, const LoginScreen());
}

@TypedGoRoute<SignUpRoute>(path: '/signup')
class SignUpRoute extends GoRouteData {
  const SignUpRoute();
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _fadeThrough(state, const SignUpScreen());
}

@TypedShellRoute<MainShellRouteData>(
  routes: [
    TypedGoRoute<HomeRoute>(path: '/home'),
    TypedGoRoute<SearchRoute>(path: '/search'),
    TypedGoRoute<MealPlannerRoute>(path: '/meal-planner'),
    TypedGoRoute<FavoritesRoute>(path: '/favorites'),
    TypedGoRoute<ProfileRoute>(path: '/profile'),
  ],
)
class MainShellRouteData extends ShellRouteData {
  const MainShellRouteData();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) {
    return MainLayout(child: navigator);
  }
}

class HomeRoute extends GoRouteData {
  const HomeRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomeScreen();
}

class SearchRoute extends GoRouteData {
  final String? q;
  final String? category;
  const SearchRoute({this.q, this.category});
  @override
  Widget build(BuildContext context, GoRouterState state) => SearchScreen(query: q, category: category);
}

class MealPlannerRoute extends GoRouteData {
  const MealPlannerRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const MealPlannerScreen();
}

class FavoritesRoute extends GoRouteData {
  const FavoritesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const FavoritesScreen();
}

class ProfileRoute extends GoRouteData {
  const ProfileRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const ProfileScreen();
}

@TypedGoRoute<RecipeDetailRoute>(path: '/recipe/:recipeId')
class RecipeDetailRoute extends GoRouteData {
  final String recipeId;
  const RecipeDetailRoute({required this.recipeId});
  @override
  Page<void> buildPage(BuildContext context, GoRouterState state) =>
      _slideUp(state, RecipeDetailScreen(recipeId: recipeId));
}

@TypedGoRoute<CategoriesRoute>(path: '/categories')
class CategoriesRoute extends GoRouteData {
  const CategoriesRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const CategoriesScreen();
}

@TypedGoRoute<CategoryDetailRoute>(path: '/category/:categoryId')
class CategoryDetailRoute extends GoRouteData {
  final String categoryId;
  const CategoryDetailRoute({required this.categoryId});
  @override
  Widget build(BuildContext context, GoRouterState state) => PlaceholderScreen(title: 'Category Detail ($categoryId)');
}

@TypedGoRoute<ShoppingListRoute>(path: '/shopping-list')
class ShoppingListRoute extends GoRouteData {
  const ShoppingListRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const ShoppingListScreen();
}

@TypedGoRoute<AiGeneratorRoute>(path: '/ai-generator')
class AiGeneratorRoute extends GoRouteData {
  const AiGeneratorRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const AiGeneratorScreen();
}

@TypedGoRoute<SettingsRoute>(path: '/settings')
class SettingsRoute extends GoRouteData {
  const SettingsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SettingsScreen();
}

@TypedGoRoute<NotificationsRoute>(path: '/notifications')
class NotificationsRoute extends GoRouteData {
  const NotificationsRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PlaceholderScreen(title: 'Notifications');
}

// ── App Transition Builder ─────────────────────────────────────────────────

/// Returns a [CustomTransitionPage] implementing a Material 3 Fade Through
/// transition (opacity 0→1 combined with a slight scale 0.93→1.0).
/// Falls back to an instant transition if the system has Reduce Motion enabled.
CustomTransitionPage<T> _fadeThrough<T>(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 300),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Respect system Reduce Motion accessibility setting
      if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
        return child;
      }
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        ),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.93, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      );
    },
  );
}

/// Returns a [CustomTransitionPage] with a shared-axis slide+fade transition
/// used for navigating into detail screens (recipe, category).
CustomTransitionPage<T> _slideUp<T>(
  GoRouterState state,
  Widget child, {
  Duration duration = const Duration(milliseconds: 320),
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: duration,
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (MediaQuery.maybeOf(context)?.disableAnimations == true) {
        return child;
      }
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}


class BottomTabIcon extends StatefulWidget {
  final IconData icon;
  final IconData inactiveIcon;
  final bool isSelected;
  final Color color;

  const BottomTabIcon({
    required this.icon,
    required this.inactiveIcon,
    required this.isSelected,
    required this.color,
    super.key,
  });

  @override
  State<BottomTabIcon> createState() => _BottomTabIconState();
}

class _BottomTabIconState extends State<BottomTabIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.18)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.18, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 60,
      ),
    ]).animate(_controller);

    if (widget.isSelected) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant BottomTabIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward(from: 0.0);
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations == true;
    if (disableAnimations) {
      return Icon(
        widget.isSelected ? widget.icon : widget.inactiveIcon,
        color: widget.color,
        size: 24,
      );
    }

    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isSelected ? _scale.value : 1.0,
          child: child,
        );
      },
      child: Icon(
        widget.isSelected ? widget.icon : widget.inactiveIcon,
        color: widget.color,
        size: 24,
      ),
    );
  }
}

// ── Placeholder Layouts and Screens ───────────────────────────────────────


class MainLayout extends StatefulWidget {
  final Widget child;
  const MainLayout({required this.child, super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  DateTime? _lastPressedAt;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/meal-planner')) return 2;
    if (location.startsWith('/favorites')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  int _getSlotIndex(int index) {
    if (index == 1) return 1;
    if (index == 3) return 2;
    if (index == 4) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index, int currentIndex) {
    if (index == currentIndex) return;
    HapticService.selection();
    switch (index) {
      case 0:
        const HomeRoute().go(context);
        break;
      case 1:
        const SearchRoute().go(context);
        break;
      case 2:
        const MealPlannerRoute().go(context);
        break;
      case 3:
        const FavoritesRoute().go(context);
        break;
      case 4:
        const ProfileRoute().go(context);
        break;
    }
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
    required int currentIndex,
  }) {
    const activeColor = Color(0xFFF47B20);
    const inactiveColor = Color(0xFF8C8A87);
    final themeColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context, index, currentIndex),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            BottomTabIcon(
              icon: icon,
              inactiveIcon: inactiveIcon,
              isSelected: isSelected,
              color: themeColor,
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: isSelected ? 1.0 : 0.6,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: themeColor,
                ),
                child: Text(label),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // If not on Home screen/tab, navigate back to Home screen/tab first
        if (selectedIndex != 0) {
          const HomeRoute().go(context);
          return;
        }

        final now = DateTime.now();
        final backButtonHasNotBeenPressedOrTimeHasExpired =
            _lastPressedAt == null || now.difference(_lastPressedAt!) > const Duration(seconds: 2);

        if (backButtonHasNotBeenPressedOrTimeHasExpired) {
          _lastPressedAt = now;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Swipe back again to exit',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF1F1E1C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          return;
        }

        // Close the app
        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAF7F2),
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final totalWidth = constraints.maxWidth;
                final itemWidth = totalWidth / 4;
                const indicatorWidth = 24.0;
                final slotIndex = _getSlotIndex(selectedIndex);

                // Position indicator in the center of the active item slot
                final leftPosition =
                    slotIndex * itemWidth + (itemWidth - indicatorWidth) / 2;

                return SizedBox(
                  height: 58,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Gliding Indicator Line under the selected item
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOutCubic,
                        left: leftPosition,
                        bottom: 2,
                        child: Container(
                          width: indicatorWidth,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF47B20),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // Navigation Row
                      Positioned.fill(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildNavItem(
                              context,
                              index: 0,
                              icon: Icons.home_filled,
                              inactiveIcon: Icons.home_outlined,
                              label: 'Home',
                              isSelected: selectedIndex == 0,
                              currentIndex: selectedIndex,
                            ),
                            _buildNavItem(
                              context,
                              index: 1,
                              icon: Icons.search,
                              inactiveIcon: Icons.search,
                              label: 'Search',
                              isSelected: selectedIndex == 1,
                              currentIndex: selectedIndex,
                            ),
                            _buildNavItem(
                              context,
                              index: 3,
                              icon: Icons.favorite,
                              inactiveIcon: Icons.favorite_border,
                              label: 'Favorites',
                              isSelected: selectedIndex == 3,
                              currentIndex: selectedIndex,
                            ),
                            _buildNavItem(
                              context,
                              index: 4,
                              icon: Icons.person,
                              inactiveIcon: Icons.person_outline,
                              label: 'Profile',
                              isSelected: selectedIndex == 4,
                              currentIndex: selectedIndex,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen({required this.title, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Recipely - $title Screen',
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  const OnboardingRoute().go(context);
                },
                child: const Text('Go to Onboarding'),
              ),
              ElevatedButton(
                onPressed: () {
                  const LoginRoute().go(context);
                },
                child: const Text('Go to Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  const HomeRoute().go(context);
                },
                child: const Text('Go to Home Shell'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
