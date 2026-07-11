import 'package:flutter/material.dart';

/// A reusable Shimmer effect for skeleton loading.
class ShimmerHelper extends StatelessWidget {
  final double width;
  final double height;
  final ShapeBorder shapeBorder;

  const ShimmerHelper.rectangular({
    super.key,
    required this.width,
    required this.height,
  }) : shapeBorder = const RoundedRectangleBorder();

  const ShimmerHelper.circular({
    super.key,
    required this.width,
    required this.height,
    this.shapeBorder = const CircleBorder(),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: ShapeDecoration(color: Colors.grey[300]!, shape: shapeBorder),
    );
  }
}

/// A specialized loader for lists.
class ShimmerListLoader extends StatelessWidget {
  const ShimmerListLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        child: Row(
          children: [
            const ShimmerHelper.circular(width: 50, height: 50),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShimmerHelper.rectangular(width: double.infinity, height: 16),
                  const SizedBox(height: 8),
                  ShimmerHelper.rectangular(width: 150, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
