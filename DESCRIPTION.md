# OmniRoute — Self-hosted AI Gateway

[OmniRoute](https://github.com/diegosouzapw/OmniRoute) is a self-hosted AI gateway that connects **237+ AI providers** through one OpenAI-compatible endpoint.

## Features

- **237+ providers** — OpenAI, Anthropic, Gemini, DeepSeek, Groq, xAI, Mistral, and many more
- **90+ free tiers** — route through free provider accounts
- **Token compression** — RTK + Caveman engines cut token usage by 10-60%
- **Auto-fallback** — automatic provider switching on errors or quota exhaustion
- **MCP Server** — 94 tools for programmatic control
- **A2A Protocol** — agent-to-agent communication
- **Dashboard** — web UI for managing providers, combos, and settings
- **OpenAI-compatible API** — drop-in replacement for any OpenAI SDK

## Quick Start

1. Open the dashboard at your app URL
2. Add your API keys in the Providers tab
3. Create combos (routing rules) in the Combos tab
4. Use the endpoint `https://your-app.com/v1` with any OpenAI-compatible client

## Documentation

- [GitHub Wiki](https://github.com/diegosouzapw/OmniRoute/wiki)
- [Architecture](https://github.com/diegosouzapw/OmniRoute/blob/main/docs/architecture/ARCHITECTURE.md)
- [Provider List](https://github.com/diegosouzapw/OmniRoute/blob/main/docs/reference/PROVIDER_REFERENCE.md)
