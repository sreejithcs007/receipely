import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../utils/extension/context_extension.dart';

class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final String name;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    required this.name,
    this.imageUrl,
    this.radius = 24.0,
    this.onTap,
    super.key,
  });

  String get _initials {
    if (name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatarChild = Center(
      child: Text(
        _initials,
        style: context.typography.textMd.bold.copyWith(
          color: context.primary.c500,
          fontSize: radius * 0.8,
        ),
      ),
    );

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      avatarChild = CachedNetworkImage(
        imageUrl: imageUrl!,
        imageBuilder:
            (context, imageProvider) => Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        placeholder:
            (context, url) => Center(
              child: SizedBox(
                width: radius * 0.8,
                height: radius * 0.8,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    context.primary.c500,
                  ),
                ),
              ),
            ),
        errorWidget: (context, url, error) => avatarChild,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: context.primary.c50,
          border: Border.all(color: context.primary.c100, width: 1.5),
        ),
        child: ClipOval(child: avatarChild),
      ),
    );
  }
}
