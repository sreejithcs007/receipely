import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
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
  Widget build(BuildContext context, GoRouterState state) => const SplashScreen();
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData {
  const OnboardingRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const OnboardingScreen();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginScreen();
}

@TypedGoRoute<SignUpRoute>(path: '/signup')
class SignUpRoute extends GoRouteData {
  const SignUpRoute();
  @override
  Widget build(BuildContext context, GoRouterState state) => const SignUpScreen();
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
  Widget build(BuildContext context, GoRouterState state) => RecipeDetailScreen(recipeId: recipeId);
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

// ── Placeholder Layouts and Screens ───────────────────────────────────────

class MainLayout extends StatelessWidget {
  final Widget child;
  const MainLayout({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2),
      body: child,
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                ),
                _buildNavItem(
                  context,
                  index: 1,
                  icon: Icons.search,
                  inactiveIcon: Icons.search,
                  label: 'Search',
                  isSelected: selectedIndex == 1,
                ),
                _buildCenterPlusButton(context),
                _buildNavItem(
                  context,
                  index: 3,
                  icon: Icons.favorite,
                  inactiveIcon: Icons.favorite_border,
                  label: 'Favorites',
                  isSelected: selectedIndex == 3,
                ),
                _buildNavItem(
                  context,
                  index: 4,
                  icon: Icons.person,
                  inactiveIcon: Icons.person_outline,
                  label: 'Profile',
                  isSelected: selectedIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required int index,
    required IconData icon,
    required IconData inactiveIcon,
    required String label,
    required bool isSelected,
  }) {
    final themeColor = isSelected ? const Color(0xFFF47B20) : const Color(0xFF8C8A87);
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context, index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? icon : inactiveIcon,
              color: themeColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: themeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterPlusButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(context, 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFF47B20),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x3DF47B20),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/search')) return 1;
    if (location.startsWith('/meal-planner')) return 2;
    if (location.startsWith('/favorites')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
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
