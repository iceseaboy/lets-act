# Optional script understanding service

The native app performs OCR, PDF extraction, TTS, speech recognition, line matching and progress locally. This service receives **only adult-approved script text** and returns a proposed structure. The app still requires a separate director review before practice.

## Private pilot setup

Requires Node.js 22+. There are no npm dependencies.

```sh
cp server/.env.example server/.env
# Fill OPENAI_API_KEY, OPENAI_MODEL, PARSER_ACCESS_TOKEN in server/.env.
# Generate the service token with: openssl rand -hex 32
node --env-file=server/.env server/src/server.mjs
```

Place the service behind an HTTPS reverse proxy, forwarding `/v1/parse` to `127.0.0.1:8787`. The iOS app deliberately rejects HTTP and redirects. Set a 150 KB request body limit at the proxy too. Do not log request bodies, authorization headers or provider responses.

In the app, enter the HTTPS origin and **service access token** under Director → Private parsing service. The OpenAI provider key stays on the server. Import text, then choose “Understand script with AI” and confirm the specific upload. Local parsing remains available if the provider is unavailable or its output fails validation.

`OPENAI_MODEL` is explicitly configured, not silently upgraded. `.env.example` uses `gpt-4.1-mini` as a structured-output example; verify model access for your account. The implementation uses [Responses structured outputs](https://developers.openai.com/api/docs/guides/structured-outputs) with a strict schema and `store: false`. This does not by itself guarantee zero provider retention; configure the provider and disclose applicable retention before production use.

## Request / response

`POST /v1/parse`, Bearer token, JSON:

```json
{"text":"SCENE 1: Garden\nLUNA: Hello!","consent":true}
```

Response schema is in `src/schema.mjs`: scenes, characters, units, and alias suggestions. Supported unit types match the product spec. Both backend and app validate foreign keys. Malformed model structures get at most one retry; refusals, incomplete output, and provider failures are surfaced without exposing provider responses.

Limits: 30,000 text characters, 150,000 HTTP bytes, 3,000 units, two concurrent requests, ten requests per minute per service instance. The process stores no scripts. Only transient request data and quota timestamps exist in memory.

## Production boundary

This shared-token service is suitable for a private development/pilot installation. Before distributing a public App Store build, replace shared pilot credentials with per-installation/account authorization, revocation, per-user quotas and shared rate-limit storage; configure provider retention, budget controls, hosting and the privacy disclosure for your deployment. None of these credentials or services have been provisioned by this repository.

```sh
node --test server/test/*.test.mjs
```

Tests use an injected provider stub and never make paid model calls. A real provider smoke test remains necessary once server credentials exist.
