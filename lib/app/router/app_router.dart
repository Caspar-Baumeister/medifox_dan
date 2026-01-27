import 'package:go_router/go_router.dart';

import '../../features/todos/presentation/pages/todos_list_page.dart';

/// Application router configuration using GoRouter.
/// Defines all navigation routes in the app.
class AppRouter {
  AppRouter._();

  /// The main router instance.
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
