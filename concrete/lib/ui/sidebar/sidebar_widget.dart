import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:concrete/concrete.dart';

class SideBar extends StatefulWidget {
  final List<Widget> items;
  const SideBar({super.key, required this.items});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  AuthResponse? authResponse;
  int current = 0;
  final ItemScrollController _scrollController = ItemScrollController();

  @override
  void initState() {
    super.initState();
    Future.delayed(Durations.short1, () => _scrollController.jumpTo(index: current, alignment: 0));
  }

  @override
  Widget build(BuildContext context) {
    for (final (index, value) in widget.items.indexed) {
      if (value is SideBarItem) {
        value.index = index;
        value.onActive = (p0) => current = p0;
        value.fix();
      }
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        return widget.items[index];
      },
    );
  }
}
