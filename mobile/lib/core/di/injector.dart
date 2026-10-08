import 'package:get_it/get_it.dart';

import '../auth/auth_repository.dart';
import '../../features/dashboard/data/public_stats_repository.dart';
import '../auth/session.dart';
import '../network/api_client.dart';
import '../storage/app_preferences.dart';
import '../storage/token_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

/// Holds the active session in memory after login; null when unauthenticated.
class SessionManager {
  Session? _session;

  Session? get session => _session;
  bool get isAuthenticated => _session != null;

  void set(Session session) => _session = session;

  void clear() => _session = null;
}

Future<void> configureDependencies() async {
  sl.registerLazySingleton<TokenStorage>(() => TokenStorage());
  final prefs = AppPreferences(await SharedPreferences.getInstance());
  sl.registerLazySingleton(() => prefs);
  sl.registerLazySingleton<SessionManager>(() => SessionManager());

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(
      tokenProvider: () => sl<TokenStorage>().readAccess(),
      onUnauthorized: () {
        sl<SessionManager>().clear();
        sl<TokenStorage>().clear();
        routerNotifier.notifyUnauthorized();
      },
    ),
  );

  sl.registerLazySingleton(
    () => AuthRepository(apiClient: sl<ApiClient>(), tokenStorage: sl<TokenStorage>()),
  );

  sl.registerLazySingleton<PublicStatsRepository>(
    () => PublicStatsRepositoryImpl(apiClient: sl<ApiClient>()),
  );
}

/// Bridge so the dio 401 interceptor can trigger a router redirect to /login
/// regardless of where the failure happened (mirrors Angular handleUnauthorized).
class RouterNotifierBridge {
  final _listeners = <void Function()>[];

  void addListener(void Function() listener) => _listeners.add(listener);

  void removeListener(void Function() listener) => _listeners.remove(listener);

  void notifyUnauthorized() {
    for (final l in List.of(_listeners)) {
      l();
    }
  }
}

final routerNotifier = RouterNotifierBridge();