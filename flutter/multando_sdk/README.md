# Multando Flutter SDK

Official Flutter SDK for the [Multando](https://multando.com) civic-reporting platform. Document infractions in public spaces, capture tamper-evident evidence, and integrate with the Multando API and MULTA token rewards.

```yaml
dependencies:
  multando_sdk: ^0.1.1
```

## Quick start

```dart
import 'package:multando_sdk/multando_sdk.dart';

final client = MultandoClient(
  config: MultandoConfig(
    apiKey: 'your-api-key',
    locale: 'es',
  ),
);
await client.initialize();
```

## Responsible Reporting Principles

Multando documents **public behavior in public spaces**, not individual people. Every integration of this SDK must surface these principles to end users:

- **Public behavior, not people.** Reports describe an infraction observed in a public space. They are not denunciations of individuals.
- **Reporter anonymity.** The identity of the reporter is never shared with the reported party. Backend endpoints strip identifying fields before exposing reports externally.
- **Authority validation.** A report is civic documentation. A legal *comparendo* (ticket) can only be issued after validation by the competent traffic authority.
- **Rate limits & plate cooldowns.** The API enforces hourly/daily report caps and plate-level cooldowns to prevent targeted harassment and coordinated pile-ons. The SDK surfaces these as `RateLimitException` and `PlateCooldownException`.
- **False reports penalize the reporter.** Rejected reports lower the reporter's reputation and reduce/void token rewards. Sustained abuse is signaled via `UserProfile.rejectionRateWarning`.

Full principles: <https://multando.com/principles>

### Surface the principles in your UI

Embed `MultandoInfoButton` next to any report-submission control:

```dart
Row(children: [
  const Text('Report infraction'),
  const MultandoInfoButton(locale: 'es'),
]);
```

The built-in `ReportForm` widget already embeds it next to the first-step title.

> **Developers integrating this SDK MUST surface these principles in their UI.** Failure to do so violates the Multando API Terms and may result in API-key revocation.

## Connect Multando (OAuth)

Let your users connect their Multando account to your app via OAuth 2.0. The user authorizes your app on multando.com, and you exchange the resulting code for an access token.

```dart
// 1. Build the authorize URL
final url = client.auth.buildAuthorizeUrl(
  redirectUri: 'myapp://multando-callback',
);

// 2. Open in browser (using url_launcher)
await launchUrl(Uri.parse(url));

// 3. Handle the callback in your app's deep link handler.
//    Extract 'code' from the callback URL query parameters.

// 4. Exchange the code for tokens
final tokens = await client.auth.exchangeOAuthCode(
  code: callbackCode,
  redirectUri: 'myapp://multando-callback',
);
// Done! The client is now authenticated as the user.
```

You can customise the requested scopes:

```dart
final url = client.auth.buildAuthorizeUrl(
  redirectUri: 'myapp://multando-callback',
  scope: 'reports:read,balance:read',
  state: 'my-csrf-token', // optional, recommended
);
```

## Handling rate limits

```dart
try {
  await client.reports.create(report);
} on RateLimitException catch (e) {
  // e.scope is RateLimitScope.hour or RateLimitScope.day
  // e.retryAfterSeconds tells you how long to back off
} on PlateCooldownException catch (e) {
  // e.plate, e.retryAfterHours
}
```

## License

See LICENSE.
