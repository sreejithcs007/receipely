import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/dimensions.dart';
import '../../utils/extension/context_extension.dart';

class ShimmerCard extends StatelessWidget {
  final double height;
  final double width;

  const ShimmerCard({this.height = 200.0, this.width = 160.0, super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.grey.c200,
      highlightColor: context.grey.c50,
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Dimensions.radiusMd),
                  ),
                ),
              ),
              Dimensions.v12,
              Container(
                height: 16.0,
                width: width * 0.75,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(Dimensions.radiusXs),
                ),
              ),
              Dimensions.v8,
              Container(
                height: 12.0,
                width: width * 0.5,
                decoration: BoxDecoration(
                  color: Colors.white,
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
