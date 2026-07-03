import 'package:equatable/equatable.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {}

class TogglePushNotifications extends SettingsEvent {}

class ToggleEmailNewsletters extends SettingsEvent {}

class UpdateThemeMode extends SettingsEvent {
  final String theme;
  const UpdateThemeMode(this.theme);

  @override
  List<Object?> get props => [theme];
}

class SelectSubSection extends SettingsEvent {
  final String section; // 'main', 'terms', 'privacy', 'about', 'profile_details', 'email_address'
  const SelectSubSection(this.section);

  @override
  List<Object?> get props => [section];
}

class UpdateProfile extends SettingsEvent {
  final String name;
  final String title;
  const UpdateProfile({required this.name, required this.title});

  @override
  List<Object?> get props => [name, title];
}

class UpdateEmail extends SettingsEvent {
  final String email;
  const UpdateEmail(this.email);

  @override
  List<Object?> get props => [email];
}
