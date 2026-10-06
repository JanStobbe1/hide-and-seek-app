# Backend foundation

This directory contains the first production-backend foundation for Verstobbertje.

## Chosen direction

The app is already deployed through Cloudflare Workers, so the backend uses:

- Cloudflare Worker for the HTTP API
- Cloudflare D1 for durable game, player, signal and audit data
- profile names as the default player identity
- no raw personal data in the game tables
- explicit audit records for every administrator action
- server-side event ingestion as the source for anomaly detection

This is deliberately a foundation. Authentication, rate limits, event signatures and the player Flutter client are separate follow-up steps and must be added before exposing the API publicly.

## Database

Apply the migration with:

```sh
wrangler d1 migrations apply verstobbertje --config backend/wrangler.jsonc
```

Copy `backend/wrangler.example.jsonc` to a local `wrangler.jsonc`, fill in the D1 database id and keep credentials in Cloudflare/GitHub secrets.

## API foundation

- `GET /admin` — management dashboard; sign in with `ADMIN_API_TOKEN`.
- `GET /api/admin/analytics` — aggregate user, participation and feedback report.
- `POST /api/v1/games/:id/complete` — records an extended completed participation.
- `POST /api/v1/feedback` — records a milestone rating/topic or a skip.

- `GET /api/health`
- `GET /api/v1/games/:id`
- `POST /api/v1/games/:id/events`
- `GET /api/admin/dashboard`
- `GET /api/admin/signals`
- `POST /api/admin/signals/:id/review`
- `POST /api/admin/games/:id/pause`
- `POST /api/admin/games/:id/stop`
- `POST /api/admin/players/:id/block`

Player sessions are issued by `POST /api/v1/auth/player` and are signed with the Worker secret `PLAYER_TOKEN_SECRET`. Game events require that player bearer token and reject a mismatching player id.\n\nAdmin routes require the `Authorization: Bearer` header and the Worker secret `ADMIN_API_TOKEN`. Configure both with `wrangler secret put`; never commit them in `wrangler.jsonc`. This is only a temporary bootstrap guard; replace it with proper administrator authentication before production use.

## Production deployment

The backend deployment is intentionally manual through
`.github/workflows/deploy-backend.yml`. Configure these GitHub Actions secrets in the
`production` environment before running it:

- `CLOUDFLARE_API_TOKEN`
- `CLOUDFLARE_ACCOUNT_ID`
- `D1_DATABASE_ID`
- `LIVE_APP_ORIGIN`
- `ADMIN_API_TOKEN`
- `PLAYER_TOKEN_SECRET`

The workflow applies the D1 migration, deploys the separate API Worker and then sets
the two Worker secrets. It does not run automatically on frontend pushes.

Production management page: https://verstobbertje-api.dry-leaf-6021.workers.dev/admin.
The dashboard accepts the admin token only in memory and shows aggregate activity, not locations or event contents. A completed participation qualifies after ten minutes from the later of joining or the scheduled game start. Feedback is requested at 2, 10 and 50 qualifying participations; account deletion removes linked feedback.


## Startmeldingen in de buurt

Browser-push werkt met een opt-in pushregistratie. De speler geeft expliciet toestemming voor browsermeldingen en locatie. De Worker bewaart een afgeronde locatie, woonplaats en push-endpoint om een startgebied in dezelfde stad of binnen de gekozen straal te matchen. Locatie- en pushgegevens worden verwijderd als de speler meldingen uitzet of het account verwijdert. Configureer de Worker secret `VAPID_PRIVATE_KEY` voordat pushinschrijving beschikbaar wordt. De publieke VAPID-sleutel staat in `wrangler.example.jsonc` en in de Flutter app-configuratie.
