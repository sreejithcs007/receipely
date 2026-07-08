import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/dimensions.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Base shimmer colors — warm cream palette matching app canvas
// ─────────────────────────────────────────────────────────────────────────────
const _kBaseColor = Color(0xFFEFEBE4);
const _kHighlightColor = Color(0xFFFAF7F2);

/// A single shimmering placeholder box/circle.
/// Wraps [Shimmer.fromColors] from the `shimmer` package for a
/// smooth 1500ms diagonal wave — much more natural than a manual gradient.
class CustomShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;

  const CustomShimmer({
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kBaseColor,
      highlightColor: _kHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _kBaseColor,
          shape: shape,
          borderRadius: shape == BoxShape.circle
              ? null
              : (borderRadius ?? BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

/// A shimmer image placeholder — same dimensions as the image it replaces.
/// Use as `placeholder` in [CachedNetworkImage] instead of a spinner.
class ShimmerImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ShimmerImagePlaceholder({
    this.width,
    this.height,
    this.borderRadius,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kBaseColor,
      highlightColor: _kHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _kBaseColor,
          borderRadius: borderRadius ?? BorderRadius.circular(0),
        ),
      ),
    );
  }
}

/// A full recipe card shimmer — a white card containing a shimmering
/// image area, title line, and subtitle line. Matches [RecipeCard] dimensions.
class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerCard({this.height = 200.0, this.width = 160.0, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kBaseColor,
      highlightColor: _kHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Dimensions.radiusLg),
        ),
        child: Padding(
          padding: const EdgeInsets.all(Dimensions.space12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: _kBaseColor,
                    borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                  ),
                ),
              ),
              Dimensions.v12,
              // Title line
              Container(
                height: 16,
                width: width * 0.75,
                decoration: BoxDecoration(
                  color: _kBaseColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusXs),
                ),
              ),
              Dimensions.v8,
              // Subtitle line
              Container(
                height: 12,
                width: width * 0.5,
                decoration: BoxDecoration(
                  color: _kBaseColor,
                  borderRadius: BorderRadius.circular(Dimensions.radiusXs),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-page shimmer for the Recipe Detail screen shown while loading.
/// Mirrors the exact visual structure: big image area → title → stats → tabs → items.
class DetailShimmer extends StatelessWidget {
  const DetailShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _kBaseColor,
      highlightColor: _kHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Container(
              height: 340,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: _kBaseColor,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Container(
                    height: 28,
                    width: 240,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    height: 28,
                    width: 180,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Description lines
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 14,
                    width: 260,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Stats row
                  Container(
                    height: 56,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Tabs
                  Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _kBaseColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Ingredient tiles
                  for (int i = 0; i < 6; i++) ...[
                    Container(
                      height: 52,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _kBaseColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
