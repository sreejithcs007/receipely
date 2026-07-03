import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final UserRepository _userRepository;

  SettingsBloc(this._userRepository)
      : super(const SettingsState(
          pushNotifications: true,
          emailNewsletters: false,
          activeTheme: 'system',
          activeSubSection: 'main',
          name: 'Sarah Johnson',
          title: 'Home Chef',
          email: 'sarah.j@recipely.com',
        )) {
    on<LoadSettings>(_onLoadSettings);
    on<TogglePushNotifications>(_onTogglePushNotifications);
    on<ToggleEmailNewsletters>(_onToggleEmailNewsletters);
    on<UpdateThemeMode>(_onUpdateThemeMode);
    on<SelectSubSection>(_onSelectSubSection);
    on<UpdateProfile>(_onUpdateProfile);
    on<UpdateEmail>(_onUpdateEmail);
  }

  Future<void> _onLoadSettings(LoadSettings event, Emitter<SettingsState> emit) async {
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.id);
        final prefs = await _userRepository.getUserPreferences(user.id);

        emit(state.copyWith(
          pushNotifications: prefs['push_notifications'] as bool? ?? true,
          emailNewsletters: prefs['email_newsletters'] as bool? ?? false,
          activeTheme: prefs['active_theme'] as String? ?? 'system',
          name: profile.name,
          title: profile.chefLevel,
          email: profile.email,
          activeSubSection: 'main',
        ));
      }
    } catch (_) {}
  }

  Future<void> _onTogglePushNotifications(TogglePushNotifications event, Emitter<SettingsState> emit) async {
    final nextState = !state.pushNotifications;
    emit(state.copyWith(pushNotifications: nextState));

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.updateUserPreferences(
          user.id,
          pushNotifications: nextState,
          emailNewsletters: state.emailNewsletters,
          activeTheme: state.activeTheme,
        );
      } catch (_) {}
    }
  }

  Future<void> _onToggleEmailNewsletters(ToggleEmailNewsletters event, Emitter<SettingsState> emit) async {
    final nextState = !state.emailNewsletters;
    emit(state.copyWith(emailNewsletters: nextState));

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.updateUserPreferences(
          user.id,
          pushNotifications: state.pushNotifications,
          emailNewsletters: nextState,
          activeTheme: state.activeTheme,
        );
      } catch (_) {}
    }
  }

  Future<void> _onUpdateThemeMode(UpdateThemeMode event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(activeTheme: event.theme));

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.updateUserPreferences(
          user.id,
          pushNotifications: state.pushNotifications,
          emailNewsletters: state.emailNewsletters,
          activeTheme: event.theme,
        );
      } catch (_) {}
    }
  }

  void _onSelectSubSection(SelectSubSection event, Emitter<SettingsState> emit) {
    emit(state.copyWith(activeSubSection: event.section));
  }

  Future<void> _onUpdateProfile(UpdateProfile event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
      name: event.name,
      title: event.title,
      activeSubSection: 'main',
    ));

    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        await _userRepository.updateUserProfile(user.id, name: event.name, title: event.title);
      } catch (_) {}
    }
  }

  void _onUpdateEmail(UpdateEmail event, Emitter<SettingsState> emit) {
    emit(state.copyWith(
      email: event.email,
      activeSubSection: 'main',
    ));
    // Auth updates can be handled through Supabase auth update
  }
}
