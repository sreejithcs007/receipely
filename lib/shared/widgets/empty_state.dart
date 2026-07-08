import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/haptic_service.dart';
import 'buttons/animated_press_button.dart';

enum EmptyStateType {
  favorites,
  search,
  offline,
  networkError,
  categories,
  noRecipes,
}

class EmptyState extends StatefulWidget {
  final EmptyStateType type;
  final VoidCallback? onPrimaryPressed;
  final VoidCallback? onSecondaryPressed;
  final String? primaryCtaLabel;
  final String? secondaryCtaLabel;

  const EmptyState({
    required this.type,
    this.onPrimaryPressed,
    this.onSecondaryPressed,
    this.primaryCtaLabel,
    this.secondaryCtaLabel,
    super.key,
  });

  factory EmptyState.favorites({VoidCallback? onBrowse}) {
    return EmptyState(
      type: EmptyStateType.favorites,
      onPrimaryPressed: onBrowse,
    );
  }

  factory EmptyState.search({VoidCallback? onBrowseAll}) {
    return EmptyState(
      type: EmptyStateType.search,
      onPrimaryPressed: onBrowseAll,
    );
  }

  factory EmptyState.offline({VoidCallback? onRetry}) {
    return EmptyState(
      type: EmptyStateType.offline,
      onPrimaryPressed: onRetry,
    );
  }

  factory EmptyState.networkError({VoidCallback? onRetry}) {
    return EmptyState(
      type: EmptyStateType.networkError,
      onPrimaryPressed: onRetry,
    );
  }

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState> {
  bool _showText = false;
  bool _showButton = false;

  @override
  void initState() {
    super.initState();
    // Staggered animation delays
    Timer(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _showText = true);
    });
    Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _showButton = true);
    });
  }

  IconData _getIcon() {
    switch (widget.type) {
      case EmptyStateType.favorites:
        return Icons.favorite_rounded;
      case EmptyStateType.search:
        return Icons.search_rounded;
      case EmptyStateType.offline:
        return Icons.wifi_off_rounded;
      case EmptyStateType.networkError:
        return Icons.error_outline_rounded;
      case EmptyStateType.categories:
        return Icons.restaurant_menu_rounded;
      case EmptyStateType.noRecipes:
        return Icons.no_meals_rounded;
    }
  }

  Color _getIconColor() {
    switch (widget.type) {
      case EmptyStateType.favorites:
      case EmptyStateType.networkError:
        return const Color(0xFFEA4335); // Alert / Accent Red
      case EmptyStateType.search:
      case EmptyStateType.categories:
        return const Color(0xFFF47B20); // Brand Orange
      case EmptyStateType.offline:
      case EmptyStateType.noRecipes:
        return const Color(0xFF8C8A87); // Warm Muted Gray
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case EmptyStateType.favorites:
        return 'No saved recipes yet';
      case EmptyStateType.search:
        return 'No recipes found';
      case EmptyStateType.offline:
        return "You're offline";
      case EmptyStateType.networkError:
        return 'Something went wrong';
      case EmptyStateType.categories:
        return 'No recipes in this category';
      case EmptyStateType.noRecipes:
        return 'No recipes found';
    }
  }

  String _getSubtitle() {
    switch (widget.type) {
      case EmptyStateType.favorites:
        return 'Save recipes to quickly find them later.';
      case EmptyStateType.search:
        return 'Try another ingredient or query.';
      case EmptyStateType.offline:
        return 'Showing cached recipes. Check your connection.';
      case EmptyStateType.networkError:
        return 'Please check your connection and try again.';
      case EmptyStateType.categories:
        return 'Explore other delicious categories on the home page.';
      case EmptyStateType.noRecipes:
        return 'Explore our collection of food items.';
    }
  }

  String _getPrimaryCta() {
    if (widget.primaryCtaLabel != null) return widget.primaryCtaLabel!;
    switch (widget.type) {
      case EmptyStateType.favorites:
        return 'Browse Recipes';
      case EmptyStateType.search:
      case EmptyStateType.categories:
      case EmptyStateType.noRecipes:
        return 'Browse All Recipes';
      case EmptyStateType.offline:
      case EmptyStateType.networkError:
        return 'Retry';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Respect Reduced Motion accessibility setting
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations == true;
    final showTextInstant = disableAnimations || _showText;
    final showButtonInstant = disableAnimations || _showButton;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ── Illustration (Fade & Slide Up) ───────────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, (1 - value) * 24),
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _getIconColor().withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _getIcon(),
                    size: 40,
                    color: _getIconColor(),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Title & Subtitle (Staggered Fade & Slide) ────────────────────
            AnimatedOpacity(
              opacity: showTextInstant ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: AnimatedSlide(
                offset: showTextInstant ? Offset.zero : const Offset(0, 0.05),
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    Text(
                      _getTitle(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1F1E1C),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getSubtitle(),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFF8C8A87),
                        fontWeight: FontWeight.w400,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── CTAs (Elastic Scale In) ──────────────────────────────────────
            AnimatedScale(
              scale: showButtonInstant ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onPrimaryPressed != null)
                    AnimatedPressButton(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        HapticService.selection();
                        widget.onPrimaryPressed?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF47B20),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF47B20).withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Text(
                          _getPrimaryCta(),
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  if (widget.onSecondaryPressed != null &&
                      widget.secondaryCtaLabel != null) ...[
                    const SizedBox(width: 12),
                    AnimatedPressButton(
                      backgroundColor: Colors.transparent,
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        HapticService.selection();
                        widget.onSecondaryPressed?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: const Color(0xFFEFEBE4), width: 1.5),
                        ),
                        child: Text(
                          widget.secondaryCtaLabel!,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1F1E1C),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
