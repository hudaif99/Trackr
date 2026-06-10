<div align="center">

# Trackr 💸

**AI-powered personal expense tracker built with Flutter & Firebase**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![BLoC](https://img.shields.io/badge/State-BLoC%20Pattern-8A2BE2)](https://bloclibrary.dev)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20Architecture-0EA5E9)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![License](https://img.shields.io/badge/License-MIT-10B981)](LICENSE)

*Track every rupee. Understand your patterns. Zero effort.*

</div>

---

## 📖 Overview

**Trackr** is a production-ready Flutter application that helps users track personal expenses with minimal friction. At its core, Trackr uses **Google Gemini AI** to automatically categorize expenses as you type — so you spend less time on bookkeeping and more time understanding your finances.

The app is built following **Clean Architecture** principles with **BLoC** state management, backed by **Firebase** for real-time sync and **Hive** for offline-first local storage.

---

## ✨ Features

### 💡 Smart Expense Tracking
- Add expenses in seconds with an intuitive form
- **AI-powered auto-categorization** using Google Gemini 1.5 Flash — type an expense title and the category is automatically suggested with an 800ms debounce
- Fallback local keyword matching ensures categorization works even offline
- 9 expense categories: Food, Travel, Shopping, Bills, Entertainment, Health, Fuel, Education, Other
- 5 payment methods: Cash, Card, UPI, Net Banking, Wallet
- Optional notes for every expense

### 📊 Rich Analytics Dashboard
- **Spending hero card** — current month total with month-over-month percentage change
- **Category pie chart** — visual breakdown of where your money goes
- **Monthly trend line chart** — 6-month spending history at a glance
- **Weekly bar chart** — spending pattern by week within the current month
- Quick stats: average monthly spend, top category, transaction count

### 🔐 Authentication
- Email & password sign-up / login
- **Google Sign-In** (one-tap OAuth flow)
- Password reset via email
- Persistent auth state — stays logged in across app restarts

### 📱 Offline-First Architecture
- Expenses are written to **Hive** local storage immediately
- Background sync queue pushes pending writes to **Firestore** when connectivity is restored
- Connectivity detection via `connectivity_plus`
- Sync status indicator on each expense tile

### 🎨 Premium Dark-First UI
- Curated dark slate color palette (`#0F172A` / `#111827`)
- Emerald green brand accent (`#10B981`)
- Google Fonts typography (Inter)
- Shimmer skeleton loaders during data fetching
- Smooth animations and micro-interactions throughout
- Native splash screen via `flutter_native_splash`
- Full dark & light theme support

### 🧭 Navigation & UX
- Bottom navigation with 3 tabs: Home, Expenses, Analytics
- Shell route architecture — tabs maintain independent state
- Double-tap back to exit from the home tab
- 3-slide onboarding shown only on first launch

---

## 🏗️ Architecture

Trackr strictly follows **Clean Architecture** with a feature-first folder structure. Each feature is fully self-contained with its own data, domain, and presentation layers.

```
lib/
├── core/                          # Shared infrastructure
│   ├── constants/                 # App-wide constants & route names
│   ├── di/                        # GetIt dependency injection
│   ├── errors/                    # Failure types
│   ├── network/                   # Connectivity detection
│   ├── router/                    # GoRouter configuration & shell
│   ├── theme/                     # Colors, text styles, app theme
│   └── widgets/                   # Reusable UI components
│
└── features/
    ├── ai/                        # Gemini AI categorization
    │   ├── data/                  # GeminiDataSource, LocalKeywordDataSource
    │   ├── domain/                # CategorizeExpenseUseCase
    │   └── presentation/          # AiCategorizationCubit
    │
    ├── auth/                      # Authentication
    │   ├── data/                  # FirebaseAuthDataSource
    │   ├── domain/                # Login, Register, GoogleSignIn use cases
    │   └── presentation/          # AuthBloc, Login/Register/Splash pages
    │
    ├── dashboard/                 # Home screen
    │   ├── data/                  # DashboardRemoteDataSource
    │   ├── domain/                # GetDashboardSummaryUseCase
    │   └── presentation/          # DashboardBloc, DashboardPage + widgets
    │
    ├── expenses/                  # Expense CRUD
    │   ├── data/                  # ExpenseRemoteDataSource, ExpenseLocalDataSource
    │   ├── domain/                # Create/Update/Delete/Get use cases
    │   └── presentation/          # ExpenseListBloc, ExpenseFormBloc, pages + widgets
    │
    ├── analytics/                 # Charts & insights
    │   └── presentation/          # AnalyticsBloc (direct Firestore queries)
    │
    └── onboarding/                # First-launch onboarding flow
```

### Architectural Layers

| Layer | Responsibility |
|-------|---------------|
| **Presentation** | BLoC/Cubit, Pages, Widgets — pure UI & state |
| **Domain** | Use Cases, Entities, Repository interfaces — pure Dart, zero framework dependencies |
| **Data** | Repository implementations, Remote & Local data sources, Models |

### Dependency Rule
Dependencies only point **inward** — presentation depends on domain, data depends on domain. The domain layer has **zero** knowledge of Flutter, Firebase, or any framework.

---

## 🔧 Tech Stack

| Category | Technology |
|----------|-----------|
| **Framework** | Flutter 3.x / Dart 3.x |
| **State Management** | flutter_bloc 9.x (BLoC + Cubit pattern) |
| **Navigation** | go_router 14.x (declarative, deep-link ready) |
| **Dependency Injection** | get_it 8.x |
| **Backend** | Firebase Auth, Cloud Firestore, Firebase Crashlytics, Firebase Analytics |
| **Local Storage** | Hive 2.x (NoSQL, typed adapters) |
| **AI** | Google Gemini 1.5 Flash (REST API) |
| **Charts** | fl_chart |
| **UI Utilities** | flutter_screenutil, shimmer, google_fonts, font_awesome_flutter |
| **Networking** | http, connectivity_plus |
| **Utilities** | intl, uuid, shared_preferences, equatable |
| **Splash** | flutter_native_splash (Android 12+ SplashScreen API) |

---

## 🗂️ State Management — BLoC Pattern

Each feature has its own BLoC/Cubit, all registered as **lazy singletons** in GetIt. The shell's `MultiBlocProvider` wraps these via `BlocProvider.value` (without taking ownership) so singleton lifecycle is managed entirely by GetIt, not the widget tree.

```
AuthBloc          — global, provided at root; drives all auth-gated navigation
DashboardBloc     — lazy singleton; refreshes on new expense save
ExpenseListBloc   — lazy singleton; preserves active category filter across navigations
AnalyticsBloc     — lazy singleton; direct Firestore queries for efficiency
ExpenseFormBloc   — factory; fresh instance per AddExpensePage push
AiCategorizationCubit — factory; scoped to AddExpensePage lifecycle
```

**Key pattern:** When an expense is saved from `AddExpensePage` (which is pushed above the shell navigator via `parentNavigatorKey`), refresh events are dispatched directly via `getIt<DashboardBloc>()` — bypassing the BuildContext scope issue — and all three tabs update automatically without a manual pull-to-refresh.

---

## 🤖 AI Categorization

The AI pipeline uses a two-tier approach for reliability:

```
User types expense title
        │
        ▼ (800ms debounce)
 ┌──────────────────┐
 │  Gemini 1.5 Flash │  (primary — cloud)
 │  REST API call    │
 └──────────────────┘
        │ fails / offline?
        ▼
 ┌──────────────────┐
 │  Local keyword   │  (fallback — instant)
 │  matcher         │
 └──────────────────┘
        │
        ▼
 Category auto-selected in form
```

The debounce (800ms) avoids excessive API calls while the user is still typing. A spinning indicator in the text field suffix gives real-time feedback.

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `>=3.5.0`
- Dart SDK `>=3.5.0`
- Firebase project with **Authentication**, **Firestore**, **Crashlytics**, and **Analytics** enabled
- Google Gemini API key

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/trackr.git
cd trackr

# 2. Install dependencies
flutter pub get

# 3. Set up Firebase
# Place google-services.json in android/app/
# Place GoogleService-Info.plist in ios/Runner/

# 4. Configure environment (API keys)
# Create lib/core/constants/env.dart:
# abstract final class Env {
#   static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
# }

# 5. Run
flutter run
```

### Firestore Indexes Required

The analytics query requires a composite index on the `expenses` collection:

| Field | Order |
|-------|-------|
| `userId` | Ascending |
| `date` | Ascending |

Firebase will print a direct URL in the console to auto-create this index if it's missing.

---

## 📁 Key Design Decisions

### Why BLoC over Riverpod/Provider?
BLoC enforces a strict separation between events, states, and business logic. The explicit event-driven model makes state transitions easy to trace, test, and reason about — especially important in a fintech app where state correctness is critical.

### Why Clean Architecture?
Each feature's domain layer is pure Dart — fully testable without Flutter or Firebase. Swapping Firebase for a different backend would only require changing the `data` layer. This separation also made it straightforward to add the AI categorization feature without touching existing expense CRUD code.

### Why Hive for local storage?
Hive provides type-safe, schema-based persistence that's significantly faster than SQLite for key-value and collection workloads. The offline sync queue uses a separate Hive box (`pending_sync`) to guarantee no writes are lost during network outages.

### Offline-first sync strategy
Expenses are always written locally first, then pushed to Firestore. If a write fails (no connectivity), the item is placed in the `pending_sync` box. A sync service monitors connectivity changes and retries failed writes in order. This ensures the app is fully functional without an internet connection.

---

## 🧪 Testing

```bash
# Static analysis
dart analyze

# Widget tests
flutter test
```

The domain layer (use cases, entities) can be unit-tested without any Flutter or Firebase dependencies.


## 👤 Author

Built with ❤️ using Flutter & Firebase.

---

