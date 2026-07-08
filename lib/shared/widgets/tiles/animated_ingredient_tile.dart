import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/haptic_service.dart';

/// An animated ingredient tile with:
/// • Scale + fade entry animation (for staggered list)
/// • Checkbox scale bounce on check
/// • Animated color change on container border
/// • Animated text strike-through via color crossfade
/// • Haptic feedback on check/uncheck
class AnimatedIngredientTile extends StatefulWidget {
  final String ingredient;
  final bool isChecked;
  final VoidCallback onToggle;
  /// Stagger delay before the entry animation plays (e.g. index * 70ms)
  final Duration entryDelay;

  const AnimatedIngredientTile({
    required this.ingredient,
    required this.isChecked,
    required this.onToggle,
    this.entryDelay = Duration.zero,
    super.key,
  });

  @override
  State<AnimatedIngredientTile> createState() =>
      _AnimatedIngredientTileState();
}

class _AnimatedIngredientTileState extends State<AnimatedIngredientTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _entryOpacity;
  late Animation<Offset> _entrySlide;

  bool _hasEntryPlayed = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _entryOpacity = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasEntryPlayed) {
      _hasEntryPlayed = true;
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!disableAnimations) {
        Future.delayed(widget.entryDelay, () {
          if (mounted) _entryController.forward();
        });
      } else {
        _entryController.value = 1.0;
      }
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticService.light();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _entryOpacity,
      child: SlideTransition(
        position: _entrySlide,
        child: GestureDetector(
          onTap: _handleTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.isChecked
                    ? const Color(0xFFF47B20).withValues(alpha: 0.3)
                    : const Color(0xFFEFEBE4),
                width: 1.0,
              ),
            ),
            child: Row(
              children: [
                // ── Animated Checkbox ────────────────────────────────────────
                _AnimatedCheckbox(isChecked: widget.isChecked),
                const SizedBox(width: 12),
                // ── Ingredient Name ──────────────────────────────────────────
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOutCubic,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.isChecked
                          ? const Color(0xFFB5B3B0)
                          : const Color(0xFF1F1E1C),
                      decoration: widget.isChecked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                    child: Text(widget.ingredient),
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

/// Internal animated checkbox with a spring-scale bounce on check.
class _AnimatedCheckbox extends StatefulWidget {
  final bool isChecked;
  const _AnimatedCheckbox({required this.isChecked});

  @override
  State<_AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<_AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceScale;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _bounceScale = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.3)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 1.3, end: 0.9)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
      TweenSequenceItem(
          tween: Tween(begin: 0.9, end: 1.0)
              .chain(CurveTween(curve: Curves.elasticOut)),
          weight: 30),
    ]).animate(_bounceController);
  }

  @override
  void didUpdateWidget(_AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isChecked != oldWidget.isChecked) {
      _bounceController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _bounceScale,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(6),
          color: widget.isChecked
              ? const Color(0xFFF47B20)
              : Colors.transparent,
          border: Border.all(
            color: widget.isChecked
                ? const Color(0xFFF47B20)
                : const Color(0xFFB5B3B0),
            width: 1.5,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: widget.isChecked
              ? const Icon(
                  Icons.check_rounded,
                  key: ValueKey(true),
                  color: Colors.white,
                  size: 14,
                )
              : const SizedBox.shrink(key: ValueKey(false)),
        ),
      ),
    );
  }
}
