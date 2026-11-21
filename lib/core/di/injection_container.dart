import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local/app_preferences_datasource.dart';
import '../../data/datasources/local/auth_local_datasource.dart';
import '../../data/datasources/local/medical_local_datasource.dart';
import '../../data/datasources/remote/auth_remote_datasource.dart';
import '../../data/datasources/remote/firebase_auth_datasource.dart';
import '../../data/datasources/remote/medical_sync_remote_datasource.dart';
import '../../data/datasources/remote/subscription_remote_datasource.dart';
import '../../data/datasources/remote/supabase_auth_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/medical_record_repository_impl.dart';
import '../../data/repositories/sync_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/medical_record_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/medical/delete_medical_event_usecase.dart';
import '../../domain/usecases/medical/get_medical_timeline_usecase.dart';
import '../../domain/usecases/medical/save_medical_event_usecase.dart';
import '../../domain/usecases/sync/sync_both_ways_usecase.dart';
import '../../domain/usecases/sync/sync_local_to_cloud_usecase.dart';
import '../config/firebase_config.dart';
import '../config/supabase_config.dart';
import '../database/database_helper.dart';
import '../security/biometric_service.dart';
import '../services/notification_service.dart';
import '../services/ocr_service.dart';
import '../services/pdf_report_service.dart';

final sl = GetIt.instance;

class InjectionContainer {
  static final InjectionContainer _instance = InjectionContainer._internal();
  factory InjectionContainer() => _instance;
  InjectionContainer._internal();

  static Future<void> init() async {
    // 0. Khởi tạo Cloud Backend Services (Supabase & Firebase)
    await SupabaseConfig.initialize();
    await FirebaseConfig.initialize();

    // 1. Database & Core Services
    if (!sl.isRegistered<OcrService>()) {
      sl.registerLazySingleton<OcrService>(
        () => OcrServiceImpl(),
      );
    }

    if (!sl.isRegistered<PdfReportService>()) {
      sl.registerLazySingleton<PdfReportService>(
        () => PdfReportServiceImpl(),
      );
    }

    if (!sl.isRegistered<NotificationService>()) {
      sl.registerLazySingleton<NotificationService>(
        () => NotificationServiceImpl(),
      );
    }

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

    if (!sl.isRegistered<FirebaseAuthRemoteDataSource>()) {
      sl.registerLazySingleton<FirebaseAuthRemoteDataSource>(
        () => FirebaseAuthRemoteDataSourceImpl(),
      );
    }

    if (!sl.isRegistered<AuthLocalDataSource>()) {
      sl.registerLazySingleton<AuthLocalDataSource>(
        () => AuthLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }

    if (!sl.isRegistered<MedicalLocalDataSource>()) {
      sl.registerLazySingleton<MedicalLocalDataSource>(
        () => MedicalLocalDataSourceImpl(databaseHelper: sl<DatabaseHelper>()),
      );
    }

    if (!sl.isRegistered<MedicalSyncRemoteDataSource>()) {
      sl.registerLazySingleton<MedicalSyncRemoteDataSource>(
        () => MedicalSyncRemoteDataSourceImpl(client: SupabaseConfig.client),
      );
    }

    if (!sl.isRegistered<SubscriptionRemoteDataSource>()) {
      sl.registerLazySingleton<SubscriptionRemoteDataSource>(
        () => SubscriptionRemoteDataSourceImpl(),
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
          firebaseAuthRemoteDataSource: sl<FirebaseAuthRemoteDataSource>(),
        ),
      );
    }

    if (!sl.isRegistered<SyncRepository>()) {
      sl.registerLazySingleton<SyncRepository>(
        () => SyncRepositoryImpl(
          localDataSource: sl<MedicalLocalDataSource>(),
          remoteDataSource: sl<MedicalSyncRemoteDataSource>(),
          preferences: sl.isRegistered<SharedPreferences>() ? sl<SharedPreferences>() : null,
        ),
      );
    }

    if (!sl.isRegistered<MedicalRecordRepository>()) {
      sl.registerLazySingleton<MedicalRecordRepository>(
        () => MedicalRecordRepositoryImpl(
          localDataSource: sl<MedicalLocalDataSource>(),
          syncRepository: sl<SyncRepository>(),
        ),
      );
    }

    // 4. Use Cases
    if (!sl.isRegistered<GetMedicalTimelineUseCase>()) {
      sl.registerLazySingleton<GetMedicalTimelineUseCase>(
        () => GetMedicalTimelineUseCase(sl<MedicalRecordRepository>()),
      );
    }

    if (!sl.isRegistered<SaveMedicalEventUseCase>()) {
      sl.registerLazySingleton<SaveMedicalEventUseCase>(
        () => SaveMedicalEventUseCase(sl<MedicalRecordRepository>()),
      );
    }

    if (!sl.isRegistered<DeleteMedicalEventUseCase>()) {
      sl.registerLazySingleton<DeleteMedicalEventUseCase>(
        () => DeleteMedicalEventUseCase(sl<MedicalRecordRepository>()),
      );
    }

    if (!sl.isRegistered<SyncLocalToCloudUseCase>()) {
      sl.registerLazySingleton<SyncLocalToCloudUseCase>(
        () => SyncLocalToCloudUseCase(sl<SyncRepository>()),
      );
    }

    if (!sl.isRegistered<SyncBothWaysUseCase>()) {
      sl.registerLazySingleton<SyncBothWaysUseCase>(
        () => SyncBothWaysUseCase(sl<SyncRepository>()),
      );
    }
  }
}
