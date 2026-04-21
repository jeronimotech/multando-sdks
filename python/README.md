# Multando Python Client

Official Python client for the [Multando API](https://multando.com/developers) -- typed HTTP wrappers for backend-to-backend integration.

## Installation

```bash
pip install multando
```

Requires Python 3.9+ and `httpx`.

## Quick start (async)

```python
from multando import MultandoClient

async with MultandoClient(api_key="mult_live_xxx") as client:
    await client.login("user@example.com", "password")

    # List available infraction types
    infractions = await client.infractions.list()

    # Submit a report
    report = await client.reports.create(
        infraction_id=1,
        plate_number="ABC123",
        latitude=4.711,
        longitude=-74.072,
        description="Parked in no-parking zone",
    )
    print(f"Report created: {report.short_id}")

    # Check wallet balance
    balance = await client.wallet.balance()
    print(f"MULTA balance: {balance.balance}")
```

## Quick start (sync)

```python
from multando import MultandoSyncClient

client = MultandoSyncClient(api_key="mult_live_xxx")
client.login("user@example.com", "password")

reports = client.reports.list()
for r in reports.items:
    print(r.short_id, r.status)

client.close()
```

## Services

| Service | Methods |
|---------|---------|
| `client.auth` | `register`, `login`, `social_login`, `refresh`, `me` |
| `client.reports` | `create`, `list`, `get`, `get_by_plate`, `delete` |
| `client.infractions` | `list`, `get` |
| `client.wallet` | `balance`, `activities` |

## Error handling

```python
from multando import MultandoError, AuthenticationError, RateLimitError

try:
    await client.reports.get("nonexistent")
except AuthenticationError:
    print("Bad credentials")
except RateLimitError as e:
    print(f"Rate limited, retry after {e.retry_after}s")
except MultandoError as e:
    print(f"API error {e.status_code}: {e.message}")
```

## License

BSL 1.1 -- see [LICENSE](LICENSE).
