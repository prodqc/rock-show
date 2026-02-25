import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_providers.dart';
import '../features/auth/sign_in_screen.dart';
import '../features/auth/sign_up_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/home/home_screen.dart';
import '../features/map/map_screen.dart';
import '../features/venues/venue_list_screen.dart';
import '../features/venues/venue_detail_screen.dart';
import '../features/venues/create_venue_screen.dart';
import '../features/shows/show_detail_screen.dart';
import '../features/shows/create_show_screen.dart';
import '../features/social/activity_feed_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/reviews/write_review_screen.dart';
import 'route_names.dart';

// Keys live OUTSIDE the provider so they're never recreated
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable that fires whenever auth state changes, so GoRouter
/// re-evaluates its redirect without being fully recreated.
class _AuthNotifier extends ChangeNotifier {
_AuthNotifier(this._ref) {
_ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final needsAuth = ['/venue/create', '/show/create', '/activity', '/profile']
          .any((p) => state.matchedLocation.startsWith(p));

      if (needsAuth && !isAuthenticated) return '/auth/sign-in';
      if (isAuthRoute && isAuthenticated) return '/home';
      return null;
    },
    routes: [
      // Auth routes (outside shell)
      GoRoute(
        path: '/auth/sign-in',
        name: RouteNames.signIn,
        builder: (_, __) => const SignInScreen(),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: RouteNames.signUp,
        builder: (_, __) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: RouteNames.resetPassword,
        builder: (_, __) => const ResetPasswordScreen(),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MapScreen(),
            ),
          ),
          GoRoute(
            path: '/explore',
            name: RouteNames.explore,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const VenueListScreen(),
            ),
          ),
          GoRoute(
            path: '/activity',
            name: RouteNames.activity,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ActivityFeedScreen(),
            ),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (_, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ProfileScreen(),
            ),
          ),
        ],
      ),

      // IMPORTANT: /create routes BEFORE /:id routes
      GoRoute(
        path: '/venue/create',
        name: RouteNames.createVenue,
        builder: (_, __) => const CreateVenueScreen(),
      ),
      GoRoute(
        path: '/venue/:venueId',
        name: RouteNames.venueDetail,
        builder: (_, state) => VenueDetailScreen(
          venueId: state.pathParameters['venueId']!,
        ),
      ),
      GoRoute(
        path: '/show/create',
        name: RouteNames.createShow,
        builder: (_, state) => CreateShowScreen(
          venueId: state.uri.queryParameters['venueId'],
        ),
      ),
      GoRoute(
        path: '/show/:showId',
        name: RouteNames.showDetail,
        builder: (_, state) => ShowDetailScreen(
          showId: state.pathParameters['showId']!,
        ),
      ),
      GoRoute(
        path: '/venue/:venueId/review',
        name: RouteNames.writeReview,
        builder: (_, state) => WriteReviewScreen(
          parentType: 'venue',
          parentId: state.pathParameters['venueId']!,
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
    ],
  );
});

/// Bottom navigation shell.
class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex(context),
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.map_rounded), label: 'Map'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded), label: 'Explore'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_rounded), label: 'Activity'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/map')) return 1;
    if (location.startsWith('/explore')) return 2;
    if (location.startsWith('/activity')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
      case 1:
        context.go('/map');
      case 2:
        context.go('/explore');
      case 3:
        context.go('/activity');
      case 4:
        context.go('/profile');
    }
  }
}