import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/injection.dart';
import 'admin_session.dart';
import 'routes/admin_routes.dart';
import 'routes/detail_routes.dart';
import 'routes/shop_routes.dart';

/// The app's single router: a shop shell, an admin shell, and the admin gate
/// between them.
///
/// The gate redirect is the "route guard": every `/admin/...` location passes
/// only when [AdminSession.unlocked] is true; otherwise it is redirected to
/// `/admin/gate`, which either asks for the PIN or (first run) sets one
/// (Task 9's SettingsRepository decides which).
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter() {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: _adminRedirect,
    routes: [
      // --- Customer shop: bottom/rail navigation across four branches. ---
      shopShellRoutes(),

      // --- Top-level pages pushed over the shells (product detail,
      // checkout, order detail, admin order detail, product forms). ---
      ...detailRoutes(_rootNavigatorKey),

      // --- Admin area: gate + gated dashboard shell. ---
      ...adminRoutes(),
    ],
  );
}

/// Route guard for the admin area.
String? _adminRedirect(BuildContext context, GoRouterState state) {
  final path = state.uri.path;
  // Exact segment match, not a bare prefix: `/administrator` must not be
  // treated as an admin route (this guard is the security boundary).
  if (path != '/admin' && !path.startsWith('/admin/')) return null;
  // The gate itself is always reachable (it is where you get unlocked).
  if (path == '/admin/gate') return null;
  if (!getIt<AdminSession>().unlocked) return '/admin/gate';
  return null;
}
