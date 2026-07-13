# Image backend Mefali — multi-stage avec cargo-chef (layer caching, research.md R1).
# Contexte de build attendu : RACINE du dépôt (pour rust-toolchain.toml).
# Build sans base : SQLX_OFFLINE=true (cache backend/.sqlx commité).

FROM rust:1.97.0-slim-bookworm AS chef
RUN cargo install cargo-chef --version 0.1.77 --locked
WORKDIR /app

FROM chef AS planner
COPY rust-toolchain.toml ./rust-toolchain.toml
COPY backend/ ./
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
# ring (tls-rustls-ring) nécessite un compilateur C.
RUN apt-get update && apt-get install -y --no-install-recommends build-essential pkg-config \
    && rm -rf /var/lib/apt/lists/*
COPY rust-toolchain.toml ./rust-toolchain.toml
COPY --from=planner /app/recipe.json recipe.json
RUN cargo chef cook --release --recipe-path recipe.json
COPY backend/ ./
ENV SQLX_OFFLINE=true
RUN cargo build --release --bin api --bin seed

FROM debian:bookworm-slim AS runtime
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY --from=builder /app/target/release/api /usr/local/bin/api
COPY --from=builder /app/target/release/seed /usr/local/bin/seed
# Seeds embarqués (les migrations sont embarquées DANS le binaire via sqlx::migrate!).
COPY backend/seeds /app/seeds
ENV SEED_DIR=/app/seeds
ENV APP_ENV=production
EXPOSE 8080
CMD ["api"]
