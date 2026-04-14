# @multando/react-native-sdk

Official React Native SDK for the Multando traffic-violation reporting
platform. Ships auth, report submission, secure evidence capture,
infractions + vehicle-type catalogs, verification queue, blockchain /
MULTA token balances, and a set of drop-in React Native components.

## Install

```bash
npm install @multando/react-native-sdk
# peer deps
npm install react-native @react-native-async-storage/async-storage @react-native-community/netinfo
```

## Quick start

```tsx
import { MultandoProvider, ReportForm } from '@multando/react-native-sdk';

<MultandoProvider config={{ apiKey: 'YOUR_KEY', baseUrl: 'https://api.multando.com' }}>
  <ReportForm location={loc} infoLocale="es" onSuccess={handleSuccess} />
</MultandoProvider>;
```

## Responsible Reporting Principles

Multando is a civic-reporting platform, not a denunciation tool. The
backend enforces hard anti-harassment guarantees and every integrating
app **must** surface those guarantees to reporters before they submit.

- **Multando documents public behavior, not people.** Reports describe
  what happened in public space — they do not accuse individuals.
- **Reporter anonymity is a contract.** The identity of the person
  filing a report is never shared with the reported party. Public
  views of a report show an anonymized label (`reporterDisplayName`)
  such as `Reporter #4821`.
- **Rate limits + plate cooldowns prevent targeted harassment.** The
  backend caps reports per hour and per day, blocks duplicate reports
  of the same plate within a cooldown window, and caps global volume
  per plate. Those 429 responses surface as `RateLimitError` and
  `PlateCooldownError` — handle them and show the matching localized
  string (`rate_limit_hour`, `rate_limit_day`, `plate_cooldown`).
- **False reports carry real penalties.** When a user's rejection rate
  exceeds 30%, `User.rejectionRateWarning` becomes `true` and points
  / reputation are deducted from their profile.
- **Only authorities accuse.** Community reports can reach the
  `community_verified` and `authority_review` statuses, but a legal
  citation always requires validation by a licensed authority.

Full principles and governance: <https://multando.com/principles>

### Embedding the info button

Developers integrating the SDK **must** surface the responsible-
reporting principles in their report-submission UX. The fastest way is
to drop the `MultandoInfoButton` next to your header:

```tsx
import { MultandoInfoButton } from '@multando/react-native-sdk';

<View style={{ flexDirection: 'row', justifyContent: 'flex-end' }}>
  <MultandoInfoButton locale="es" primaryColor="#f97316" />
</View>;
```

`ReportForm` already embeds `MultandoInfoButton` in its header — pass
`infoLocale="es"` to localize it.

### Handling rate-limit errors

```ts
import {
  RateLimitError,
  PlateCooldownError,
  tResponsibleReporting,
} from '@multando/react-native-sdk';

try {
  await reports.create(payload);
} catch (err) {
  if (err instanceof PlateCooldownError) {
    alert(tResponsibleReporting('plate_cooldown', 'es'));
  } else if (err instanceof RateLimitError) {
    const key =
      err.scope === 'reports_per_day' ? 'rate_limit_day' : 'rate_limit_hour';
    alert(tResponsibleReporting(key, 'es'));
  }
}
```

### Rejection-rate warning

```ts
const { user } = useAuth();
if (user?.rejectionRateWarning) {
  alert(tResponsibleReporting('rejection_rate_warning', user.locale ?? 'en'));
}
```

## License

MIT
