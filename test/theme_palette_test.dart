import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghclient/common/widgets/github_markdown.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/pages/repo_detail/issue_label.dart';
import 'package:ghclient/pages/settings_page.dart';
import 'package:ghclient/services/storage_service.dart';
import 'package:ghclient/theme/theme.dart';

double _contrast(Color fg, Color bg) {
  return IssueLabel.calculateContrastRatio(fg, bg);
}

class _FakeStorageService implements StorageService {
  String? savedMode;

  @override
  String? getThemeMode() => savedMode;

  @override
  Future<void> saveThemeMode(String mode) async {
    savedMode = mode;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _StaticProfileNotifier extends ProfileNotifier {
  @override
  ProfileState build() => ProfileState(
    isLoading: false,
    user: User(
      login: 'octocat',
      name: 'The Octocat',
      avatarUrl: 'https://example.com/avatar.png',
      followers: 0,
      following: 0,
      publicRepos: 0,
    ),
  );
}

void main() {
  group('GitHub Primer 双模式主题色板契约', () {
    test('lightMode 关键 M3 槽位均已显式配置，不回退为纯黑或纯白隐身', () {
      final cs = lightMode.colorScheme;
      expect(cs.outlineVariant, isNot(equals(Colors.black)));
      expect(lightMode.dividerColor, isNot(equals(Colors.black)));
      expect(cs.onSurfaceVariant, isNot(equals(Colors.black)));
      expect(cs.surfaceContainerHighest, isNot(equals(cs.surface)));
      expect(
        _contrast(cs.outlineVariant, cs.surface),
        inInclusiveRange(1.2, 2.2),
      );
      expect(_contrast(cs.outline, cs.surface), greaterThanOrEqualTo(3.0));
    });

    test('darkMode 主色具备明确交互色相，且全套前景/背景对比度满足 WCAG AA', () {
      final darkCs = darkMode.colorScheme;
      final darkHsl = HSLColor.fromColor(darkCs.primary);
      expect(
        darkHsl.saturation,
        greaterThan(0.5),
        reason: 'darkMode.primary 不能是 0% 饱和度纯灰',
      );

      // 深色模式核心色对 >= 4.5:1
      expect(
        _contrast(darkCs.onSurface, darkCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.onSurfaceVariant, darkCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.onSurfaceVariant, darkCs.surfaceContainerHighest),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.primary, darkCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.onPrimary, darkCs.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.onSecondary, darkCs.secondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.onPrimaryContainer, darkCs.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkCs.outline, darkCs.surface),
        greaterThanOrEqualTo(3.0),
      );

      // 浅色模式核心色对 >= 4.5:1
      final lightCs = lightMode.colorScheme;
      expect(
        _contrast(lightCs.onSurface, lightCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.onSurfaceVariant, lightCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.onSurfaceVariant, lightCs.surfaceContainerHighest),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.primary, lightCs.surface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.onPrimary, lightCs.primary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.onSecondary, lightCs.secondary),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightCs.onPrimaryContainer, lightCs.primaryContainer),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('AppSemanticColors 状态色满足 WCAG AA 且星标/分支保持经典鲜亮色值', () {
      final lightSem = lightMode.semanticColors;
      final lightSurface = lightMode.colorScheme.surface;
      expect(_contrast(lightSem.open, lightSurface), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(lightSem.closed, lightSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightSem.merged, lightSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(lightSem.attention, lightSurface),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(lightSem.link, lightSurface), greaterThanOrEqualTo(4.5));
      expect(lightSem.star, equals(const Color(0xFFFFB300)));
      expect(lightSem.fork, equals(const Color(0xFF00897B)));

      final darkSem = darkMode.semanticColors;
      final darkSurface = darkMode.colorScheme.surface;
      final darkElevated = darkMode.colorScheme.surfaceContainerHighest;
      expect(_contrast(darkSem.open, darkSurface), greaterThanOrEqualTo(4.5));
      expect(_contrast(darkSem.closed, darkSurface), greaterThanOrEqualTo(4.5));
      expect(_contrast(darkSem.merged, darkSurface), greaterThanOrEqualTo(4.5));
      expect(_contrast(darkSem.open, darkElevated), greaterThanOrEqualTo(4.5));
      expect(
        _contrast(darkSem.closed, darkElevated),
        greaterThanOrEqualTo(4.5),
      );
      expect(
        _contrast(darkSem.attention, darkElevated),
        greaterThanOrEqualTo(4.5),
      );
      expect(_contrast(darkSem.link, darkElevated), greaterThanOrEqualTo(4.5));
      expect(darkSem.star, equals(const Color(0xFFFFB300)));
      expect(darkSem.fork, equals(const Color(0xFF4DB6AC)));
    });

    test('裸 ThemeData 未挂载扩展时 semanticColors 按 Brightness 安全兜底', () {
      expect(
        ThemeData.light().semanticColors.open,
        equals(AppSemanticColors.light.open),
      );
      expect(
        ThemeData.dark().semanticColors.merged,
        equals(AppSemanticColors.dark.merged),
      );
    });

    test('卡片圆角在深浅模式下保持一致，避免切换主题发生几何跳变', () {
      final lightShape = lightMode.cardTheme.shape as RoundedRectangleBorder;
      final darkShape = darkMode.cardTheme.shape as RoundedRectangleBorder;
      expect(lightShape.borderRadius, equals(darkShape.borderRadius));
    });

    test('五档表面容器阶梯严格区分且 AppSemanticColors 具备值相等性', () {
      for (final theme in [lightMode, darkMode]) {
        final cs = theme.colorScheme;
        expect(
          cs.surfaceContainerHigh,
          isNot(equals(cs.surfaceContainerHighest)),
        );
        expect(cs.surfaceContainer, isNot(equals(cs.surfaceContainerHigh)));

        final searchTheme = theme.searchBarTheme;
        expect(
          searchTheme.elevation!.resolve(const <WidgetState>{}),
          equals(0),
        );
        expect(searchTheme.shape!.resolve(const <WidgetState>{}), isNotNull);
      }

      expect(AppSemanticColors.dark.copyWith(), equals(AppSemanticColors.dark));
      expect(
        AppSemanticColors.dark.copyWith().hashCode,
        equals(AppSemanticColors.dark.hashCode),
      );
      expect(AppSemanticColors.dark, isNot(equals(AppSemanticColors.light)));
    });

    testWidgets('GitHubMarkdown readme-typing-svg 缺省 color 时回退为当前主题 onSurface', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: darkMode,
          home: const Scaffold(
            body: GitHubMarkdown(
              data:
                  '<img src="https://readme-typing-svg.demolab.com?lines=Hello+Primer" />',
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 700));

      final textWidget = tester.widget<Text>(find.text('Hello Primer'));
      expect(textWidget.style?.color, equals(darkMode.colorScheme.onSurface));
      expect(textWidget.style?.color, isNot(equals(Colors.black)));

      // 销毁前推完轮播动画计时器
      await tester.pumpWidget(const SizedBox.shrink());
    });

    test('SwitchThemeData 在深浅模式的选中/未选中态均满足 >= 3.0:1 控件对比度且无半透明稀释', () {
      for (final theme in [lightMode, darkMode]) {
        final sw = theme.switchTheme;
        final surface = theme.colorScheme.surface;

        final unselectedThumb = sw.thumbColor!.resolve(const <WidgetState>{})!;
        final unselectedTrack = sw.trackColor!.resolve(const <WidgetState>{})!;
        final unselectedOutline = sw.trackOutlineColor!.resolve(
          const <WidgetState>{},
        )!;
        expect(
          _contrast(unselectedThumb, unselectedTrack),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness} 未选中滑块与轨道对比度需 >= 3.0:1',
        );
        expect(
          _contrast(unselectedOutline, surface),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness} 未选中轨道描边与卡片对比度需 >= 3.0:1',
        );

        const selected = <WidgetState>{WidgetState.selected};
        final selectedThumb = sw.thumbColor!.resolve(selected)!;
        final selectedTrack = sw.trackColor!.resolve(selected)!;
        final selectedOutline = sw.trackOutlineColor!.resolve(selected)!;
        expect(selectedTrack.a, equals(1.0));
        expect(selectedOutline, equals(Colors.transparent));
        expect(
          _contrast(selectedThumb, selectedTrack),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness} 选中滑块与轨道对比度需 >= 3.0:1',
        );
        expect(
          _contrast(selectedTrack, surface),
          greaterThanOrEqualTo(3.0),
          reason: '${theme.brightness} 选中轨道与卡片对比度需 >= 3.0:1',
        );
      }
    });

    testWidgets('SettingsPage 深色模式开关完全委托 ThemeData.switchTheme，无页面内联色值覆盖', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [profileProvider.overrideWith(_StaticProfileNotifier.new)],
          child: MaterialApp(theme: lightMode, home: const SettingsPage()),
        ),
      );

