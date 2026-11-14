import 'package:flutter/material.dart';
import 'package:ghclient/common/utils/app_log.dart';
import 'package:ghclient/common/utils/toast_utils.dart';

/// 获取指定页的数据；请求失败时抛出异常。
typedef PageLoader<T> = Future<List<T>> Function(int page);

/// 根据当前页数据判断是否继续加载。
typedef PageHasMore<T> = bool Function(List<T> pageItems);

class PaginatedTabListView<T> extends StatefulWidget {
  const PaginatedTabListView({
    super.key,
    required this.initialItems,
    required this.fetchPage,
    required this.hasMoreForPage,
    required this.itemBuilder,
    required this.emptyState,
    required this.onRefresh,
  });

  /// 首屏数据（第 1 页）
  final List<T> initialItems;

  /// 分页请求从第 2 页开始
  final PageLoader<T> fetchPage;

  /// 根据单页数据判断是否还有下一页
  final PageHasMore<T> hasMoreForPage;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget emptyState;
  final Future<void> Function() onRefresh;

  @override
  State<PaginatedTabListView<T>> createState() =>
      _PaginatedTabListViewState<T>();
}

class _PaginatedTabListViewState<T> extends State<PaginatedTabListView<T>>
    with AutomaticKeepAliveClientMixin<PaginatedTabListView<T>> {
  final _scrollController = ScrollController();
  late List<T> _items;
  late bool _hasMore;
  int _page = 1;
  int _generation = 0;
  bool _isLoadingMore = false;
  bool _isRefreshing = false;
  bool _loadFailed = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _resetItems();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant PaginatedTabListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.initialItems, oldWidget.initialItems)) {
      _resetItems();
    }
  }

  void _resetItems() {
    // 数据替换后，忽略之前发出的分页请求
    _generation++;
    _items = List<T>.of(widget.initialItems);
    _hasMore = widget.hasMoreForPage(widget.initialItems);
    _page = 1;
    _isLoadingMore = false;
    _loadFailed = false;
  }

  void _onScroll() {
    if (!_loadFailed && _scrollController.position.extentAfter <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _isRefreshing || !_hasMore) return;
    final generation = _generation;
    final nextPage = _page + 1;
    setState(() {
      _isLoadingMore = true;
      _loadFailed = false;
    });

    try {
      final newItems = await widget.fetchPage(nextPage);
      if (!mounted || generation != _generation) return;
      final hasMore = widget.hasMoreForPage(newItems);
      setState(() {
        _items.addAll(newItems);
        _page = nextPage;
        _hasMore = hasMore;
        _isLoadingMore = false;
      });
    } catch (error, stackTrace) {
      if (!mounted || generation != _generation) return;
      AppLog.e('加载分页数据失败', error, stackTrace);
      setState(() {
        _loadFailed = true;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _generation++;
      _isRefreshing = true;
      _isLoadingMore = false;
      _loadFailed = false;
    });
    try {
      // 由上级页面提供刷新
      await widget.onRefresh();
    } catch (error, stackTrace) {
      if (!mounted) return;
      AppLog.e('刷新分页列表失败', error, stackTrace);
      if (ScaffoldMessenger.maybeOf(context) != null) {
        ToastUtils.show(
          context,
          message: '刷新失败，请稍后重试',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _handleRefresh,
        child: ListView.builder(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: _items.isEmpty
              ? EdgeInsets.zero
              : const EdgeInsets.symmetric(vertical: 8),
          itemCount: _items.isEmpty
              ? 1
              : _items.length + (_isLoadingMore || _loadFailed ? 1 : 0),
          itemBuilder: (context, index) {
            if (_items.isEmpty) {
              return SizedBox(
                height: constraints.hasBoundedHeight
                    ? constraints.maxHeight
                    : null,
                child: widget.emptyState,
              );
            }
            if (index < _items.length) {
              return widget.itemBuilder(context, _items[index]);
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: _loadFailed
                    ? TextButton(onPressed: _loadMore, child: const Text('重试'))
                    : const CircularProgressIndicator(),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _generation++;
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }
}
