import 'package:flutter/material.dart';

/// 骨架屏类型
enum SkeletonType {
  overview,
  list,
  card,
}

class SkeletonLoader extends StatefulWidget {
  /// 骨架屏类型
  final SkeletonType type;
  
  /// 列表类型时显示的项目数量
  final int itemCount;

  const SkeletonLoader({
    super.key,
    required this.type,
    this.itemCount = 5,
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.3, end: 0.6).animate(
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
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return switch (widget.type) {
          SkeletonType.overview => _buildOverviewSkeleton(),
          SkeletonType.list => _buildListSkeleton(),
          SkeletonType.card => _buildCardSkeleton(),
        };
      },
    );
  }

  /// 构建概览页骨架屏
  Widget _buildOverviewSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 仓库信息卡片骨架
          _buildCardSkeleton(),
          const SizedBox(height: 16),
          // README 标题骨架
          _buildSkeletonBox(width: 100, height: 24),
          const SizedBox(height: 12),
          // README 内容卡片骨架
          _buildReadmeCardSkeleton(),
        ],
      ),
    );
  }

  /// 构建列表骨架屏
  Widget _buildListSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: widget.itemCount,
      itemBuilder: (context, index) => _buildListItemSkeleton(),
    );
  }

  /// 构建卡片骨架屏
  Widget _buildCardSkeleton() {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 描述文本骨架
            _buildSkeletonBox(width: double.infinity, height: 16),
            const SizedBox(height: 8),
            _buildSkeletonBox(width: 200, height: 16),
            const SizedBox(height: 16),
            // 统计信息骨架
            Row(
              children: [
                _buildSkeletonBox(width: 60, height: 20),
                const SizedBox(width: 16),
                _buildSkeletonBox(width: 60, height: 20),
                const SizedBox(width: 16),
                _buildSkeletonBox(width: 80, height: 20),
              ],
            ),
            const SizedBox(height: 16),
            // 按钮骨架
            _buildSkeletonBox(width: 140, height: 36, borderRadius: 18),
          ],
        ),
      ),
    );
  }

  /// 构建 README 卡片骨架
  Widget _buildReadmeCardSkeleton() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            _buildSkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            _buildSkeletonBox(width: 280, height: 14),
            const SizedBox(height: 16),
            _buildSkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            _buildSkeletonBox(width: double.infinity, height: 14),
            const SizedBox(height: 10),
            _buildSkeletonBox(width: 200, height: 14),
            const SizedBox(height: 16),
            // 代码块骨架
            _buildSkeletonBox(
              width: double.infinity,
              height: 80,
              borderRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  /// 构建列表项骨架
  Widget _buildListItemSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // 头像/图标骨架
          _buildSkeletonBox(width: 40, height: 40, borderRadius: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题骨架
                _buildSkeletonBox(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                // 副标题骨架
                _buildSkeletonBox(width: 180, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建骨架占位框
  Widget _buildSkeletonBox({
    required double width,
    required double height,
    double borderRadius = 4,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.grey.shade800.withValues(alpha: _animation.value)
            : Colors.grey.shade300.withValues(alpha: _animation.value),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
