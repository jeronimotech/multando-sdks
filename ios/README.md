# Multando iOS SDK

Swift package that embeds Multando's traffic-violation reporting flow into
third-party iOS apps. iOS 16+ / macOS 13+, SwiftUI-first.

```swift
.package(url: "https://github.com/multando/multando-ios-sdk", from: "1.1.0")
```

## Quick start

```swift
import MultandoSDK

let client = MultandoSDK.initialize(
    config: MultandoConfig(apiKey: "...", baseURL: "https://api.multando.com")
)

ReportFormView(client: client) { report in
    print("Created", report.id)
}
```

## Responsible Reporting Principles

Multando is a **reporting** platform — it documents public behavior so
authorities can decide what to do. Reports are not accusations, and the SDK
enforces a set of safeguards that every integrator must surface to the
end-user.

- **Statement.** Reports document public behavior, not people. Civic
  participation only works when it stays proportional.
- **Anonymity.** Reporter identity is never shared with the reported party.
  The backend exposes no path from a plate to a reporter.
- **Rate limits.** Submissions are capped per hour and per day. The same
  plate also has a cooldown window to block harassment. Breaches come back
  as typed ``MultandoError.rateLimitExceeded`` / ``.plateCooldown`` errors
  with `Retry-After` info.
- **Penalties.** Reports flagged as false reduce the reporter's points and
  reputation. A sustained rejection rate above 30% surfaces a warning
  (`UserProfile.rejectionRateWarning`).
- **Authority-only citations.** A legal citation always requires an
  authority's validation. The community can only flag, never accuse.

Full text: <https://multando.com/principles>.

### Surface the principles in your UI

Every report-submit surface must make the principles one tap away. The SDK
ships a drop-in component:

```swift
MultandoInfoButton(primaryColor: .orange)
```

It renders an `info.circle` affordance and opens a localized sheet with the
five bullets, an anonymity notice, and a "Learn more" link to the canonical
`/principles` page. `ReportFormView` embeds it automatically in the step
header; if you build your own submit screen, include it yourself.

### Localization

Bundled in `en` and `es`. Strings live in
`Sources/MultandoSDK/Resources/<locale>.lproj/Localizable.strings` and are
loaded through `Bundle.module`. Pull requests adding new locales are
welcome.

### Handling rate-limit errors

```swift
do {
    _ = try await client.reports.create(report)
} catch MultandoError.rateLimitExceeded(let retryAfter, let scope) {
    // scope == .hour or .day — surface the localized message.
} catch MultandoError.plateCooldown(let plate, let retryAfterHours) {
    // Ask the user whether this is genuinely a different incident.
}
```

## Version

`MultandoSDK.version` — currently `1.1.0` (adds responsible-reporting
safeguards, structured 429 errors, and `MultandoInfoButton`).
