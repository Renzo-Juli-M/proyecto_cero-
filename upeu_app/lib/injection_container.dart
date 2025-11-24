import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/network/dio_client.dart';
import 'core/network/local_storage.dart';
import 'features/admin/data/datasources/admin_remote_datasource.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_admin_usecase.dart';
import 'features/auth/domain/usecases/login_student_usecase.dart';
import 'features/auth/domain/usecases/login_juror_usecase.dart';
import 'features/auth/domain/usecases/logout_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  // ========== Features - Auth ==========

  // Bloc
  sl.registerFactory(
        () => AuthBloc(
      loginAdminUseCase: sl(),
      loginStudentUseCase: sl(),
      loginJurorUseCase: sl(),
      logoutUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginAdminUseCase(sl()));
  sl.registerLazySingleton(() => LoginStudentUseCase(sl()));
  sl.registerLazySingleton(() => LoginJurorUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
        () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      localStorage: sl(),
      dioClient: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImpl(sl()),
  );
  // ========== Features - Admin ==========

  // Data sources
  sl.registerLazySingleton<AdminRemoteDataSource>(
        () => AdminRemoteDataSourceImpl(sl()),
  );

  // ========== Core ==========

  // Network
  sl.registerLazySingleton(() => DioClient());

  // Local Storage
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => LocalStorage(sharedPreferences));
}