import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class LoadMoreWidget extends StatefulWidget {
  final int itemCount;
  final int shimmerCount;
  final bool isRefreshing;
  final bool maxReached;
  final Widget? header;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final Widget Function(BuildContext context, int index)? shimmerBuilder;
  final Future Function() onLoadMore;
  final Future Function()? onRefresh;
  final Axis scrollDirection;
  final EdgeInsets padding;
  final int adsAfter;
  final bool adsEnabled;
  final bool isActive;
  final bool reverse;
  //final SliverGridDelegate? gridDelegate;
  final int crossAxisCount;
  final double axisSpacing;
  final double gridRatio;
  final bool staggeredGrid;
  final bool noScrolling;
  const LoadMoreWidget({
    super.key,
    required this.onLoadMore,
    required this.itemCount,
    required this.itemBuilder,
    required this.maxReached,
    this.onRefresh,
    this.header,
    //this.gridDelegate,
    this.crossAxisCount = 1,
    this.gridRatio = 1.0,
    this.axisSpacing = 0,
    this.shimmerBuilder,
    this.isRefreshing = false,
    this.adsEnabled = false,
    this.isActive = true,
    this.shimmerCount = 1,
    this.adsAfter = 7,
    this.scrollDirection = Axis.vertical,
    this.padding = const EdgeInsets.all(8),
    this.staggeredGrid = false,
    this.reverse = false,
    this.noScrolling = false,
  });
  @override
  State<LoadMoreWidget> createState() => LoadMoreWidgetState();
}

class LoadMoreWidgetState extends State<LoadMoreWidget> {
  bool _loading = false;

  Future<void> _load() async {
    if (!_loading && !widget.maxReached) {
      setState(() {
        _loading = true;
      });
      await widget.onLoadMore();
      setState(() {
        _loading = false;
      });
    }
  }

  // ------------------------
  int getItemsCount() {
    if (!widget.adsEnabled || widget.adsAfter == 0 || widget.itemCount == 0) return widget.itemCount;
    int s = widget.itemCount;
    int p = (s ~/ (widget.adsAfter));
    int t = s + p;
    //logUI.debug('○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○○ COUNT => $t = $s + $p');
    return t;
  }

