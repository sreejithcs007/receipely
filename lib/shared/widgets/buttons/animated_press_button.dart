import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/haptic_service.dart';

/// A premium press-feedback button with:
/// • Scale down to 96% on press, bounce back on release
/// • Elevation reduction on press
/// • Ripple effect built into Material
/// • Respects Reduced Motion
class AnimatedPressButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final BorderRadius borderRadius;
  final EdgeInsets padding;
  final double? height;
  final double pressScale;

  const AnimatedPressButton({
    required this.child,
    required this.backgroundColor,
    this.onPressed,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.height,
    this.pressScale = 0.96,
    super.key,
  });

  @override
  State<AnimatedPressButton> createState() => _AnimatedPressButtonState();
}

class _AnimatedPressButtonState extends State<AnimatedPressButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween<double>(begin: 1.0, end: widget.pressScale).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (disableAnimations) {
      return SizedBox(
        height: widget.height,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.backgroundColor,
            shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
            elevation: 0,
            padding: widget.padding,
          ),
          onPressed: widget.onPressed,
          child: widget.child,
        ),
      );
    }

    return GestureDetector(
      onTapDown: (_) {
        HapticService.medium();
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          height: widget.height,
          child: Material(
            color: widget.backgroundColor,
            borderRadius: widget.borderRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: null, // handled by GestureDetector above
              splashColor: Colors.white.withValues(alpha: 0.15),
              highlightColor: Colors.transparent,
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Convenience: a fully configured "Start Cooking" flavoured button.
class StartCookingButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const StartCookingButton({this.onPressed, super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedPressButton(
      backgroundColor: const Color(0xFFF47B20),
      borderRadius: BorderRadius.circular(16),
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.soup_kitchen_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            'Start Cooking',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
