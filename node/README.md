# @multando/node

Official Node.js client for the Multando API. Zero runtime dependencies -- uses native `fetch` (Node 18+).

## Installation

```bash
npm install @multando/node
```

## Quick start

```typescript
import { MultandoClient } from '@multando/node';

const client = new MultandoClient({ apiKey: 'mult_live_xxx' });
await client.login('user@example.com', 'password');

const infractions = await client.infractions.list();
const report = await client.reports.create({
  infraction_id: 1,
  plate_number: 'ABC123',
  latitude: 4.711,
  longitude: -74.072,
  description: 'Parked in no-parking zone',
});
console.log(`Report: ${report.short_id}`);
```

## Services

| Service | Methods |
|---------|---------|
| `client.auth` | `register`, `login`, `socialLogin`, `refresh`, `me`, `logout` |
| `client.reports` | `create`, `list`, `get`, `getByPlate`, `delete` |
| `client.infractions` | `list`, `get` |
| `client.wallet` | `balance`, `activities` |

## Error handling

```typescript
import { AuthenticationError, RateLimitError } from '@multando/node';

try {
  await client.reports.list();
} catch (err) {
  if (err instanceof AuthenticationError) {
    // Re-authenticate
  } else if (err instanceof RateLimitError) {
    console.log(`Retry after ${err.retryAfter}s`);
  }
}
```

## License

BSL 1.1 -- see [LICENSE](./LICENSE).
