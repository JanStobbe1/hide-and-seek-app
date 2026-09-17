# Verstobbertje v0.1

## Product overview

Verstobbertje is the provisional name for a mobile-first, location-based hide-and-seek competition. This presentable Flutter prototype lets the persona **Arie** discover, join, create and simulate games entirely offline. The customer-facing interface is Dutch.

## Prototype scope

The prototype includes Home, Nieuw spel, Ik speel al mee met, Beschikbare spellen, Afgeronde spellen and Persoonlijke omgeving. It demonstrates game discovery and sorting, hierarchical local location selection, varied configuration-aware introduction copy, local joining/publishing, a countdown-driven active seeker experience, proximity and hider simulations, results, friends, profile customization, financial demo data and local privacy preferences.

Everything runs in **DEMO MODE**. There is no login, backend, Firebase, GPS, map provider, AI service, wallet, external sharing or payment. Monetary values are explicitly illustrative.

## Architecture

The UI observes a small `AppState`; it does not own prize or game transition logic. Domain models and rules are provider-agnostic. `GameRepository` is the seam for a future Firestore implementation; `MockGameRepository` owns deterministic local data. `FinancialService` owns prize-pool calculations and reads the single example fee value from `AppConfig`.

```text
lib/
├── config/             # configurable app name, demo flag, example platform fee
├── domain/             # models, value types and pure active-game transitions
├── services/           # repository contract and financial service
├── data/               # deterministic mock repository
├── presentation/       # responsive Material 3 screens and reusable widgets
├── app_state.dart      # local demo orchestration
└── main.dart
test/                   # finance, transition, event and repository tests
```

Future authentication, game, location, map and payment adapters should implement dedicated service contracts; server responses should populate the same domain models.

## Run Flutter Web

Install a current stable Flutter SDK, then:

```bash
flutter pub get
flutter run -d chrome
```

For a shareable local build:

```bash
flutter build web
python3 -m http.server 8080 --directory build/web
```

Open `http://localhost:8080`. Use a narrow browser viewport to see the intended mobile layout; at 800 px and wider the app switches to a navigation rail.

## Run Android or iOS later

If native platform folders are not present in a checkout, generate them without replacing `lib`:

```bash
flutter create --platforms=android,ios .
flutter run -d <device-id>
```

iOS builds require macOS/Xcode. Android requires the Android SDK and an emulator or device.

## Demo walkthrough

### Join and play

1. Open **Ontdekken** and select **MostEpicGameEver**.
2. Inspect the details, known players and mock-money disclosure; choose **Doe mee**.
3. Open **Mijn spellen** to verify the joined game.
4. Open **Game X** from Home, inspect the countdown and mock map, and tap **Simuleer speler binnen 5 meter**.
5. Choose **GEVONDEN** to move progress from 5 to 6. The separate hider-scenario button demonstrates the one-use invisibility action.
6. End the demo game to view the seeker result. It is then added to history and the played count increases.

The supplied primary scenario assigns Arie the seeker role. A hider warning/result concept is represented, but switching the entire active screen to a hider role is deliberately not presented as a production rule.

### Create a game

Choose **Nieuw spel**, adjust the prefilled Test123 settings and enter one or more mock countries, provinces, cities and neighbourhoods. Select either a configurable participant threshold or an editable mock date/time, then edit the introduction. The “AI” button inserts fixed local copy. Review the illustrative pool, publish, then open **Ontdekken** to see the locally added game with its selected area and start condition.

### Reset

Go to **Profiel → Demo beheren → Reset demo data**. This restores deterministic games, join state, active-game progress, statistics and privacy preferences. All settings remain local session state; restarting the app also restores the initial data.

## Mocked functionality

- identity and profile; all users and social relationships;
- map geometry, proximity, real location and visible-player indicators;
- game joins, creation, publishing, hints, questions, sharing and AI introduction;
- balances, entry fees, platform fee, prize pool and results;
- privacy persistence and all notifications.

The countdown itself now runs locally from the configured demo duration. Player
values use centralized `DemoPlayerValueRules`: seekers gain value for finds and
lose value gradually over time, while hiders gain value over time and as others
are found. These are illustrative prototype constants, not a finalized economy
or real-money payout calculation. Introduction generation is deterministic local
template variation, not an external AI call. Profile name, avatar, theme colour
and map marker are session-only selections; no photo file is uploaded or stored.

## Production functionality still required

A production backend must provide authentication, persistent storage, authorization, matchmaking, invitations, real-time state, push notifications, maps/location integration, verified payments/refunds, moderation, support, accessibility testing, analytics/consent and operational tooling. Locale-aware money/date formatting and offline conflict handling are also required.

## Production Security Considerations

**The mobile/web client must never be authoritative** for GPS validation, found-player events, winner determination, prize calculations, payment status, game start/end or results. Those decisions belong to a trusted server.

- Detect GPS spoofing and OS mock-location signals, but treat client signals only as risk inputs.
- Validate timestamps, accuracy and impossible movement/speed server-side; compare event and location histories.
- Rooted/jailbroken-device detection can inform risk scoring but cannot be the only control.
- Require short-lived authenticated API authorization with per-game and per-action access checks.
- Apply user/device/IP rate limiting and idempotency to proximity, found, joining and payment endpoints.
- Execute versioned game rules, role assignment, clocks, winner selection and prize calculations on the server.
- Verify payment-provider webhooks cryptographically; never trust a client-reported paid or withdrawn state.
- Maintain tamper-resistant audit/event logs for location evidence, rule decisions, administrative actions and financial reconciliation, with privacy-minded retention.

## Suggested Firebase/backend architecture

Firebase Authentication could supply identity, Firestore could store profiles/game read models, Cloud Functions or Cloud Run could run authoritative commands, and FCM could deliver proximity/game events. Sensitive location samples should use least-privilege access and short retention. A payment provider should be called only from server code with webhook verification. An append-only event/audit stream can feed derived game views. Maps should be behind a `MapService`, and live position collection behind a consent-aware `LocationService`.

## Assumptions and open product questions

- Dates use a fixed demo year so the flow remains deterministic; production scheduling needs time-zone policy.
- One seeker per approximately six participants, surviving hiders and the top seeker are configurable rule concepts, not a finalized winner algorithm.
- The 10% fee is an illustrative configurable default, not commercial or legal advice.
- Exact hint costs/rewards, question mechanics, invisibility duration, proximity evidence and tie-breaking remain open.
- Privacy settings are not persisted in v0.1. Age eligibility, safeguarding, location visibility and retention require product/legal decisions.
- “Paid out” and balance values are mock labels only; no custody or transfer occurs.

## Recommended v0.2 scope

Validate the rules and safety model first; then add a fake-server boundary with persisted demo sessions, complete the hider role journey, add widget/golden accessibility tests, introduce localization infrastructure, prototype consent-based location streams, and define versioned command/event APIs before selecting production providers.
