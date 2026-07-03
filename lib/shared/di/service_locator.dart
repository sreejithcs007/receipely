import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/supabase_data_source.dart';
import '../data/repositories/recipe_repository.dart';
import '../data/repositories/user_repository.dart';
import '../services/storage_service.dart';
import '../services/token_storage.dart';
import '../services/user_cache_service.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // ── Supabase Client ──────────────────────────────────────────────────
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );

  // ── Data Sources & Repositories ──────────────────────────────────────
  getIt.registerLazySingleton<SupabaseDataSource>(
    () => SupabaseDataSource(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<RecipeRepository>(
    () => RecipeRepository(getIt<SupabaseDataSource>()),
  );
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepository(getIt<SupabaseDataSource>()),
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
