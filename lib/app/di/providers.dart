import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../router/app_router.dart';

/// Provider for the GoRouter instance.
/// Use this provider to access the router throughout the app.
final goRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});
