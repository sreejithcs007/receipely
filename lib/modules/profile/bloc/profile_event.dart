import 'package:equatable/equatable.dart';

abstract class ProfileEvent extends Equatable {
  const ProfileEvent();

  @override
  List<Object?> get props => [];
}

class LoadProfilePage extends ProfileEvent {}

class UpdateAvatar extends ProfileEvent {
  final String path;
  const UpdateAvatar(this.path);

  @override
  List<Object?> get props => [path];
}

class TriggerHelpCenter extends ProfileEvent {}
