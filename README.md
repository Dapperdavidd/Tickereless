# Tickerless

Tickerless turns real-world context into a path for discovering and interacting
with tokenized equities on Base.

[![CI](https://github.com/Dapperdavidd/Tickereless/actions/workflows/ci.yml/badge.svg)](https://github.com/Dapperdavidd/Tickereless/actions/workflows/ci.yml)

## Architecture

The product resolves three kinds of input through one company-resolution engine:

```text
search / lens / link -> company -> equity -> tokenized asset -> Base
```

Development begins with the Rust API in `crates/tickerless-api`. The Flutter
client lives in `apps/mobile`, and the demo Base contracts live in `contracts`.

## Run the mobile app

The Flutter client targets iOS and Android. Its current onboarding buttons all
enter the demo while authentication is intentionally deferred. Every ownership
surface is labeled as Base Sepolia and uses demo assets.

The frontend includes navigable Search, Lens, Link, Company Passport, purchase,
confirmation, Your World, Discovery History, and Profile experiences. The
screens currently use deterministic demo content while backend and wallet
integration are added in later slices.

```shell
cd apps/mobile
flutter pub get
flutter run
```

The app defaults to `http://127.0.0.1:8080` for iOS Simulator development.
Override the API origin for a physical device or Android emulator without
changing source code:

```shell
flutter run --dart-define=TICKERLESS_API_URL=http://10.0.2.2:8080
```

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
10–128 characters. Google authentication is intentionally left as the only
provider requiring external credentials.

Resolve a real-world query:

```shell
curl -X POST http://127.0.0.1:8080/v1/resolve/search \
  -H 'content-type: application/json' \
  -d '{"query":"who owns Instagram?"}'
```

The initial registry contains Apple, Meta Platforms, Alphabet, and NVIDIA. Only
assets explicitly present in the registry are returned as actionable.

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

Quotes expose the selected asset and estimated fractional token amount. An asset
is only marked `actionable`/`executable` after both its token contract and market
addresses have been registered; seeded symbols alone never imply deployability.

After the wallet broadcasts a market purchase, submit its transaction hash:

```shell
curl -X POST http://127.0.0.1:8080/v1/transactions \
  -H 'content-type: application/json' \
  -d '{
    "wallet_address":"0x0000000000000000000000000000000000000001",
    "company_slug":"nvidia",
    "tx_hash":"0x0000000000000000000000000000000000000000000000000000000000000000"
  }'
```

The API does not trust purchase amounts supplied by the client. It verifies the
chain ID, sender, market, asset, receipt status, `buy` calldata, and `Purchased`
event, then derives the USDC and token amounts from the confirmed transaction.
Transaction hashes are recorded once only.

Retrieve the wallet's personalized “Your World” view:

```shell
curl 'http://127.0.0.1:8080/v1/world?wallet_address=0x0000000000000000000000000000000000000001'
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
curl 'http://127.0.0.1:8080/v1/discoveries?wallet_address=0x0000000000000000000000000000000000000001'
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

## Demo contracts

The Foundry project contains:

- `DemoToken`, an owner-minted ERC-20-compatible token used for demo equities.
- `DemoPaymentToken`, a test USDC token that gives each demo wallet one self-service allocation.
- `TickerlessMarket`, a fixed-price market that exchanges six-decimal test USDC for fractional
  18-decimal demo equities with a caller-provided minimum output.
- A deployment script that creates tUSDC, tAAPLc, tNVDAc, tMETAc, and tGOOGLc, lists the four
  equities, and supplies market inventory.

These contracts represent demo assets only; they are not real securities. Run the contract gates
with:

```shell
forge fmt --check
forge build
forge test
forge lint
```

Deploy to a configured development RPC:

```shell
forge script contracts/script/Deploy.s.sol:DeployTickerless \
  --rpc-url "$BASE_SEPOLIA_RPC_URL" \
  --broadcast
```

After deployment, copy the returned addresses into the corresponding
`TICKERLESS_*_ADDRESS` values in `.env`, then register the complete deployment
atomically:

```shell
cargo run -p tickerless-api --bin register_deployment
```

The command validates every address, chain ID, and HTTPS explorer URL before
updating all four registry assets. Quotes and resolver results only become
executable/actionable after this registration succeeds.
