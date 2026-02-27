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
import '../features/contact/contact_form_screen.dart';
import '../features/reports/report_entity_screen.dart';
import '../features/admin/admin_moderation_screen.dart';
import '../providers/user_providers.dart';
import 'route_names.dart';

// Keys live OUTSIDE the provider so they're never recreated
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

/// Listenable that fires whenever auth state changes, so GoRouter
/// re-evaluates its redirect without being fully recreated.
class _AuthNotifier extends ChangeNotifier {
  _AuthNotifier(this._ref) {
    _ref.listen(isAuthenticatedProvider, (_, __) => notifyListeners());
    _ref.listen(isAdminProvider, (_, __) => notifyListeners());
  }
  final Ref _ref;
}

/// Quick fade for tab switches (120ms).
Page<void> _tabPage(LocalKey key, Widget child) => CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 120),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    );

/// Slide-up + fade for detail/modal routes (300ms).
Page<void> _slidePage(LocalKey key, Widget child) => CustomTransitionPage(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      transitionsBuilder: (_, animation, __, child) => SlideTransition(
        position: animation.drive(
          Tween(begin: const Offset(0, 0.06), end: Offset.zero)
              .chain(CurveTween(curve: Curves.easeOut)),
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );

final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isAuthenticated = ref.read(isAuthenticatedProvider);
      final isAdmin = ref.read(isAdminProvider);
      final isAuthRoute = state.matchedLocation.startsWith('/auth');
      final location = state.matchedLocation;
      final needsAuth = location.startsWith('/venue/create') ||
          location.startsWith('/show/create') ||
          location.startsWith('/activity') ||
          location.startsWith('/profile') ||
          location.startsWith('/report/') ||
          (location.startsWith('/venue/') && location.endsWith('/review')) ||
          (location.startsWith('/venue/') && location.endsWith('/claim'));
      final needsAdmin = location.startsWith('/admin');

      if (needsAuth && !isAuthenticated) return '/auth/sign-in';
      if (needsAdmin && !isAdmin) return '/home';
      if (isAuthRoute && isAuthenticated) return '/home';
      return null;
    },
    routes: [
      // Auth routes (outside shell) — plain fade
      GoRoute(
        path: '/auth/sign-in',
        name: RouteNames.signIn,
        pageBuilder: (_, state) => _tabPage(state.pageKey, const SignInScreen()),
      ),
      GoRoute(
        path: '/auth/sign-up',
        name: RouteNames.signUp,
        pageBuilder: (_, state) => _tabPage(state.pageKey, const SignUpScreen()),
      ),
      GoRoute(
        path: '/auth/reset-password',
        name: RouteNames.resetPassword,
        pageBuilder: (_, state) =>
            _tabPage(state.pageKey, const ResetPasswordScreen()),
      ),

      // Main shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            pageBuilder: (_, state) =>
                _tabPage(state.pageKey, const HomeScreen()),
          ),
          GoRoute(
            path: '/map',
            name: RouteNames.map,
            pageBuilder: (_, state) =>
                _tabPage(state.pageKey, const MapScreen()),
          ),
          GoRoute(
            path: '/explore',
            name: RouteNames.explore,
            pageBuilder: (_, state) =>
                _tabPage(state.pageKey, const VenueListScreen()),
          ),
          GoRoute(
            path: '/activity',
            name: RouteNames.activity,
            pageBuilder: (_, state) =>
                _tabPage(state.pageKey, const ActivityFeedScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: RouteNames.profile,
            pageBuilder: (_, state) =>
                _tabPage(state.pageKey, const ProfileScreen()),
          ),
        ],
      ),

      // IMPORTANT: /create routes BEFORE /:id routes
      GoRoute(
        path: '/venue/create',
        name: RouteNames.createVenue,
        pageBuilder: (_, state) =>
            _slidePage(state.pageKey, const CreateVenueScreen()),
      ),
      GoRoute(
        path: '/venue/:venueId',
        name: RouteNames.venueDetail,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          VenueDetailScreen(venueId: state.pathParameters['venueId']!),
        ),
      ),
      GoRoute(
        path: '/show/create',
        name: RouteNames.createShow,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          CreateShowScreen(venueId: state.uri.queryParameters['venueId']),
        ),
      ),
      GoRoute(
        path: '/show/:showId',
        name: RouteNames.showDetail,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          ShowDetailScreen(showId: state.pathParameters['showId']!),
        ),
      ),
      GoRoute(
        path: '/venue/:venueId/review',
        name: RouteNames.writeReview,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          WriteReviewScreen(
            parentType: 'venue',
            parentId: state.pathParameters['venueId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/venue/:venueId/claim',
        name: RouteNames.claimVenue,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          ContactFormScreen(
            isVenueClaim: true,
            venueId: state.pathParameters['venueId'],
            venueName: state.uri.queryParameters['name'],
          ),
        ),
      ),
      GoRoute(
        path: '/contact',
        name: RouteNames.contact,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          ContactFormScreen(
            isVenueClaim: state.uri.queryParameters['claim'] == 'true',
            venueId: state.uri.queryParameters['venueId'],
            venueName: state.uri.queryParameters['venueName'],
          ),
        ),
      ),
      GoRoute(
        path: '/report/:entityType/:entityId',
        name: RouteNames.reportEntity,
        pageBuilder: (_, state) => _slidePage(
          state.pageKey,
          ReportEntityScreen(
            entityType: state.pathParameters['entityType']!,
            entityId: state.pathParameters['entityId']!,
          ),
        ),
      ),
      GoRoute(
        path: '/profile/edit',
        name: RouteNames.editProfile,
        pageBuilder: (_, state) =>
            _slidePage(state.pageKey, const EditProfileScreen()),
      ),
      GoRoute(
        path: '/admin/moderation',
        name: RouteNames.adminModeration,
        pageBuilder: (_, state) =>
            _slidePage(state.pageKey, const AdminModerationScreen()),
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
          BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded), label: 'Home'),
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
