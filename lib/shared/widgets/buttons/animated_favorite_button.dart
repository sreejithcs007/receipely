import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';

/// A premium animated favorite/bookmark button with:
/// • Scale bounce: 1.0 → 1.25 → 1.0 with spring overshoot
/// • Icon morphs between filled and outlined
/// • Color animates from grey to brand orange
/// • Haptic feedback on toggle
class AnimatedFavoriteButton extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onToggle;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  final bool useBookmarkIcon;

  const AnimatedFavoriteButton({
    required this.isFavorite,
    required this.onToggle,
    this.size = 20.0,
    this.activeColor = const Color(0xFFF47B20),
    this.inactiveColor = const Color(0xFF8C8A87),
    this.useBookmarkIcon = false,
    super.key,
  });

  @override
  State<AnimatedFavoriteButton> createState() => _AnimatedFavoriteButtonState();
}

class _AnimatedFavoriteButtonState extends State<AnimatedFavoriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // Bounce: 1.0 → 1.25 → 0.92 → 1.0 using a custom spring-like curve
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.25)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.25, end: 0.92)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 35,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticService.light();
    widget.onToggle();
    _controller.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    // Respect Reduce Motion
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final activeIcon =
        widget.useBookmarkIcon ? Icons.bookmark_rounded : Icons.favorite_rounded;
    final inactiveIcon = widget.useBookmarkIcon
        ? Icons.bookmark_border_rounded
        : Icons.favorite_border_rounded;

    if (disableAnimations) {
      return GestureDetector(
        onTap: _handleTap,
        child: Icon(
          widget.isFavorite ? activeIcon : inactiveIcon,
          color: widget.isFavorite ? widget.activeColor : widget.inactiveColor,
          size: widget.size,
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation,
              child: child,
            ),
          ),
          child: Icon(
            widget.isFavorite ? activeIcon : inactiveIcon,
            key: ValueKey<bool>(widget.isFavorite),
            color: widget.isFavorite ? widget.activeColor : widget.inactiveColor,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}
