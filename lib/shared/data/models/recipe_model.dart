import 'package:equatable/equatable.dart';

class RecipeModel extends Equatable {
  final String id;
  final String title;
  final String description;
  final double rating;
  final int reviews;
  final String cookTime;
  final String calories;
  final String servings;
  final String imageUrl;
  final String difficulty;
  final bool isFeatured;
  final bool isTrending;

  const RecipeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.cookTime,
    required this.calories,
    required this.servings,
    required this.imageUrl,
    required this.difficulty,
    required this.isFeatured,
    required this.isTrending,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    return RecipeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (json['reviews'] ?? json['reviews_count'] ?? 0) as int,
      cookTime: (json['cook_time'] ?? json['total_time'] ?? '') as String,
      calories: json['calories'] as String,
      servings: json['servings'] as String,
      imageUrl: (json['image_url'] ??
              json['primary_image_url'] ??
              json['thumbnail_image_url'] ??
              json['thumbnail_url'] ??
              json['image'] ??
              '') as String,
      difficulty: json['difficulty'] as String,
      isFeatured: json['is_featured'] as bool? ?? false,
      isTrending: json['is_trending'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rating': rating,
      'reviews': reviews,
      'cook_time': cookTime,
      'calories': calories,
      'servings': servings,
      'image_url': imageUrl,
      'difficulty': difficulty,
      'is_featured': isFeatured,
      'is_trending': isTrending,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    rating,
    reviews,
    cookTime,
    calories,
    servings,
    imageUrl,
    difficulty,
    isFeatured,
    isTrending,
  ];
}
