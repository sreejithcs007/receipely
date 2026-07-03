import 'package:equatable/equatable.dart';

class ProfileState extends Equatable {
  final String name;
  final String level;
  final String imageUrl;
  final int savedCount;
  final int cookedCount;
  final bool isLoading;
  final bool showHelpBottomSheet;

  const ProfileState({
    required this.name,
    required this.level,
    required this.imageUrl,
    required this.savedCount,
    required this.cookedCount,
    required this.isLoading,
    required this.showHelpBottomSheet,
  });

  ProfileState copyWith({
    String? name,
    String? level,
    String? imageUrl,
    int? savedCount,
    int? cookedCount,
    bool? isLoading,
    bool? showHelpBottomSheet,
  }) {
    return ProfileState(
      name: name ?? this.name,
      level: level ?? this.level,
      imageUrl: imageUrl ?? this.imageUrl,
      savedCount: savedCount ?? this.savedCount,
      cookedCount: cookedCount ?? this.cookedCount,
      isLoading: isLoading ?? this.isLoading,
      showHelpBottomSheet: showHelpBottomSheet ?? this.showHelpBottomSheet,
    );
  }

  @override
  List<Object?> get props => [
        name,
        level,
        imageUrl,
        savedCount,
        cookedCount,
        isLoading,
        showHelpBottomSheet,
      ];
}
