import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/haptic_service.dart';

enum NotificationType { success, warning, error }

class OverlayNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  /// Shows a premium, top-sliding animated notification banner.
  /// Automatically dismisses after 3 seconds or on user drag.
  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
  }) {
    // Cancel previous notification if visible
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    // Trigger haptic feedback based on notification type
    switch (type) {
      case NotificationType.success:
        HapticService.light();
        break;
      case NotificationType.warning:
        HapticService.medium();
        break;
      case NotificationType.error:
        HapticService.heavy();
        break;
    }

    final overlayState = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (context) => _OverlayNotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    // Schedule auto-dismiss
    _dismissTimer = Timer(const Duration(milliseconds: 3200), () {
      if (_currentEntry == entry) {
        // Trigger exit animation on the state if active
        // The widget handles removing itself through the callback
      }
    });
  }
}

class _OverlayNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;

  const _OverlayNotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_OverlayNotificationWidget> createState() =>
      __OverlayNotificationWidgetState();
}

class __OverlayNotificationWidgetState extends State<_OverlayNotificationWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Start auto-dismiss sequence
    _autoDismissTimer = Timer(const Duration(milliseconds: 2800), () {
      _dismissWithAnimation();
    });
  }

  void _dismissWithAnimation() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Style settings based on notification type
    final IconData icon;
    final Color primaryColor;
    final Color backgroundColor;
    final Color borderColor;

    switch (widget.type) {
      case NotificationType.success:
        icon = Icons.check_circle_rounded;
        primaryColor = const Color(0xFF2E7D32);
        backgroundColor = const Color(0xFFEAF5E3);
        borderColor = const Color(0xFFC8E6C9);
        break;
      case NotificationType.warning:
        icon = Icons.warning_amber_rounded;
        primaryColor = const Color(0xFFE65100);
        backgroundColor = const Color(0xFFFFF3E0);
        borderColor = const Color(0xFFFFE0B2);
        break;
      case NotificationType.error:
        icon = Icons.error_outline_rounded;
        primaryColor = const Color(0xFFC62828);
        backgroundColor = const Color(0xFFFFEBEE);
        borderColor = const Color(0xFFFFCDD2);
        break;
    }

    final topPadding = MediaQuery.of(context).padding.top + 16;

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.only(top: topPadding, left: 20, right: 20),
          child: SlideTransition(
            position: _offsetAnimation,
            child: FadeTransition(
              opacity: _opacityAnimation,
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    if (details.primaryDelta! < -5) {
                      _dismissWithAnimation();
                    }
                  },
                  onTap: _dismissWithAnimation,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(icon, color: primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1F1E1C),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.drag_handle_rounded,
                          color: primaryColor.withValues(alpha: 0.4),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
