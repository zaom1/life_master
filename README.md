# LifeMaster

[![Flutter CI](https://github.com/yourusername/lifemaster/actions/workflows/flutter.yml/badge.svg)](https://github.com/yourusername/lifemaster/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

LifeMaster is a comprehensive personal life management app built with Flutter. It helps you organize your daily tasks, manage expenses, track subscriptions, set reminders, and schedule events all in one place.

## Features

- **Todo Management**: Create, edit, and organize tasks with categories, due dates, and priority levels
- **Expense Tracker**: Record and categorize expenses with monthly trend charts
- **Subscription Manager**: Track recurring subscriptions with billing cycle reminders
- **Calendar Events**: Schedule and manage events with custom colors
- **Smart Reminders**: Set one-time or recurring reminders with local notifications
- **Search & Filter**: Quickly find expenses by category or description
- **Dark Mode Support**: Automatic theme switching based on system preference

## Screenshots

*(Add your screenshots here)*

## Tech Stack

- **Framework**: Flutter 3.24+
- **State Management**: Riverpod
- **Database**: Drift (SQLite)
- **Navigation**: Go Router
- **Charts**: fl_chart
- **Notifications**: flutter_local_notifications

## Getting Started

### Prerequisites

- Flutter SDK 3.24.0 or higher
- Dart SDK 3.0.0 or higher
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/lifemaster.git
cd lifemaster
```

2. Install dependencies:
```bash
flutter pub get
```

3. Generate required code:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

4. Run the app:
```bash
flutter run
```

### Building for Release

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Project Structure

```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── router/         # Navigation configuration
│   ├── services/       # Notification service
│   ├── theme/          # App themes
│   └── utils/          # Utility functions
├── features/
│   ├── calendar/       # Calendar events feature
│   ├── expense/        # Expense tracking feature
│   ├── reminder/       # Reminders feature
│   ├── subscription/   # Subscription management feature
│   └── todo/           # Todo management feature
├── shared/
│   ├── data/           # Database configuration
│   ├── domain/         # Shared models
│   └── presentation/   # Shared widgets
├── app.dart            # Main app widget
└── main.dart           # Entry point
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with [Flutter](https://flutter.dev)
- Icons by [Material Design](https://material.io/resources/icons)
