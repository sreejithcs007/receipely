import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../shared/data/repositories/recipe_repository.dart';
import '../../../../shared/data/repositories/user_repository.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  // ignore: unused_field
  final RecipeRepository _recipeRepository;
  final UserRepository _userRepository;

  ProfileBloc(this._recipeRepository, this._userRepository)
      : super(const ProfileState(
          name: 'Sarah Johnson',
          level: 'Home Chef',
          imageUrl: '',
          savedCount: 0,
          cookedCount: 0,
          isLoading: false,
          showHelpBottomSheet: false,
        )) {
    on<LoadProfilePage>(_onLoadProfilePage);
    on<UpdateAvatar>(_onUpdateAvatar);
    on<TriggerHelpCenter>(_onTriggerHelpCenter);
  }

  Future<void> _onLoadProfilePage(LoadProfilePage event, Emitter<ProfileState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final user = _userRepository.getCurrentUser();
      if (user != null) {
        final profile = await _userRepository.getUserProfile(user.id);
        final favorites = await _userRepository.getFavorites(user.id);
        final cooked = await _userRepository.getCookedRecipes(user.id);

        emit(state.copyWith(
          name: profile.name,
          level: profile.chefLevel,
          imageUrl: profile.avatarUrl,
          savedCount: favorites.length,
          cookedCount: cooked.length,
          isLoading: false,
          showHelpBottomSheet: false,
        ));
      } else {
        emit(state.copyWith(isLoading: false));
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> _onUpdateAvatar(UpdateAvatar event, Emitter<ProfileState> emit) async {
    final user = _userRepository.getCurrentUser();
    if (user != null) {
      try {
        final updatedUrl = await _userRepository.updateUserAvatar(user.id, event.path);
        if (updatedUrl != null) {
          emit(state.copyWith(imageUrl: updatedUrl));
        }
      } catch (_) {}
    }
  }

  void _onTriggerHelpCenter(TriggerHelpCenter event, Emitter<ProfileState> emit) {
    emit(state.copyWith(showHelpBottomSheet: true));
    emit(state.copyWith(showHelpBottomSheet: false));
  }
}
