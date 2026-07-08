import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/haptic_service.dart';

/// An animated segmented tab switcher with:
/// • Sliding white indicator background animated with AnimatedPositioned
/// • Fade transition on tab content change (handled by consumer via AnimatedSwitcher)
/// • Haptic selection feedback on switch
/// • Respects Reduce Motion preference
class AnimatedTabBar extends StatelessWidget {
  final int selectedIndex;
  final List<String> labels;
  final ValueChanged<int> onTabChanged;

  const AnimatedTabBar({
    required this.selectedIndex,
    required this.labels,
    required this.onTabChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabWidth = totalWidth / labels.length;

        return Container(
          height: 48,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F3EE),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            children: [
              // ── Animated sliding indicator ────────────────────────────────
              if (!disableAnimations)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOutCubic,
                  left: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Positioned(
                  left: selectedIndex * tabWidth,
                  top: 0,
                  bottom: 0,
                  width: tabWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),

              // ── Tab labels (on top of indicator) ─────────────────────────
              Row(
                children: List.generate(labels.length, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (index != selectedIndex) {
                          HapticService.selection();
                          onTabChanged(index);
                        }
                      },
                      child: Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF1F1E1C)
                                : const Color(0xFF8C8A87),
                          ),
                          child: Text(labels[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }
}
