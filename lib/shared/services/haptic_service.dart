import 'package:flutter/services.dart';


/// A centralized service for triggering platform-compliant haptic feedback.
/// All micro-interactions should go through this service so that haptics
/// can be disabled globally or swapped for accessibility.
abstract class HapticService {
  /// Light tap – use on toggles, checkboxes, selections.
  static void light() {
    HapticFeedback.lightImpact();
  }

  /// Medium impact – use on primary button presses.
  static void medium() {
    HapticFeedback.mediumImpact();
  }

  /// Heavy impact – use on pull-to-refresh threshold reached.
  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  /// Selection click – use on tab switches, filter selections.
  static void selection() {
    HapticFeedback.selectionClick();
  }
}
