# Project Setup & Installation — Recipely

This guide covers how to set up the development environment, install dependencies, and run the application.

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Stable channel)
- [Git](https://git-scm.com/)
- VS Code or Android Studio with Flutter & Dart plugins
- A [Supabase](https://supabase.com) account with a project created

---

## Installation

1. **Clone the repository:**

```bash
git clone <repository_url>
cd recipely
```

2. **Install dependencies:**

```bash
flutter pub get
```

---

## Environment Configuration

This project uses [envied](https://pub.dev/packages/envied) for secure environment variables.

1. Create a `.env` file in the root directory:

```properties
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

2. **Generate environment code:**

```bash
dart run build_runner build -d
```

> ⚠️ Never commit `.env` or `lib/env.g.dart` to version control. Add both to `.gitignore`.

---

## Supabase Setup

Ensure the following tables exist in your Supabase project with **RLS enabled**:

| Table | Purpose |
|---|---|
| `profiles` | Extended user data (name, avatar, cooking level) |
| `recipes` | Recipe catalog |
| `favorites` | User-saved recipes |
| `meal_plans` | Weekly meal plan entries |
| `shopping_list` | Shopping list items per user |
| `recipe_ratings` | User ratings and reviews |
| `categories` | Recipe category metadata |

Enable **Realtime** on `shopping_list` and `meal_plans` tables for live updates.

---

## Running the App

### Development

```bash
flutter run
```

### Profile / Release

```bash
flutter run --profile
flutter run --release
```

---

## Code Generation

Run all generators after cloning or modifying annotated files:

```bash
# All generators (json_serializable, envied, go_router_builder)
dart run build_runner build --delete-conflicting-outputs

# Watch mode during development
dart run build_runner watch -d

# Localization
flutter gen-l10n
```

---

## Troubleshooting

### Build Runner Conflict

```bash
dart run build_runner clean
dart run build_runner build --delete-conflicting-outputs
```

### Supabase Auth Not Working

- Confirm `SUPABASE_URL` and `SUPABASE_ANON_KEY` are correct in `.env`.
- Check RLS policies on the `profiles` table allow authenticated users to read/write their own rows.
- Ensure email confirmation is disabled for development in the Supabase Auth settings.

### iOS Setup

```bash
cd ios && pod install && cd ..
```

---

## Recommended VS Code Extensions

- **Flutter** — Dart & Flutter language support
- **Flutter Intl** — ARB localization file support
- **Dart Data Class Generator** — Boilerplate generation
- **Error Lens** — Inline error highlighting
