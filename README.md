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

Start the development server:

```shell
cargo run -p tickerless-api
```

Check its health:

```shell
curl http://127.0.0.1:8080/health
```

Resolve a real-world query:

```shell
curl -X POST http://127.0.0.1:8080/v1/resolve/search \
  -H 'content-type: application/json' \
  -d '{"query":"who owns Instagram?"}'
```

The initial registry contains Apple, Meta Platforms, Alphabet, and NVIDIA. Only
assets explicitly present in the registry are returned as actionable.

Run the project checks:

```shell
cargo fmt --all --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo test --workspace --all-features
```
