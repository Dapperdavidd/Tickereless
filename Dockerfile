FROM rust:1.95-bookworm AS builder

WORKDIR /app
COPY Cargo.toml Cargo.lock rust-toolchain.toml ./
COPY crates ./crates
COPY migrations ./migrations
RUN cargo build --locked --release -p tickerless-api --bin tickerless-api

FROM debian:bookworm-slim AS runtime

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/tickerless-api /usr/local/bin/tickerless-api

ENV TICKERLESS_API_HOST=0.0.0.0
EXPOSE 8080
CMD ["tickerless-api"]
