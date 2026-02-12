import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:url_launcher/url_launcher.dart';

/// GitHub 风格的 Markdown 渲染组件
/// 
/// 支持：
/// - 自定义样式表
/// - HTML img/a 标签预处理
/// - 相对路径图片转换
/// - GitHub 扩展语法（表格、emoji 等）
class GitHubMarkdown extends StatelessWidget {
  /// Markdown 内容
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
    final processedData = _preprocessMarkdown(data);
    final styleSheet = _buildStyleSheet(context);

    return MarkdownBody(
      data: processedData,
      selectable: selectable,
      styleSheet: styleSheet,
      onTapLink: (text, href, title) {
        if (onTapLink != null) {
          onTapLink!(href);
        } else if (href != null) {
          launchUrl(Uri.parse(href));
        }
      },
      imageBuilder: (uri, title, alt) => _buildImage(uri, title, alt),
      extensionSet: md.ExtensionSet(
        md.ExtensionSet.gitHubFlavored.blockSyntaxes,
        [
          md.EmojiSyntax(),
          ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ],
      ),
    );
  }

  /// 预处理 Markdown 内容
  String _preprocessMarkdown(String content) {
    var result = content;
    
    // 移除 HTML 容器标签
    result = result.replaceAll(
      RegExp(r'<(div|p|center|span|figure|figcaption)[^>]*>', caseSensitive: false), 
      '\n'
    );
    result = result.replaceAll(
      RegExp(r'</(div|p|center|span|figure|figcaption)>', caseSensitive: false), 
      '\n'
    );
    
    // 处理 <a> 包裹的 <img>
    result = result.replaceAllMapped(
      RegExp(r'<a\s+[^>]*href\s*=\s*["\x27]([^"\x27]+)["\x27][^>]*>\s*<img\s+[^>]*src\s*=\s*["\x27]([^"\x27]+)["\x27][^>]*/?\s*>\s*</a>', caseSensitive: false),
      (match) {
        final href = match.group(1) ?? '';
        final src = match.group(2) ?? '';
        if (src.isEmpty) return match.group(0) ?? '';
        return '\n[![image]($src)]($href)\n';
      },
    );
    
    // 处理独立的 <img> 标签
    result = result.replaceAllMapped(
      RegExp(r'<img\s+[^>]*?/?>', caseSensitive: false),
      (match) {
        final imgTag = match.group(0) ?? '';
        String src = _extractAttribute(imgTag, 'src');
        if (src.isEmpty) return imgTag;
        String alt = _extractAttribute(imgTag, 'alt');
        if (alt.isEmpty) alt = 'image';
        return '\n![$alt]($src)\n';
      },
    );
    
    // 清理多余空行
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return result;
  }

  /// 提取 HTML 属性
  String _extractAttribute(String tag, String attrName) {
    final pattern = RegExp(
      attrName + r'\s*=\s*["\x27]([^"\x27]*)["\x27]',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(tag);
    return match?.group(1) ?? '';
  }

  /// 构建图片 Widget
  Widget _buildImage(Uri uri, String? title, String? alt) {
    String imageUrl = uri.toString();
    
    // Data URI
    if (imageUrl.startsWith('data:')) {
      try {
        final dataUri = Uri.parse(imageUrl);
        final base64Data = dataUri.data?.contentAsBytes();
        if (base64Data != null) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Image.memory(base64Data, fit: BoxFit.contain),
          );
        }
      } catch (e) {
        debugPrint('解析 Data URI 失败: $e');
      }
      return const SizedBox.shrink();
    }
    
    // 处理绝对 URL
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      imageUrl = _normalizeGitHubUrl(imageUrl);
    } else {
      // 处理相对路径
      imageUrl = _resolveRelativePath(imageUrl);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        placeholder: (context, url) => Container(
          height: 100,
          color: Colors.grey.shade200,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          debugPrint('图片加载失败: $url');
          return const SizedBox.shrink();
        },
        fit: BoxFit.contain,
      ),
    );
  }

  /// 标准化 GitHub URL
  String _normalizeGitHubUrl(String url) {
    // 移除锚点
    final hashIndex = url.indexOf('#');
    if (hashIndex != -1) {
      url = url.substring(0, hashIndex);
    }
    
    // github.com/blob/ → raw.githubusercontent.com
    final blobPattern = RegExp(
      r'https?://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)',
    );
    final blobMatch = blobPattern.firstMatch(url);
    if (blobMatch != null) {
      final o = blobMatch.group(1);
      final r = blobMatch.group(2);
      final b = blobMatch.group(3);
      var p = blobMatch.group(4) ?? '';
      final queryIndex = p.indexOf('?');
      if (queryIndex != -1) p = p.substring(0, queryIndex);
      return 'https://raw.githubusercontent.com/$o/$r/$b/$p';
    }
    
    // github.com/raw/ → raw.githubusercontent.com
    final rawPattern = RegExp(
      r'https?://github\.com/([^/]+)/([^/]+)/raw/([^/]+)/(.+)',
    );
    final rawMatch = rawPattern.firstMatch(url);
    if (rawMatch != null) {
      final o = rawMatch.group(1);
      final r = rawMatch.group(2);
      final b = rawMatch.group(3);
      var p = rawMatch.group(4) ?? '';
      final queryIndex = p.indexOf('?');
      if (queryIndex != -1) p = p.substring(0, queryIndex);
      return 'https://raw.githubusercontent.com/$o/$r/$b/$p';
    }
    
    return url;
  }

  /// 解析相对路径
  String _resolveRelativePath(String path) {
    // 移除锚点和查询参数
    var cleanPath = path;
    final hashIndex = cleanPath.indexOf('#');
    if (hashIndex != -1) cleanPath = cleanPath.substring(0, hashIndex);
    final queryIndex = cleanPath.indexOf('?');
    if (queryIndex != -1) cleanPath = cleanPath.substring(0, queryIndex);
    
    // 移除 ./ 和 /
    if (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    while (cleanPath.startsWith('../')) {
      cleanPath = cleanPath.substring(3);
    }
    
    // 如果没有 owner/repo，无法构建完整 URL
    if (owner == null || repo == null) {
      return path; // 返回原始路径
    }
    
    return 'https://raw.githubusercontent.com/$owner/$repo/$branch/$cleanPath';
  }

  /// 构建样式表
  MarkdownStyleSheet _buildStyleSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final baseSheet = MarkdownStyleSheet.fromTheme(theme);

    return baseSheet.copyWith(
      // 引用块
      blockquote: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
        fontStyle: FontStyle.italic,
      ),
      blockquoteDecoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800.withValues(alpha: 0.6) : Colors.grey.shade100,
        border: Border(
          left: BorderSide(
            color: isDark ? Colors.amber.shade600 : Colors.blueGrey.shade400,
            width: 4,
          ),
        ),
      ),
      blockquotePadding: const EdgeInsets.fromLTRB(16, 12, 12, 12),

      // 代码块
      code: TextStyle(
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        color: isDark ? Colors.orange.shade300 : Colors.deepOrange.shade700,
        fontFamily: 'monospace',
        fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * 0.9,
      ),
      codeblockDecoration: BoxDecoration(
        color: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
        ),
      ),
      codeblockPadding: const EdgeInsets.all(12),

      // 表格
      tableBorder: TableBorder.all(
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

      // 链接
      a: TextStyle(
        color: isDark ? Colors.lightBlue.shade300 : Colors.blue.shade700,
        decoration: TextDecoration.underline,
      ),
    );
  }
}
