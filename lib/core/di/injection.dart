import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../network/network_info.dart';

import '../../features/ai/data/datasources/gemini_datasource.dart';
import '../../features/ai/data/datasources/local_keyword_datasource.dart';
import '../../features/ai/data/repositories/ai_repository_impl.dart';
import '../../features/ai/domain/repositories/ai_repository.dart';
import '../../features/ai/domain/usecases/categorize_expense_usecase.dart';
import '../../features/ai/presentation/bloc/ai_categorization_cubit.dart';

import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/auth_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import '../../features/dashboard/data/repositories/dashboard_repository_impl.dart';
import '../../features/dashboard/domain/repositories/dashboard_repository.dart';
import '../../features/dashboard/domain/usecases/get_dashboard_summary_usecase.dart';
import '../../features/dashboard/presentation/bloc/dashboard_bloc.dart';

import '../../features/expenses/data/datasources/expense_local_datasource.dart';
import '../../features/expenses/data/datasources/expense_remote_datasource.dart';
import '../../features/expenses/data/repositories/expense_repository_impl.dart';
import '../../features/expenses/domain/repositories/expense_repository.dart';
import '../../features/expenses/domain/usecases/expense_usecases.dart';
import '../../features/expenses/presentation/bloc/expense_bloc.dart';

import '../../features/analytics/presentation/bloc/analytics_bloc.dart';

/// Global service locator instance.
final getIt = GetIt.instance;

/// Registers all dependencies in the correct order.
///
/// Order matters — register infrastructure first, then data, domain, presentation.
void configureDependencies() {
  // ── Infrastructure ──────────────────────────────────────────────────────
  getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<GoogleSignIn>(() => GoogleSignIn());
  getIt.registerLazySingleton<Connectivity>(() => Connectivity());
  getIt.registerLazySingleton<http.Client>(() => http.Client());

  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<Connectivity>()),
  );

  // ── Auth feature ────────────────────────────────────────────────────────
  getIt.registerLazySingleton<FirebaseAuthDataSource>(
    () => FirebaseAuthDataSource(
      getIt<FirebaseAuth>(),
      getIt<FirebaseFirestore>(),
      getIt<GoogleSignIn>(),
    ),
  );

  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(getIt<FirebaseAuthDataSource>()),
  );

  getIt.registerLazySingleton<GetCurrentUserUseCase>(
    () => GetCurrentUserUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LoginUseCase>(
    () => LoginUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<RegisterUseCase>(
    () => RegisterUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<GoogleSignInUseCase>(
    () => GoogleSignInUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LogoutUseCase>(
    () => LogoutUseCase(getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<SendPasswordResetEmailUseCase>(
    () => SendPasswordResetEmailUseCase(getIt<AuthRepository>()),
  );

  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(
      getCurrentUser: getIt<GetCurrentUserUseCase>(),
      login: getIt<LoginUseCase>(),
      register: getIt<RegisterUseCase>(),
      googleSignIn: getIt<GoogleSignInUseCase>(),
      logout: getIt<LogoutUseCase>(),
      sendPasswordResetEmail: getIt<SendPasswordResetEmailUseCase>(),
    ),
  );

  // ── Expenses feature ────────────────────────────────────────────────────
  getIt.registerLazySingleton<ExpenseRemoteDataSource>(
    () => ExpenseRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ExpenseLocalDataSource>(
    () => ExpenseLocalDataSource(),
  );
  getIt.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(
      remote: getIt<ExpenseRemoteDataSource>(),
      local: getIt<ExpenseLocalDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  getIt.registerLazySingleton<GetExpensesUseCase>(
    () => GetExpensesUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<GetExpenseByIdUseCase>(
    () => GetExpenseByIdUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<CreateExpenseUseCase>(
    () => CreateExpenseUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<UpdateExpenseUseCase>(
    () => UpdateExpenseUseCase(getIt<ExpenseRepository>()),
  );
  getIt.registerLazySingleton<DeleteExpenseUseCase>(
    () => DeleteExpenseUseCase(getIt<ExpenseRepository>()),
  );

  getIt.registerFactory<ExpenseListBloc>(
    () => ExpenseListBloc(
      getExpenses: getIt<GetExpensesUseCase>(),
      deleteExpense: getIt<DeleteExpenseUseCase>(),
    ),
  );
  getIt.registerFactory<ExpenseFormBloc>(
    () => ExpenseFormBloc(
      create: getIt<CreateExpenseUseCase>(),
      update: getIt<UpdateExpenseUseCase>(),
    ),
  );

  // ── AI feature ──────────────────────────────────────────────────────────
  getIt.registerLazySingleton<GeminiDataSource>(
    () => GeminiDataSource(getIt<http.Client>()),
  );
  getIt.registerLazySingleton<LocalKeywordDataSource>(
    () => LocalKeywordDataSource(),
  );
  getIt.registerLazySingleton<AiRepository>(
    () => AiRepositoryImpl(
      getIt<GeminiDataSource>(),
      getIt<LocalKeywordDataSource>(),
    ),
  );
  getIt.registerLazySingleton<CategorizeExpenseUseCase>(
    () => CategorizeExpenseUseCase(getIt<AiRepository>()),
  );
  getIt.registerFactory<AiCategorizationCubit>(
    () => AiCategorizationCubit(getIt<CategorizeExpenseUseCase>()),
  );

  // ── Dashboard feature ────────────────────────────────────────────────────
  getIt.registerLazySingleton<DashboardRemoteDataSource>(
    () => DashboardRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<DashboardRepository>(
    () => DashboardRepositoryImpl(getIt<DashboardRemoteDataSource>()),
  );
  getIt.registerLazySingleton<GetDashboardSummaryUseCase>(
    () => GetDashboardSummaryUseCase(getIt<DashboardRepository>()),
  );
  getIt.registerFactory<DashboardBloc>(
    () => DashboardBloc(getIt<GetDashboardSummaryUseCase>()),
  );

  // ── Analytics feature ────────────────────────────────────────────────────
  getIt.registerFactory<AnalyticsBloc>(
    () => AnalyticsBloc(getIt<FirebaseFirestore>()),
  );
}
