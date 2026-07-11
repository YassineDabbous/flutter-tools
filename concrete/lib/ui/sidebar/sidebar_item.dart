import 'package:concrete/concrete.dart';
import 'package:flutter/material.dart';
import 'package:core/core.dart';

// ignore: must_be_immutable
class SideBarItem extends StatelessWidget {
  SideBarItem({
    super.key,
    required this.title,
    this.icon,
    this.press,
    this.children = const [],
    this.path,
    this.index,
    this.active,
    this.onActive,
    this.tab = 0.0,
  }) : assert(children.isEmpty || press == null);

  List<SideBarItem> getChildren() {
    return [
      if (path != null)
        SideBarItem(tab: 20, title: title, active: active, path: path),
      ...children,
    ];
  }

  void fix() {
    if (children.isNotEmpty) {
      for (var element in children) {
        element.tab = tab + 20.0;
        element.index = index;
        element.onActive = onActive;
      }
    }
  }

  int? index; // for scroll position
  Function(int)? onActive;
  final bool? active;
  double tab = 0.0;
  final String title;
  final String? path;
  final IconData? icon;
  final VoidCallback? press;
  final List<SideBarItem> children;

  bool get isDivider => path == '';

  bool get isActive =>
      (active ?? false) || (path != null && Core.nav.path.startsWith(path!));
  void onTap() {
    if (press != null) {
      press?.call();
      return;
    }
    if (path != null) {
      Core.nav.push(path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDivider) {
      return title != '' ? TwoSidedTextBars(text: title) : const Divider();
    }
    if (index != null && onActive != null && isActive) {
      onActive?.call(index!);
    }
    final expanded =
        isActive || (children.where((element) => element.isActive).isNotEmpty);
    return Row(
      children: [
        SizedBox(width: tab),
        Expanded(
          child: children.isEmpty
              ? ListTile(
                  onTap: isDivider ? null : onTap,
                  // horizontalTitleGap: 0.0,
                  leading: Icon(icon),
                  title: Text(title),
                  selected: isActive,
                )
              : ExpansionTile(
                  trailing: const SizedBox(),
                  initiallyExpanded: expanded,
                  leading: Icon(icon),
                  title: Text(title),
                  children: getChildren(),
                ),
        ),
      ],
    );
  }
}

//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//
//

class TwoSidedTextBars extends StatelessWidget {
  final String text;

  const TwoSidedTextBars({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      // Centers the children in the Row
      mainAxisAlignment: MainAxisAlignment.center,
      // Aligns the bars and text vertically
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Bar
        Expanded(
          child: Container(
            height: 1.0, // Thickness of the bar
            color: Colors.grey, // Color of the bar
            margin: const EdgeInsets.only(
              right: 10.0,
            ), // Space between bar and text
          ),
        ),

        // Text
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Right Bar
        Expanded(
          child: Container(
            height: 1.0, // Thickness of the bar
            color: Colors.grey, // Color of the bar
            margin: const EdgeInsets.only(
              left: 10.0,
            ), // Space between text and bar
          ),
        ),
      ],
    );
  }
}
