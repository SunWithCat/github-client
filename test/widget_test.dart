// Basic Flutter widget test for GhClient app
//
// This is a smoke test to verify the app can be built and rendered.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghclient/common/utils/date_formatter.dart';
import 'package:ghclient/common/widgets/empty_state.dart';
import 'package:ghclient/common/widgets/skeleton_loader.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/my_user_model.dart';
import 'package:ghclient/pages/home_page.dart';

void main() {
  group('DateFormatter', () {
    test('format returns correct format for valid ISO date', () {
      // Using a fixed UTC date to avoid timezone issues in tests
      final result = DateFormatter.format('2024-12-22T10:30:45Z');
      // Should contain date parts
      expect(result.contains('2024'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('22'), isTrue);
    });

    test('format returns original string for invalid date', () {
      final result = DateFormatter.format('invalid-date');
      expect(result, equals('invalid-date'));
    });

    test('dateOnly returns correct format', () {
      final result = DateFormatter.dateOnly('2024-12-22T10:30:45Z');
      // Should contain date parts only
      expect(result.contains('2024'), isTrue);
      expect(result.contains('12'), isTrue);
      expect(result.contains('22'), isTrue);
      // Should not contain time separator
      expect(result.contains(':'), isFalse);
    });

    test('relative returns relative time string', () {
      // Test with a date from the past
      final pastDate = DateTime.now().subtract(const Duration(hours: 2));
      final result = DateFormatter.relative(pastDate.toIso8601String());
      expect(result.contains('小时前'), isTrue);
    });
  });

  group('EmptyState Widget', () {
    testWidgets('renders with required properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
            ),
          ),
        ),
      );

      expect(find.text('No Items'), findsOneWidget);
      expect(find.text('There are no items to display'), findsOneWidget);
      expect(find.byIcon(Icons.inbox), findsOneWidget);
    });

    testWidgets('renders action button when provided', (WidgetTester tester) async {
      bool actionCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.inbox,
              title: 'No Items',
              message: 'There are no items to display',
              actionLabel: 'Add Item',
              onAction: () => actionCalled = true,
            ),
          ),
        ),
      );

      expect(find.text('Add Item'), findsOneWidget);
      
      await tester.tap(find.text('Add Item'));
      expect(actionCalled, isTrue);
    });
  });

  group('SkeletonLoader Widget', () {
    testWidgets('renders overview skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.overview),
          ),
        ),
      );

      // Should render without errors
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders list skeleton with items', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.list, itemCount: 3),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('renders card skeleton', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLoader(type: SkeletonType.card),
          ),
        ),
      );

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });
  });

  group('HomePage Widget', () {
    testWidgets('shows minimal loading view before showing empty state', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(const ProfileState(isLoading: true));
      await _pumpHomePage(tester, notifier);

      expect(find.byKey(const ValueKey('home_loading')), findsOneWidget);
      expect(find.text('正在同步 GitHub 数据...'), findsOneWidget);
      expect(find.text('未能找到用户消息'), findsNothing);
    });

    testWidgets('shows empty state when loading completed and no user', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(const ProfileState(isLoading: false));
      await _pumpHomePage(tester, notifier);

      expect(find.byKey(const ValueKey('home_empty')), findsOneWidget);
      expect(find.text('未能找到用户消息'), findsOneWidget);
    });

    testWidgets('shows content sections when user exists', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(
          isLoading: false,
          user: _fakeUser(),
          profileReadme: '# Hello',
        ),
      );
      await _pumpHomePage(tester, notifier);

      expect(find.byKey(const ValueKey('home_content')), findsOneWidget);
      expect(find.text('The Octocat'), findsOneWidget);
      expect(find.text('@octocat'), findsOneWidget);
      expect(find.text('Profile README'), findsOneWidget);
      expect(find.text('仓库'), findsOneWidget);
      expect(find.text('星标'), findsOneWidget);
    });

    testWidgets('navigates to repos page from quick action', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(isLoading: false, user: _fakeUser()),
      );
      final router = await _pumpHomePage(tester, notifier);

      await tester.tap(find.text('仓库'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/repos');
      expect(find.text('repos-page'), findsOneWidget);
    });

    testWidgets('navigates to starred page from quick action', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(isLoading: false, user: _fakeUser()),
      );
      final router = await _pumpHomePage(tester, notifier);

      await tester.tap(find.text('星标'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/starred');
      expect(find.text('starred-page'), findsOneWidget);
    });

    testWidgets('navigates to settings page from header action', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(isLoading: false, user: _fakeUser()),
      );
      final router = await _pumpHomePage(tester, notifier);

      await tester.tap(find.byTooltip('设置'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/settings');
      expect(find.text('settings-page'), findsOneWidget);
    });

    testWidgets('navigates to explore page from floating button', (
      WidgetTester tester,
    ) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(isLoading: false, user: _fakeUser()),
      );
      final router = await _pumpHomePage(tester, notifier);

      await tester.tap(find.text('探索'));
      await tester.pumpAndSettle();

      expect(router.routeInformationProvider.value.uri.path, '/explore');
      expect(find.text('explore-page'), findsOneWidget);
    });

    testWidgets('pull to refresh calls refreshData', (WidgetTester tester) async {
      final notifier = _FakeProfileNotifier(
        ProfileState(isLoading: false, user: _fakeUser()),
      );
      await _pumpHomePage(tester, notifier);

      await tester.drag(find.byType(ListView).first, const Offset(0, 320));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(notifier.refreshCallCount, 1);
    });
  });
}

User _fakeUser() {
  return User(
    login: 'octocat',
    name: 'The Octocat',
    avatarUrl: 'https://example.com/avatar.png',
    bio: 'GitHub mascot',
    followers: 100,
    following: 42,
    publicRepos: 12,
    location: 'San Francisco',
    createdAt: '2020-01-01T00:00:00Z',
  );
}

class _FakeProfileNotifier extends ProfileNotifier {
  _FakeProfileNotifier(this._initialState);

  final ProfileState _initialState;
  int refreshCallCount = 0;

  @override
  ProfileState build() => _initialState;

  @override
  Future<void> refreshData() async {
    refreshCallCount += 1;
  }
}

Future<GoRouter> _pumpHomePage(
  WidgetTester tester,
  _FakeProfileNotifier notifier,
) async {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const HomePage()),
      GoRoute(
        path: '/repos',
        builder: (context, state) => const Scaffold(body: Text('repos-page')),
      ),
      GoRoute(
        path: '/starred',
        builder: (context, state) => const Scaffold(body: Text('starred-page')),
      ),
      GoRoute(
        path: '/settings',
        builder:
            (context, state) => const Scaffold(body: Text('settings-page')),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const Scaffold(body: Text('explore-page')),
      ),
    ],
  );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [profileProvider.overrideWith(() => notifier)],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pump();
  return router;
}
