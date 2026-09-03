# Tickerless

Tickerless turns real-world context into a path for discovering and interacting
with tokenized equities on Base.

## Architecture

The product resolves three kinds of input through one company-resolution engine:

```text
search / lens / link -> company -> equity -> tokenized asset -> Base
```

Development begins with the Rust API in `crates/tickerless-api`. The Flutter
client and Base contracts will be introduced in later phases.

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

Request an exact-decimal ownership quote:

```shell
curl 'http://127.0.0.1:8080/v1/companies/nvidia/quote?amount_usdc=9'
```

Quotes expose the selected asset and estimated fractional token amount. An asset
is only marked `actionable`/`executable` after both its token contract and market
addresses have been registered; seeded symbols alone never imply deployability.

Record the context that led to a company:

```shell
curl -X POST http://127.0.0.1:8080/v1/discoveries \
  -H 'content-type: application/json' \
  -d '{
    "company_slug":"meta",
    "method":"search",
    "source":"company behind Instagram",
    "explanation":"Instagram is associated with Meta Platforms.",
    "wallet_address":"0x0000000000000000000000000000000000000001"
  }'
```

Retrieve a wallet's discovery history:

```shell
curl 'http://127.0.0.1:8080/v1/discoveries?wallet_address=0x0000000000000000000000000000000000000001'
```

Run the project checks:

```shell
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
```

## Demo contracts

The Foundry project contains:

- `DemoToken`, an owner-minted ERC-20-compatible token used for test USDC and demo equities.
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
