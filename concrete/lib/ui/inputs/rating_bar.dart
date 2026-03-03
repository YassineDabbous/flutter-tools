import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final bool disabled;
  final int itemsCount;
  final double initial;
  final double? size;
  final Color? disabledColor;
  final Function(int)? onUpdate;
  const RatingBar({super.key, required this.itemsCount, required this.initial, this.onUpdate, this.size, this.disabled = false, this.disabledColor});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: List.generate(
        itemsCount,
        (index) {
          return Padding(
            padding: Edges.xs,
            child: GestureDetector(
              onTap: disabled ? null : () => onUpdate?.call(index + 1),
              child: Icon(
                Icons.star,
                size: size,
                color: initial > index ? Colors.amber : (disabledColor ?? context.theme.disabledColor),
              ),
            ),
          );
        },
      ),
    );
  }
}
