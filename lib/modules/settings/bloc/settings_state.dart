import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool pushNotifications;
  final bool emailNewsletters;
  final String activeTheme;
  final String activeSubSection;

  const SettingsState({
    required this.pushNotifications,
    required this.emailNewsletters,
    required this.activeTheme,
    required this.activeSubSection,
  });

  SettingsState copyWith({
    bool? pushNotifications,
    bool? emailNewsletters,
    String? activeTheme,
    String? activeSubSection,
  }) {
    return SettingsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNewsletters: emailNewsletters ?? this.emailNewsletters,
      activeTheme: activeTheme ?? this.activeTheme,
      activeSubSection: activeSubSection ?? this.activeSubSection,
    );
  }

  @override
  List<Object?> get props => [
        pushNotifications,
        emailNewsletters,
        activeTheme,
        activeSubSection,
      ];
}
