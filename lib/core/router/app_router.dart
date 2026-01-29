import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/todos/presentation/pages/todos_list_page.dart';

/// Provider for the GoRouter instance.
final goRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.router;
});

/// Application router configuration using GoRouter.
class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'todos',
        builder: (context, state) => const TodosListPage(),
      ),
    ],
  );
}
