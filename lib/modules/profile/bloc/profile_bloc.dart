import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/core/constants/asset_constants.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc()
      : super(const ProfileState(
          name: 'Sarah Johnson',
          level: 'Home Chef Level 4',
          imageUrl: AppImages.chefAvatar,
          savedCount: 124,
          cookedCount: 89,
          isLoading: false,
          showHelpBottomSheet: false,
        )) {
    on<LoadProfilePage>(_onLoadProfilePage);
    on<UpdateAvatar>(_onUpdateAvatar);
    on<TriggerHelpCenter>(_onTriggerHelpCenter);
  }

  void _onLoadProfilePage(LoadProfilePage event, Emitter<ProfileState> emit) {
    emit(state.copyWith(isLoading: false, showHelpBottomSheet: false));
  }

  void _onUpdateAvatar(UpdateAvatar event, Emitter<ProfileState> emit) {
    emit(state.copyWith(imageUrl: event.path));
  }

  void _onTriggerHelpCenter(TriggerHelpCenter event, Emitter<ProfileState> emit) {
    emit(state.copyWith(showHelpBottomSheet: true));
    emit(state.copyWith(showHelpBottomSheet: false));
  }
}
