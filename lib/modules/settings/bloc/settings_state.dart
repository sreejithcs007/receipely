import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool pushNotifications;
  final bool emailNewsletters;
  final String activeTheme;
  final String activeSubSection;
  final String name;
  final String title;
  final String email;

  const SettingsState({
    required this.pushNotifications,
    required this.emailNewsletters,
    required this.activeTheme,
    required this.activeSubSection,
    required this.name,
    required this.title,
    required this.email,
  });

  SettingsState copyWith({
    bool? pushNotifications,
    bool? emailNewsletters,
    String? activeTheme,
    String? activeSubSection,
    String? name,
    String? title,
    String? email,
  }) {
    return SettingsState(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNewsletters: emailNewsletters ?? this.emailNewsletters,
      activeTheme: activeTheme ?? this.activeTheme,
      activeSubSection: activeSubSection ?? this.activeSubSection,
      name: name ?? this.name,
      title: title ?? this.title,
      email: email ?? this.email,
    );
  }

  @override
  List<Object?> get props => [
        pushNotifications,
        emailNewsletters,
        activeTheme,
        activeSubSection,
        name,
        title,
        email,
      ];
}
