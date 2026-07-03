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
  final String section; // 'main', 'terms', 'privacy', 'about'
  const SelectSubSection(this.section);

  @override
  List<Object?> get props => [section];
}
