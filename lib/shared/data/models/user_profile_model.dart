import 'package:equatable/equatable.dart';

class UserProfileModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String avatarUrl;
  final String chefLevel;
  final int savedCount;
  final int cookedCount;

  const UserProfileModel({
    required this.id,
    required this.email,
    required this.name,
    required this.avatarUrl,
    required this.chefLevel,
    required this.savedCount,
    required this.cookedCount,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String? ?? 'Sarah Johnson',
      avatarUrl: json['avatar_url'] as String? ?? '',
      chefLevel: json['chef_level'] as String? ?? 'Home Chef Level 4',
      savedCount: json['saved_count'] as int? ?? 124,
      cookedCount: json['cooked_count'] as int? ?? 89,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar_url': avatarUrl,
      'chef_level': chefLevel,
      'saved_count': savedCount,
      'cooked_count': cookedCount,
    };
  }

  @override
  List<Object?> get props => [id, email, name, avatarUrl, chefLevel, savedCount, cookedCount];
}
