# OmniRoute — Cloudron Installation

## First Steps

1. **Open the dashboard** at `https://<your-domain>/`
2. **Set a password** — the first user becomes admin
3. **Add API keys** in the Providers tab
4. **Create combos** in the Combos tab to define routing rules

## Cloudron Addons

### Redis (Rate Limiter)

The Redis addon provides rate limiting. It's configured automatically.

### OIDC (Single Sign-On)

If you enabled the OIDC addon, Cloudron login appears on the OmniRoute dashboard. Users who authenticate via Cloudron are automatically created as OmniRoute users.

### Local Storage (SQLite)

Your database is persisted at `/app/data/storage.sqlite` and survives restarts.

## API Usage

Use the OpenAI-compatible endpoint:

```
Base URL: https://<your-domain>/v1
```

Example with the OpenAI SDK:

```python
import openai

client = openai.OpenAI(
    base_url="https://<your-domain>/v1",
    api_key="your-omniroute-api-key"
)

response = client.chat.completions.create(
    model="gpt-4o",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

## Troubleshooting

- **Rate limiter not working**: Check that Redis addon is enabled
- **Provider errors**: Verify API keys in the Providers tab
- **Slow responses**: Enable token compression in Settings
