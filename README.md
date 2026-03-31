# Multando Mobile SDKs

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![React Native](https://img.shields.io/badge/React_Native-61DAFB?style=for-the-badge&logo=react&logoColor=black)
![Swift](https://img.shields.io/badge/Swift-F05138?style=for-the-badge&logo=swift&logoColor=white)
![Kotlin](https://img.shields.io/badge/Kotlin-7F52FF?style=for-the-badge&logo=kotlin&logoColor=white)

> Four platform SDKs for integrating traffic violation reporting into third-party mobile applications. Built from a shared OpenAPI specification to ensure consistent behavior across all platforms.

---

## SDK Overview

| SDK | Language | Files | Install Command |
|-----|----------|-------|----------------|
| Flutter | Dart | 35 | `flutter pub add multando_sdk` |
| React Native | TypeScript | 44 | `npm install @multando/react-native-sdk` |
| iOS | Swift | 30 | `pod 'MultandoSDK'` |
| Android | Kotlin | 35 | `implementation("com.multando:sdk:1.0.0")` |

## Features

All four SDKs share a common feature set:

- **Report creation** — 3-step flow with photo, location, and violation type
- **Offline queue** — reports are stored locally and synced when connectivity resumes
- **Auto token refresh** — JWT access tokens are refreshed transparently
- **Pre-built UI components** — drop-in screens for report creation and history
- **Type safety** — fully typed models generated from OpenAPI spec
- **Internationalization** — English and Spanish out of the box
- **Wallet integration** — MULTA token balance and transaction history
- **Error handling** — structured error types with retry logic

## Architecture

Each SDK follows a 3-layer architecture:

```
+-------------------------------+
|          UI Layer             |  Pre-built screens & widgets
|  (ReportFlow, WalletView)    |
+-------------------------------+
|        Service Layer          |  Business logic, auth, sync
|  (ReportService, AuthService) |
+-------------------------------+
|          Core Layer           |  HTTP client, models, storage
|  (ApiClient, Models, Cache)   |
+-------------------------------+
```

## Quick Start

### Flutter

```dart
import 'package:multando_sdk/multando_sdk.dart';

final multando = MultandoSDK(
  apiKey: 'mk_your_api_key',
  environment: Environment.production,
);

await multando.initialize();
final reports = await multando.reports.list();
```

### React Native

```typescript
import { MultandoSDK } from '@multando/react-native-sdk';

const multando = new MultandoSDK({
  apiKey: 'mk_your_api_key',
  environment: 'production',
});

await multando.initialize();
const reports = await multando.reports.list();
```

### iOS (Swift)

```swift
import MultandoSDK

let multando = MultandoSDK(
    apiKey: "mk_your_api_key",
    environment: .production
)

try await multando.initialize()
let reports = try await multando.reports.list()
```

### Android (Kotlin)

```kotlin
import com.multando.sdk.MultandoSDK
import com.multando.sdk.Environment

val multando = MultandoSDK(
    apiKey = "mk_your_api_key",
    environment = Environment.PRODUCTION
)

multando.initialize()
val reports = multando.reports.list()
```

## SDK Services

Each SDK exposes the following service modules:

| Service | Methods | Description |
|---------|---------|-------------|
| `auth` | `login`, `register`, `refresh`, `logout` | Authentication flows |
| `reports` | `create`, `list`, `get`, `update`, `uploadMedia` | Report CRUD + media |
| `wallet` | `getBalance`, `getTransactions`, `stake`, `unstake` | MULTA token wallet |
| `user` | `getProfile`, `updateProfile`, `getAchievements` | User management |
| `cities` | `list`, `get`, `getNearby` | City and jurisdiction info |

## Pre-built UI Components

Drop-in screens that handle the full user flow:

| Component | Description |
|-----------|-------------|
| `ReportFlow` | 3-step report creation wizard (photo, location, details) |
| `ReportList` | Paginated list with filters and search |
| `ReportDetail` | Full report view with evidence gallery and map |
| `WalletView` | Balance display, staking controls, transaction history |
| `LoginScreen` | Email/password + social login form |

## Configuration

```
MultandoSDK(
  apiKey:        String    // Required. Your developer API key
  environment:   Enum      // .production | .staging | .development
  locale:        String    // "en" | "es" (default: device locale)
  offlineMode:   Boolean   // Enable offline queue (default: true)
  theme:         Theme     // Custom colors, fonts (default: Multando brand #3b5eef)
)
```

## Project Structure

```
sdks/
  shared/           # OpenAPI spec, shared test fixtures
  flutter/          # Dart/Flutter SDK
  react-native/     # TypeScript React Native SDK
  ios/              # Swift iOS SDK
  android/          # Kotlin Android SDK
```

## API Reference

Full API documentation is available at the [Multando Developer Portal](https://developers.multando.com).

The OpenAPI specification used to generate SDK models is located in `shared/openapi.yaml`.

## License

All rights reserved. Proprietary software.
