# Stage 1: Build
FROM rust:1.93-slim AS builder
WORKDIR /app
RUN apt-get update && apt-get install -y pkg-config libssl-dev && rm -rf /var/lib/apt/lists/*
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
RUN cargo build --release --bin api

# Stage 2: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/* \
    && useradd -r -s /bin/false mefali
COPY --from=builder /app/target/release/api /usr/local/bin/api
USER mefali
EXPOSE 8080
CMD ["api"]
