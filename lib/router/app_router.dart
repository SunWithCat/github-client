import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ghclient/core/providers.dart';
import 'package:ghclient/models/repo.dart';
import 'package:ghclient/pages/explore_page.dart';
import 'package:ghclient/pages/home_page.dart';
import 'package:ghclient/pages/loading_page.dart';
import 'package:ghclient/pages/login_page.dart';
import 'package:ghclient/pages/repos_page.dart';
import 'package:ghclient/pages/repo_detail_page.dart';
import 'package:ghclient/pages/search_page.dart';
import 'package:ghclient/pages/settings_page.dart';
import 'package:ghclient/pages/starred_repos_page.dart';

class RepoDetailArgs {
  final Repo repo;
  final String token;

  const RepoDetailArgs({required this.repo, required this.token});
}

class GoRouterRefreshNotifier extends ChangeNotifier {
  GoRouterRefreshNotifier(this._ref) {
    _subscription = _ref.listen<ProfileState>(profileProvider, (_, __) {
      notifyListeners();
    });
  }

  final Ref _ref;
  late final ProviderSubscription<ProfileState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = GoRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final profileState = ref.read(profileProvider);
      final isLoading = profileState.isLoading;
      final isLoggedIn = profileState.isLoggedIn;
      final location = state.uri.path;

      final goingToLogin = location == '/login';
      final goingToLoading = location == '/loading';

      if (isLoading) {
        return goingToLoading ? null : '/loading';
      }

      if (!isLoggedIn) {
        return goingToLogin ? null : '/login';
      }

      if (goingToLogin || goingToLoading) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => const LoadingPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/explore',
        builder: (context, state) => const ExplorePage(),
      ),
      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/repos',
        builder: (context, state) => const ReposPage(),
      ),
      GoRoute(
        path: '/starred',
        builder: (context, state) => const StarredReposPage(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/repo',
        builder: (context, state) {
          final args = state.extra;
          if (args is RepoDetailArgs) {
            return RepoPage(repo: args.repo, token: args.token);
          }
          return const Scaffold(
            body: Center(child: Text('Invalid repo details')),
          );
        },
      ),
    ],
  );
});
