import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerSkeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final ShapeBorder shapeBorder;

  const ShimmerSkeleton.rectangular({
    Key? key,
    this.width,
    required this.height,
    this.shapeBorder = const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  }) : super(key: key);

  const ShimmerSkeleton.circular({
    Key? key,
    required double size,
    this.shapeBorder = const CircleBorder(),
  })  : width = size,
        height = size,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width ?? double.infinity,
        height: height,
        decoration: ShapeDecoration(
          color: baseColor,
          shape: shapeBorder,
        ),
      ),
    );
  }
}