      final switchTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchTile.thumbColor, isNull);
      expect(switchTile.trackColor, isNull);
      expect(switchTile.trackOutlineColor, isNull);
    });
  });

  group('IssueLabel 极端边界与对比度保障', () {
    testWidgets('深色模式下极暗标签 (#000000) 与非法颜色均保持可见描边及 AA 文字对比度', (tester) async {
      for (final rawHex in ['000000', '24292e', '', 'invalid']) {
        await tester.pumpWidget(
          MaterialApp(
            theme: darkMode,
            home: Scaffold(
              body: Center(
                child: IssueLabel(name: 'tag', color: rawHex),
              ),
            ),
          ),
        );

        final container = tester.widget<Container>(find.byType(Container));
        final box = container.decoration! as BoxDecoration;
        final borderColor = box.border!.top.color;
        final surface = darkMode.colorScheme.surface;
        final effectiveBorder = Color.alphaBlend(borderColor, surface);
        final effectiveBg = Color.alphaBlend(box.color!, surface);
        final textWidget = tester.widget<Text>(find.text('tag'));

        expect(
          _contrast(effectiveBorder, surface),
          greaterThanOrEqualTo(1.35),
          reason: 'hex=$rawHex 描边不能黑化隐身',
        );
        expect(
          _contrast(textWidget.style!.color!, effectiveBg),
          greaterThanOrEqualTo(4.5),
          reason: 'hex=$rawHex 文字对比度需 >= 4.5:1',
        );
      }
    });

    test('浅色模式 getContrastColor 对中低明度饱和色 (#7057FF) 选择更高对比度的白字', () {
      final purpleLabel = IssueLabel.hexToColor('7057FF');
      final picked = IssueLabel.getContrastColor(purpleLabel);
      final whiteCr = _contrast(Colors.white, purpleLabel);
      final darkCr = _contrast(const Color(0xFF1F2328), purpleLabel);
      expect(whiteCr, greaterThan(darkCr));
      expect(picked, equals(Colors.white));
    });
  });

  group('ThemeNotifier 运行时动态切换', () {
    test('首启默认 darkMode，调用 toggleTheme 立即切换至 lightMode 并持久化', () async {
      final fakeStorage = _FakeStorageService();
      final container = ProviderContainer(
        overrides: [storageServiceProvider.overrideWithValue(fakeStorage)],
      );
      addTearDown(container.dispose);

      expect(container.read(themeProvider).brightness, Brightness.dark);

      await container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider).brightness, Brightness.light);
      expect(fakeStorage.savedMode, 'light');

      await container.read(themeProvider.notifier).toggleTheme();
      expect(container.read(themeProvider).brightness, Brightness.dark);
      expect(fakeStorage.savedMode, 'dark');
    });
  });
}
