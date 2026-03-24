# LifeMaster

LifeMaster is a Flutter-based personal management app that combines tasks, reminders, calendar planning, expense tracking, and subscription management in one place.

It is designed as a practical all-in-one productivity app with local-first data storage and a responsive UI for Android, iOS, and Web.

## Features

- Todo management with categories, due dates, and priority tags
- Reminder scheduling with local notifications and repeat options
- Calendar event planning with daily/monthly views
- Expense tracking with search and six-month trend charts
- Subscription tracking with billing cycles and active/inactive states
- Riverpod-based state management and Drift-powered local database

## Tech Stack

- **Framework**: Flutter (Material 3)
- **State Management**: Riverpod
- **Database**: Drift (SQLite, with Web support)
- **Navigation**: go_router
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications

## Project Structure

```text
lib/
  core/
    constants/
    router/
    services/
    theme/
  features/
    calendar/
    expense/
    reminder/
    subscription/
    todo/
  shared/
    data/
    presentation/
    providers/
  app.dart
  main.dart
```

## Getting Started

### Prerequisites

- Flutter SDK 3.24+
- Dart SDK 3.0+
- Android Studio / Xcode (for mobile builds)

### Installation

```bash
git clone https://github.com/<your-username>/lifemaster.git
cd lifemaster
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Development

### Static Analysis

```bash
flutter analyze
```

### Run Tests

```bash
flutter test
```

### Build Web

```bash
flutter config --enable-web
flutter build web --release
```

### Localization (i18n)

The app uses Flutter's built-in localization generator (`gen_l10n`) with ARB files:

- `lib/l10n/app_en.arb`
- `lib/l10n/app_zh.arb`

When adding or updating localized text:

1. Add keys to both ARB files
2. Run localization generation
3. Use `AppLocalizations.of(context)!` in UI code
4. Keep business identifiers (like category IDs) language-neutral and map them to localized labels at the presentation layer
5. Avoid hardcoded user-facing strings in Dart files

```bash
flutter gen-l10n
```

#### Localization Checklist

When adding a new feature or screen, run through this checklist:

- Add user-facing text to both `lib/l10n/app_en.arb` and `lib/l10n/app_zh.arb`
- Avoid hardcoded UI strings in Dart files
- Keep business values language-neutral (e.g. `weekly`, `Food`) and localize only at the presentation layer
- Use locale-aware date/number formatting via `intl` (do not hardcode date patterns per language)
- Regenerate localization files with `flutter gen-l10n`
- Run `flutter analyze` and `flutter test` before opening a PR

## CI/CD

This repository includes a GitHub Actions workflow for building and deploying the Flutter Web app to GitHub Pages:

- Workflow file: `.github/workflows/deploy_web.yml`

## Roadmap

- Improve test coverage for providers and business logic
- Add robust database migration strategy for schema updates
- Expand localization support and language switching
- Improve recurring reminder behavior across platforms

## Contributing

Contributions are welcome.

1. Fork the repository
2. Create a feature branch
3. Commit your changes with clear messages
4. Run `flutter analyze` and `flutter test`
5. Open a pull request

For more details, see `CONTRIBUTING.md`.

## License

This project is licensed under the MIT License. See `LICENSE` for details.
