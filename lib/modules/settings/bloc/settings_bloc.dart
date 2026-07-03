import 'package:flutter_bloc/flutter_bloc.dart';
import 'settings_event.dart';
import 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc()
      : super(const SettingsState(
          pushNotifications: true,
          emailNewsletters: false,
          activeTheme: 'system',
          activeSubSection: 'main',
        )) {
    on<LoadSettings>((event, emit) {
      emit(state.copyWith(activeSubSection: 'main'));
    });
    on<TogglePushNotifications>((event, emit) {
      emit(state.copyWith(pushNotifications: !state.pushNotifications));
    });
    on<ToggleEmailNewsletters>((event, emit) {
      emit(state.copyWith(emailNewsletters: !state.emailNewsletters));
    });
    on<UpdateThemeMode>((event, emit) {
      emit(state.copyWith(activeTheme: event.theme));
    });
    on<SelectSubSection>((event, emit) {
      emit(state.copyWith(activeSubSection: event.section));
    });
  }
}
