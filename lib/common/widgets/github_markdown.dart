import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_animate/flutter_animate.dart';

class GitHubMarkdown extends StatelessWidget {
  /// HTML 内容（来自 GitHub API 的 application/vnd.github.html+json 响应）
  final String data;

  /// GitHub 用户名（用于解析相对路径图片）
  final String? owner;

  /// GitHub 仓库名（用于解析相对路径图片）
  final String? repo;

  /// 默认分支
  final String branch;

  /// 是否可选择文本
  final bool selectable;

  /// 自定义链接点击回调
  final void Function(String? href)? onTapLink;

  const GitHubMarkdown({
    super.key,
    required this.data,
    this.owner,
    this.repo,
    this.branch = 'main',
    this.selectable = false,
    this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return HtmlWidget(
      data,
      // 文本是否可选
      textStyle: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade900,
      ),
      // 链接点击处理
      onTapUrl: (url) {
        if (onTapLink != null) {
          onTapLink!(url);
        } else {
          launchUrl(Uri.parse(url));
        }
        return true;
      },
      // 自定义图片渲染
      customWidgetBuilder: (element) {
        if (element.localName == 'img') {
          final src = element.attributes['src'];
          final canonicalSrc = element.attributes['data-canonical-src'];
          if (src == null || src.isEmpty) return null;

          final originalUrl = canonicalSrc ?? src;

          if (_isBadgeUrl(originalUrl)) {
            final pngUrl = _forcePngFormat(originalUrl);
            return _buildImage(pngUrl, isBadge: true);
          }

          if (originalUrl.contains('readme-typing-svg')) {
            return _buildTypingSvgFallback(originalUrl);
          }

          if (originalUrl.toLowerCase().contains('.svg')) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SvgPicture.network(
                originalUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return SvgPicture.network(
                    src,
                    fit: BoxFit.contain,
                    errorBuilder:
                        (context, error, stackTrace) => _buildImage(src),
                  );
                },
              ),
            );
          }

          final fullUrl = _processImageUrl(src);
          if (fullUrl != src) {
            return _buildImage(fullUrl);
          }

          return null;
        }
        return null;
      },
      // 自定义样式
      customStylesBuilder: (element) {
        // 隐藏 GitHub 的标题锚点图标 (小链条 🔗)
        if (element.localName == 'a' && element.classes.contains('anchor')) {
          return {'display': 'none'};
        }

        // 隐藏 GitHub 的标题锚点图标 (通常是带有 octicon-link 类的 svg)
        if (element.localName == 'svg' &&
            element.classes.contains('octicon-link')) {
          return {'display': 'none'};
        }

        // 代码块样式
        if (element.localName == 'pre') {
          return {
            'background-color':
                isDark ? 'rgba(50, 50, 50, 1.0)' : 'rgba(230, 230, 230, 1.0)',
            'border-radius': '8px',
            'padding': '12px',
          };
        }
        // 行内代码
        if (element.localName == 'code' && element.parent?.localName != 'pre') {
          return {
            'background-color':
                isDark ? 'rgba(60, 60, 60, 1.0)' : 'rgba(220, 220, 220, 1.0)',
            'padding': '2px 6px',
            'border-radius': '4px',
          };
        }
        // 引用块
        if (element.localName == 'blockquote') {
          return {
            'border-left': isDark ? '4px solid #FFA000' : '4px solid #607D8B',
            'padding': '12px 12px 12px 16px',
            'background-color':
                isDark ? 'rgba(60, 60, 60, 0.6)' : 'rgba(240, 240, 240, 1.0)',
          };
        }
        // 链接
        if (element.localName == 'a') {
          return {'color': isDark ? '#64B5F6' : '#1565C0'};
        }
        return null;
      },
    );
  }

  /// 构建统一样式的图片
  Widget _buildImage(String url, {bool isBadge = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isBadge ? 2.0 : 0.0,
        vertical: isBadge ? 3.0 : 8.0,
      ),
      child: CachedNetworkImage(
        imageUrl: url,
        height: isBadge ? 20.0 : null,
        fit: isBadge ? BoxFit.contain : BoxFit.fitWidth,
        fadeInDuration: const Duration(milliseconds: 300),
        errorWidget: (context, url, error) {
          debugPrint('图片加载失败: $url');
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// 处理图片 URL，补全 GitHub 相对路径
  String _processImageUrl(String src) {
    if (src.startsWith('http')) return src;
    if (owner == null || repo == null) return src;

    // 清理路径开头的 /
    final cleanPath = src.startsWith('/') ? src.substring(1) : src;

    // 构造 GitHub Raw 链接
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$cleanPath';
  }

  /// 判断是否为徽章服务 URL（通过域名精确匹配）
  static bool _isBadgeUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    const badgeHosts = [
      'img.shields.io',
      'shields.io',
      'badgen.net',
      'badge.fury.io',
      'codecov.io',
    ];
    return badgeHosts.any((d) => uri.host.contains(d));
  }

  /// 将徽章 URL 强制转为 PNG 格式
  static String _forcePngFormat(String url) {
    try {
      final uri = Uri.parse(url);
      var path = uri.path;
      if (path.endsWith('.svg')) {
        path = '${path.substring(0, path.length - 4)}.png';
      } else if (!path.endsWith('.png')) {
        path = '$path.png';
      }
      return uri.replace(path: path).toString();
    } catch (_) {
      return url;
    }
  }

  /// 解析 readme-typing-svg URL 参数，用原生 Text 静态展示文字内容
  Widget _buildTypingSvgFallback(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return const SizedBox.shrink();

    final params = uri.queryParameters;
    final lines = params['lines']?.split(';') ?? [];
    if (lines.isEmpty) return const SizedBox.shrink();

    final colorHex = params['color'] ?? '000000';
    final colorVal =
        int.tryParse(colorHex.replaceAll('#', ''), radix: 16) ?? 0x000000;
    final fontSize = double.tryParse(params['size'] ?? '20') ?? 20.0;
    final isCenter = params['center'] == 'true';
    final pauseMs = int.tryParse(params['pause'] ?? '2000') ?? 2000;

    return _TypingCarouselWidget(
      lines: lines,
      color: Color(colorVal | 0xFF000000),
      fontSize: fontSize,
      isCenter: isCenter,
      fontFamily: params['font'],
      pauseMs: pauseMs,
    );
  }
}

/// 专门为 readme-typing-svg 打造的原生轮播组件
class _TypingCarouselWidget extends StatefulWidget {
  final List<String> lines;
  final Color color;
  final double fontSize;
  final bool isCenter;
  final String? fontFamily;
  final int pauseMs;

  const _TypingCarouselWidget({
    required this.lines,
    required this.color,
    required this.fontSize,
    required this.isCenter,
    this.fontFamily,
    required this.pauseMs,
  });

  @override
  State<_TypingCarouselWidget> createState() => _TypingCarouselWidgetState();
}

class _TypingCarouselWidgetState extends State<_TypingCarouselWidget> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      alignment: widget.isCenter ? Alignment.center : Alignment.centerLeft,
      padding: EdgeInsets.zero,
      child: Animate(
            key: ValueKey(_currentIndex),
            onComplete: (controller) {
              if (mounted) {
                setState(() {
                  _currentIndex = (_currentIndex + 1) % widget.lines.length;
                });
              }
            },
            child: Text(
              widget.lines[_currentIndex],
              style: TextStyle(
                color: widget.color,
                fontSize: widget.fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: widget.fontFamily ?? 'monospace',
                height: 1.0,
              ),
              textAlign: widget.isCenter ? TextAlign.center : TextAlign.left,
            ),
          )
          .fadeIn(duration: 600.ms, curve: Curves.easeOut)
          .slideY(begin: 0.2, end: 0, duration: 600.ms)
          .then(delay: widget.pauseMs.ms)
          .fadeOut(duration: 400.ms)
          .slideY(begin: 0, end: -0.2, duration: 400.ms),
    );
  }
}
