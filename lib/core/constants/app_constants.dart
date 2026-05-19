import 'env.dart';

/// Application-wide constants.
///
/// Route names, Firestore collections, Hive boxes, and API config
/// are all centralised here to avoid magic strings scattered across the codebase.
abstract final class AppConstants {
  // ── App ───────────────────────────────────────────────────────────────────
  static const String appName = 'Fluxo';
  static const String appVersion = '1.0.0';

  // ── Gemini AI ─────────────────────────────────────────────────────────────
  static const String geminiApiKey = Env.geminiApiKey;
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String geminiModel = 'gemini-1.5-flash';

  // ── Firestore Collections ──────────────────────────────────────────────────
  static const String usersCollection = 'users';
  static const String expensesCollection = 'expenses';

  // ── Hive Boxes ────────────────────────────────────────────────────────────
  static const String expenseBox = 'expenses';
  static const String pendingSyncBox = 'pending_sync';
  static const String settingsBox = 'settings';

  // ── Hive Type IDs ─────────────────────────────────────────────────────────
  static const int expenseModelTypeId = 0;
  static const int pendingSyncItemTypeId = 1;

  // ── SharedPreferences Keys ────────────────────────────────────────────────
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String themeModeKey = 'theme_mode';

  // ── Pagination ────────────────────────────────────────────────────────────
  static const int expensePageSize = 20;

  // ── Timeouts ──────────────────────────────────────────────────────────────
  static const Duration networkTimeout = Duration(seconds: 10);
  static const Duration aiDebounce = Duration(milliseconds: 800);
  static const Duration syncRetryDelay = Duration(seconds: 5);

  // ── Route Names ───────────────────────────────────────────────────────────
  static const String routeSplash = '/';
  static const String routeOnboarding = '/onboarding';
  static const String routeLogin = '/auth/login';
  static const String routeRegister = '/auth/register';
  static const String routeDashboard = '/home/dashboard';
  static const String routeExpenses = '/home/expenses';
  static const String routeAnalytics = '/home/analytics';
  static const String routeAddExpense = '/expenses/add';
  static const String routeExpenseDetail = '/expenses/:id';
  static const String routeEditExpense = '/expenses/:id/edit';

  // ── Animation Durations ───────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 200);
  static const Duration animNormal = Duration(milliseconds: 350);
  static const Duration animSlow = Duration(milliseconds: 600);
}
