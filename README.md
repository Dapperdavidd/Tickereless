# Tickerless

Tickerless turns real-world context into a path for discovering tokenized
equities on Solana.

[![CI](https://github.com/Dapperdavidd/Tickereless/actions/workflows/ci.yml/badge.svg)](https://github.com/Dapperdavidd/Tickereless/actions/workflows/ci.yml)

## Architecture

The product resolves three kinds of input through one company-resolution engine:

```text
search / lens / link -> company -> equity -> verified Solana instrument
```

The Rust API lives in `crates/tickerless-api` and the Flutter client lives in
`apps/mobile`. The old Base proof-of-concept contracts remain in `contracts`
for historical reference; they are not part of the active product path.

## Run the mobile app

The Flutter client targets iOS and Android. Email and Google authentication
create a stable, locally secured Solana wallet; guest mode remains discovery
only. Wallet transfers use Solana Devnet while real-equity execution remains
disabled until a compliant mainnet route is integrated. The UI does not mint or
pretend to purchase fake equity assets.

```shell
cd apps/mobile
flutter pub get
flutter run
```

The app defaults to the deployed Railway API at
`https://api-production-b1d0b.up.railway.app`. Override the API origin for
local development without changing source code:

```shell
flutter run --dart-define=TICKERLESS_API_URL=http://10.0.2.2:8080
```

For a physical iPhone or Android phone, put the phone and Mac on the same Wi-Fi,
then use the helper. It starts PostgreSQL (Homebrew or Docker) and the API, detects the Mac's local
address, waits for backend readiness, and configures the app automatically:

```shell
./scripts/run-device-demo.sh
```

In Zed, the same complete flow is available as the `Run Tickerless on iPhone`
task. Do not use a plain `flutter run` for a physical phone because its localhost
belongs to the phone rather than the Mac.

Cleartext HTTP is allowed only in Android debug builds; release builds retain
the platform's secure-network policy. iOS permits local-network development.

Run its local checks with:

```shell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

## Run the API

Requirements:

- Rust 1.95 or newer
- Docker, for the local PostgreSQL service

Start PostgreSQL:

```shell
docker compose up -d postgres
```

Create the local environment file and start the API. Database migrations and
registry seed data are applied automatically during startup:

```shell
cp .env.example .env
cargo run -p tickerless-api
```

Start the development server:

```shell
cargo run -p tickerless-api
```

Check its health:

```shell
curl http://127.0.0.1:8080/health
```

Readiness includes a live database check:

```shell
curl http://127.0.0.1:8080/ready
```

Create an email account and session:

```shell
curl -X POST http://127.0.0.1:8080/v1/auth/email/register \
  -H 'content-type: application/json' \
  -d '{"email":"demo@example.com","password":"a-secure-demo-password"}'
```

Email addresses are normalized and unique. Passwords are stored as salted
PBKDF2-HMAC-SHA256 hashes, never plaintext. Registration and login return a
random 30-day bearer token; only its SHA-256 hash is stored. Use that token with
`GET /v1/auth/me`, and revoke it with `POST /v1/auth/logout`. Passwords must be
10–128 characters.

To enable Google sign-in, set `GOOGLE_OAUTH_CLIENT_IDS` to the OAuth client ID
that issues the mobile ID token, or a comma-separated allowlist when iOS and
Android use different client IDs. Send the Google ID token to
`POST /v1/auth/google` as `{"id_token":"..."}`. The API validates the RS256
signature with Google's rotating public keys plus the issuer, audience, expiry,
verified-email, and stable subject claims before creating a Tickerless session.

Resolve a real-world query:

```shell
curl -X POST http://127.0.0.1:8080/v1/resolve/search \
  -H 'content-type: application/json' \
  -d '{"query":"who owns Instagram?"}'
```

The registry contains Apple, NVIDIA, Meta, Alphabet, Microsoft, Amazon, and
Tesla. Each maps to a verified xStocks mint on Solana mainnet. Spotify remains
discoverable but has no registered instrument.

Resolve companies mentioned by a public page:

```shell
curl -X POST http://127.0.0.1:8080/v1/resolve/link \
  -H 'content-type: application/json' \
  -d '{"url":"https://www.nvidia.com/en-us/"}'
```

Link fetching accepts HTTP(S) text pages up to one megabyte, does not follow
redirects, and rejects credentials, localhost, and non-public network targets.
Title matches are ranked as the primary subject; deduplicated body matches are
returned as mentions.

Resolve OCR text and labels produced by the mobile Lens:

```shell
curl -X POST http://127.0.0.1:8080/v1/resolve/image \
  -H 'content-type: application/json' \
  -d '{"text":"GeForce RTX","labels":["GPU","graphics card"]}'
```

The API bounds and deduplicates recognition signals before resolving them through
the same company registry used by Search and Link.

JSON endpoints require `content-type: application/json`, reject unknown fields,
and cap request bodies at 64 KiB. Payload errors use the same `{code, message}`
shape as application errors so clients can handle them consistently.

Request an exact-decimal ownership quote:

```shell
curl 'http://127.0.0.1:8080/v1/companies/nvidia/quote?amount_usdc=9'
```

Quotes use the issuer's public price endpoint and fall back to a cached price
when it is unavailable. A verified mint may be returned as `actionable`, but
quotes remain `executable: false` until the API has a supported swap route,
transaction builder, and confirmation verifier.

Mainnet execution will use Jupiter Swap V2. Create a server-side API key at
`https://portal.jup.ag` and set `JUPITER_API_KEY`; never place this key in the
Flutter app. The backend will request the order, the user's local wallet will
sign the returned transaction, and the backend will verify the confirmed swap
before recording ownership.

The transaction endpoint is intentionally closed during the migration:

```shell
curl -X POST http://127.0.0.1:8080/v1/transactions \
  -H 'content-type: application/json' \
  -d '{
    "wallet_address":"XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp",
    "company_slug":"nvidia",
    "tx_hash":"5VERIFIED_SOLANA_SIGNATURE"
  }'
```

It returns `execution_unavailable` rather than accepting an unverified purchase.
The endpoint will reopen only when it can derive the wallet, mint, USDC amount,
token amount, and confirmation status from a Solana transaction.

Retrieve the wallet's personalized “Your World” view:

```shell
curl 'http://127.0.0.1:8080/v1/world?wallet_address=XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp'
```

Only confirmed purchases contribute to ownership totals. Multiple purchases are
aggregated per company, while every associated search, Lens, and Link discovery
remains visible as the path from attention to ownership.

Record the context that led to a company:

```shell
curl -X POST http://127.0.0.1:8080/v1/discoveries \
  -H 'content-type: application/json' \
  -d '{
    "company_slug":"meta",
    "method":"search",
    "source":"company behind Instagram",
    "explanation":"Instagram is associated with Meta Platforms."
  }'
```

Retrieve a wallet's discovery history:

```shell
curl 'http://127.0.0.1:8080/v1/discoveries?wallet_address=XsbEhLAtcf6HdfpFZ5xEMdqW8nfAvcsP5bdudRLJzJp'
```

New discoveries are anonymous. Supplying a discovery ID with a verified purchase
links it to the transaction sender, preventing unverified callers from adding
history to arbitrary wallets.

Run the project checks:

```shell
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
```

## Legacy Base proof of concept

The Foundry project contains the earlier hackathon proof of concept:

- `DemoToken`, an owner-minted ERC-20-compatible token used for demo equities.
- `DemoPaymentToken`, a test USDC token that gives each demo wallet one self-service allocation.
- `TickerlessMarket`, a fixed-price market that exchanges six-decimal test USDC for fractional
  18-decimal demo equities with a caller-provided minimum output.
- A deployment script that creates tUSDC, tAAPLc, tNVDAc, tMETAc, tGOOGLc, and tMSFTc, lists the
  five equities, and supplies market inventory.

These contracts represent test assets only, are not real securities, and are no
longer used by the API or mobile app. They are retained so the project history
and contract tests remain reproducible. Run their checks with:

```shell
forge fmt --check
forge build
forge test
forge lint
```

Historical deployment addresses remain in `deployments/base-sepolia.json`.
They must not be configured as current assets or shown as real ownership.
