# Multando Android SDK

Kotlin Android SDK for integrating Multando's traffic-violation reporting flow,
secure capture, chat, and rewards into third-party apps.

```kotlin
MultandoSDK.initialize(
    context = applicationContext,
    config = MultandoConfig(
        apiKey = "pk_live_...",
        baseUrl = "https://api.multando.com",
        locale = "en-US",
    ),
)
```

## Responsible Reporting Principles

Multando is a reporting platform, not an accusation platform. The SDK surfaces
the same principles the web product enforces so end users understand what they
are doing when they submit a report.

- **Reports document public behavior, not people.** Reporters flag observable
  conduct in public spaces.
- **Anonymity is preserved.** The reporter's identity is never shared with the
  reported party. Only authorities ever see identifying data, and only when
  their jurisdiction requires it.
- **Only authorities sanction.** The community can flag; a legal citation
  requires validation by the local authority.
- **Rate limits and plate cooldowns.** The backend enforces per-hour, per-day
  and per-plate caps to prevent harassment. When exceeded, the SDK throws
  `MultandoError.RateLimitException` or `MultandoError.PlateCooldownException`
  — both carry structured retry-after metadata.
- **Penalties for false reports.** Reports that are rejected reduce the
  reporter's points and reputation. When a user's rejection rate exceeds 30%
  the backend surfaces `rejectionRateWarning = true` on `UserProfile`.

Full details live at <https://multando.com/principles>.

### Surfacing the principles in your UI

Drop the `MultandoInfoButton` next to any report-submission affordance (the
bundled `ReportFormScreen` already embeds it):

```kotlin
Row(verticalAlignment = Alignment.CenterVertically) {
    Button(onClick = ::submit) { Text("Submit report") }
    MultandoInfoButton(primaryColor = Color(0xFFF97316))
}
```

Tapping the icon opens a ModalBottomSheet listing the five principles and a
"Learn more" button that opens `https://multando.com/principles` in the
browser. You can invoke the sheet directly via `PrinciplesBottomSheet(...)`.

### Handling structured 429s

```kotlin
try {
    reports.create(reportCreate)
} catch (e: MultandoError.RateLimitException) {
    // e.scope == RateLimitScope.HOUR | DAY
    // e.retryAfterSeconds
    showSnackbar(stringResource(R.string.multando_rate_limit_hour))
} catch (e: MultandoError.PlateCooldownException) {
    // e.plate, e.retryAfterHours
    showSnackbar(stringResource(R.string.multando_plate_cooldown))
}
```

### Rejection-rate warning

```kotlin
val profile = MultandoSDK.auth.me()
if (profile.rejectionRateWarning) {
    showBanner(stringResource(R.string.multando_rejection_rate_warning))
}
```

## Version

Current SDK version: **1.1.0** (see `MultandoSDK.VERSION`).
