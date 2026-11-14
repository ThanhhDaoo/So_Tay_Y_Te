import 'package:get_it/get_it.dart';
import '../../data/datasources/local/app_preferences_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/supabase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../config/supabase_config.dart';
import '../database/database_helper.dart';
import '../security/biometric_service.dart';

final sl = GetIt.instance;

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  static Future<void> init() async {
    // 0. Khởi tạo Supabase Backend (Option A)
    await SupabaseConfig.initialize();

    // 1. Database & Core
    if (!sl.isRegistered<BiometricService>()) {
      sl.registerLazySingleton<BiometricService>(
        () => BiometricServiceImpl(),
      );
    }

    if (!sl.isRegistered<DatabaseHelper>()) {
      final dbHelper = AppDatabaseHelper();
      await dbHelper.init();
      sl.registerSingleton<DatabaseHelper>(dbHelper);
    }

    // 2. DataSources
    if (!sl.isRegistered<AppPreferencesDataSource>()) {
      sl.registerLazySingleton<AppPreferencesDataSource>(
        () => AppPreferencesDataSourceImpl(),
      );
    }

    if (!sl.isRegistered<AuthRemoteDataSource>()) {
      sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(),
      );
    }

    if (!sl.isRegistered<SupabaseAuthRemoteDataSource>()) {
      sl.registerLazySingleton<SupabaseAuthRemoteDataSource>(
        () => SupabaseAuthRemoteDataSourceImpl(),
      );
    }

    if (!sl.isRegistered<AuthLocalDataSource>()) {
      sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }

    // 3. Repositories
    if (!sl.isRegistered<AuthRepository>()) {
      sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
          remoteDataSource: sl<AuthRemoteDataSource>(),
          localDataSource: sl<AppPreferencesDataSource>(),
          authLocalDataSource: sl<AuthLocalDataSource>(),
          supabaseAuthRemoteDataSource: sl<SupabaseAuthRemoteDataSource>(),
        ),
      );
    }
  }
}
