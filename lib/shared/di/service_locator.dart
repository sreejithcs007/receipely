import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/storage_service.dart';
import '../services/token_storage.dart';
import '../services/user_cache_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // ── Supabase Client ──────────────────────────────────────────────────
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Services ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<StorageService>(() => StorageService());
  getIt.registerLazySingleton<TokenStorage>(
    () => TokenStorage(getIt<StorageService>()),
  );
  getIt.registerLazySingleton<UserCacheService>(
    () => UserCacheService(getIt<StorageService>()),
  );
}
