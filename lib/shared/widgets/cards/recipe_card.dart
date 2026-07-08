import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';
import '../buttons/animated_favorite_button.dart';
import '../loader/shimmer_card.dart';

class RecipeCard extends StatefulWidget {
  final String title;
  final String imageUrl;
  final String rating;
  final String cookTime;
  final String calories;
  final bool isFavorite;
  final VoidCallback? onFavoriteToggled;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  /// Optional hero tag for image transition to detail screen.
  final String? heroTag;

  const RecipeCard({
    required this.title,
    required this.imageUrl,
    required this.rating,
    required this.cookTime,
    required this.calories,
    this.isFavorite = false,
    this.onFavoriteToggled,
    this.onTap,
    this.width,
    this.height = 240.0,
    this.heroTag,
    super.key,
  });

  @override
  State<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends State<RecipeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? 170.0,
          height: widget.height,
          decoration: BoxDecoration(
            color: context.white.c50,
            borderRadius: BorderRadius.circular(Dimensions.radiusLg),
            boxShadow: [
              BoxShadow(
                color: context.grey.c900.withValues(alpha: 0.04),
                blurRadius: 12.0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image Header with overlays
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(Dimensions.radiusLg),
                        ),
                        child: widget.imageUrl.startsWith('http')
                            ? Hero(
                                tag: widget.heroTag ?? widget.imageUrl,
                                flightShuttleBuilder: (_, anim, __, ___, ____) =>
                                    Material(
                                      color: Colors.transparent,
                                      child: ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(Dimensions.radiusLg),
                                        ),
                                        child: CachedNetworkImage(
                                          imageUrl: widget.imageUrl,
                                          memCacheWidth: 400,
                                          memCacheHeight: 400,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                child: CachedNetworkImage(
                                  imageUrl: widget.imageUrl,
                                  memCacheWidth: 400,
                                  memCacheHeight: 400,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => ShimmerCard(
                                    width: widget.width ?? 170.0,
                                    height: widget.height - 80.0,
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: context.grey.c200,
                                    child: Icon(
                                      Icons.restaurant_menu,
                                      color: context.grey.c400,
                                      size: 32.0,
                                    ),
                                  ),
                                ),
                              )
                            : Image.asset(
                                widget.imageUrl,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    // Rating Badge Top-Left
                    Positioned(
                      top: Dimensions.space8,
                      left: Dimensions.space8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Dimensions.space6,
                          vertical: Dimensions.space2,
                        ),
                        decoration: BoxDecoration(
                          color: context.white.c50.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(
                            Dimensions.radiusFull,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 14.0,
                            ),
                            const SizedBox(width: 2.0),
                            Text(
                              widget.rating,
                              style: context.typography.textXs.bold.copyWith(
                                color: context.grey.c900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Favorite Toggle Button Top-Right
                    Positioned(
                      top: Dimensions.space8,
                      right: Dimensions.space8,
                      child: Container(
                        padding: const EdgeInsets.all(Dimensions.space6),
                        decoration: BoxDecoration(
                          color: context.white.c50.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: AnimatedFavoriteButton(
                          isFavorite: widget.isFavorite,
                          useBookmarkIcon: false,
                          activeColor: const Color(0xFFEA4335),
                          size: 16.0,
                          onToggle: widget.onFavoriteToggled ?? () {},
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Meta details body
              Padding(
                padding: const EdgeInsets.all(Dimensions.space12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typography.textSm.semibold.copyWith(
                        color: context.grey.c900,
                      ),
                    ),
                    const SizedBox(height: Dimensions.space4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12.0,
                          color: context.grey.c500,
                        ),
                        const SizedBox(width: 2.0),
                        Text(
                          widget.cookTime,
                          style: context.typography.textXs.regular.copyWith(
                            color: context.grey.c500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.local_fire_department,
                          size: 12.0,
                          color: context.grey.c500,
                        ),
                        const SizedBox(width: 2.0),
                        Text(
                          widget.calories,
                          style: context.typography.textXs.regular.copyWith(
                            color: context.grey.c500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