  Widget builder(BuildContext ctx, int position) {
    if (widget.adsEnabled && (position % (widget.adsAfter + 1)) == widget.adsAfter) {
      return Container(
        color: Colors.red,
        child: const Center(child: Text('ADS')),
      );
    }
    if (widget.adsEnabled && position > widget.adsAfter) {
      position = position - (position ~/ (widget.adsAfter + 1));
    }
    return widget.itemBuilder(ctx, position);
  }
  //-------------------------

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) => _onNotification(notification, context),
      child: CustomScrollView(
        reverse: widget.reverse,
        shrinkWrap: widget.noScrolling,
        physics: widget.noScrolling ? const NeverScrollableScrollPhysics() : null,
        scrollDirection: widget.scrollDirection,
        //controller: _scrollController,
        slivers: <Widget>[
          if (widget.header != null) SliverToBoxAdapter(child: widget.header),
          // CupertinoSliverNavigationBar(
          //   largeTitle: const Text("Hot news"),
          // ),
          // if(onRefresh!=null)
          // CupertinoSliverRefreshControl(
          //   onRefresh: widget.onRefresh,
          //   refreshTriggerPullDistance: 500,
          // ),
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
          if (widget.crossAxisCount < 2)
            SliverPadding(
              padding: widget.padding,
              sliver: widget.isRefreshing
                  ? (widget.shimmerBuilder == null
                        ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                        : SliverList(delegate: SliverChildBuilderDelegate(widget.shimmerBuilder!, childCount: widget.shimmerCount)))
                  : SliverList(delegate: SliverChildBuilderDelegate(builder, childCount: getItemsCount())),
            ),
          if (widget.crossAxisCount > 1 && !widget.staggeredGrid)
            SliverPadding(
              padding: widget.padding,
              sliver: widget.isRefreshing
                  ? (widget.shimmerBuilder == null
                        ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                        : SliverGrid(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: widget.crossAxisCount),
                            delegate: SliverChildBuilderDelegate(widget.shimmerBuilder!, childCount: widget.shimmerCount),
                          ))
                  : SliverGrid(
                      //gridDelegate: widget.gridDelegate!,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.crossAxisCount,
                        childAspectRatio: widget.gridRatio,
                        mainAxisSpacing: widget.axisSpacing,
                        crossAxisSpacing: widget.axisSpacing,
                      ),
                      delegate: SliverChildBuilderDelegate(builder, childCount: getItemsCount()),
                    ),
            ),

          if (widget.crossAxisCount > 1 && widget.staggeredGrid)
            SliverPadding(
              padding: widget.padding,
              sliver: widget.isRefreshing
                  ? (widget.shimmerBuilder == null
                        ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()))
                        : SliverStaggeredGrid.countBuilder(
                            crossAxisCount: widget.crossAxisCount,
                            staggeredTileBuilder: (_) => const StaggeredTile.fit(1),
                            itemBuilder: widget.shimmerBuilder!,
                            itemCount: widget.shimmerCount,
                            //children: List.generate(widget.shimmerCount, (index) => widget.shimmerBuilder!(context, index)),
                          )
                    //  SliverToBoxAdapter(
                    //       child: MasonryGridView.count(
                    //         crossAxisCount: widget.crossAxisCount,
                    //         itemCount: widget.shimmerCount,
                    //         itemBuilder: (context, index) => widget.shimmerBuilder!(context, index),
                    //       ),
                    //     )
                    )
                  : SliverStaggeredGrid.countBuilder(
                      crossAxisCount: widget.crossAxisCount,
                      staggeredTileBuilder: (_) => const StaggeredTile.fit(1),
                      itemBuilder: builder,
                      itemCount: getItemsCount(),
                    ),
              // SliverToBoxAdapter(
              //       child: MasonryGridView.count(
              //         crossAxisCount: widget.crossAxisCount,
              //         itemCount: getItemsCount(),
              //         itemBuilder: builder,
              //       ),
              //     ),
            ),
          //
          //
          //
          //
          //
          //
          //
          //
          SliverToBoxAdapter(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : const SizedBox(),
          ),
          SliverToBoxAdapter(
            child: widget.maxReached
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Center(child: Text('no more data'.i18n())),
                  )
                : const SizedBox(),
          ),
        ],
      ),
    );
  }

  bool _onNotification(ScrollNotification notification, BuildContext context) {
    if (!widget.isActive || widget.maxReached) {
      return true;
    }
    if (widget.scrollDirection == notification.metrics.axis) {
      if (notification is ScrollUpdateNotification) {
        if (!widget.reverse && notification.metrics.maxScrollExtent > notification.metrics.pixels && notification.metrics.maxScrollExtent - notification.metrics.pixels <= 100) {
          _load();
        } else if (widget.reverse &&
            notification.metrics.minScrollExtent < notification.metrics.pixels &&
            notification.metrics.minScrollExtent + 100 >= notification.metrics.pixels) {
          _load();
        }
        return true;
      }

      if (notification is OverscrollNotification) {
        if (notification.overscroll > 0) {
          _load();
        }
        return true;
      }
    }
    return false;
  }

  //late final ScrollController _scrollController;

  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController = ScrollController()..addListener(_onScroll);
  //   //_load();
  // }

  // @override
  // void dispose() {
  //   _scrollController.dispose();
  //   super.dispose();
  // }

  // void _onScroll() {
  //   var triggerFetchMoreSize = 0.9 * _scrollController.position.maxScrollExtent;
  //   if (_scrollController.position.pixels > triggerFetchMoreSize) {
  //     logUI.debug('_loading $_loading , widget.maxReached ${widget.maxReached}');
  //     _load();
  //   }
  // }
}
