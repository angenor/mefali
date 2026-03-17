# Story 1.3: Docker Compose Infrastructure

Status: done

---

## Story

En tant que **developpeur**,
Je veux **un Docker Compose avec API, PostgreSQL, Redis, MinIO et Caddy**,
Afin que **le stack complet tourne en local avec une seule commande**.

## Criteres d'Acceptation

1. **AC1**: Un fichier `.env` avec ports configurables (API:8090, PG:5433, Redis:6380, MinIO:9000) est present et documente
2. **AC2**: `docker compose up` demarre les 5 services sur les ports configures
3. **AC3**: La console MinIO est accessible via navigateur (port 9001)
4. **AC4**: L'API Rust (crate `api`) se build et demarre dans son container, endpoint `/api/v1/health` retourne 200
5. **AC5**: PostgreSQL accepte les connexions sur le port configure et la base `mefali` existe
6. **AC6**: Redis repond a `PING` sur le port configure
7. **AC7**: Caddy sert de reverse proxy vers l'API avec HTTPS local (self-signed ou dev mode)
8. **AC8**: Les donnees PostgreSQL, Redis et MinIO persistent entre `docker compose down` et `up` (volumes nommes)
9. **AC9**: Un fichier `docker-compose.prod.yml` (override) est prepare avec limites de ressources et restart policies

## Taches / Sous-taches

- [x] **T1** Creer `.env` et `.env.example` a la racine du projet (AC: #1)
  - [x] T1.1 Definir toutes les variables (ports, credentials, URLs internes)
  - [x] T1.2 Ajouter `.env` au `.gitignore` (verifier qu'il n'est pas deja committe)
- [x] **T2** Creer `docker-compose.yml` avec les 5 services (AC: #2, #3, #4, #5, #6, #7)
  - [x] T2.1 Service `postgres` avec healthcheck et volume nomme
  - [x] T2.2 Service `redis` avec healthcheck et volume nomme
  - [x] T2.3 Service `minio` avec healthcheck, volume nomme, et console exposee
  - [x] T2.4 Service `api` avec Dockerfile multi-stage pour le Rust backend
  - [x] T2.5 Service `caddy` avec Caddyfile pour reverse proxy
  - [x] T2.6 Reseau Docker interne `mefali-net`
- [x] **T3** Creer `server/Dockerfile` multi-stage (AC: #4)
  - [x] T3.1 Stage builder: cargo build --release dans un container Rust
  - [x] T3.2 Stage runtime: image minimale (debian-slim) avec le binaire
  - [x] T3.3 Copier `.env` ou passer les vars via Docker Compose environment
- [x] **T4** Creer `Caddyfile` pour reverse proxy (AC: #7)
  - [x] T4.1 Route `/api/*` vers le service `api:8080`
  - [x] T4.2 Mode dev : HTTPS local auto-signe par Caddy
- [x] **T5** Configurer les volumes nommes pour persistance (AC: #8)
  - [x] T5.1 `postgres_data`, `redis_data`, `minio_data` (+ caddy_data, caddy_config)
- [x] **T6** Creer `docker-compose.prod.yml` override (AC: #9)
  - [x] T6.1 Limites CPU/memoire par service
  - [x] T6.2 `restart: unless-stopped` sur tous les services
  - [x] T6.3 Caddy avec Let's Encrypt (domaine reel via CADDY_DOMAIN)
- [x] **T7** Script d'initialisation MinIO (AC: #3)
  - [x] T7.1 Creer le bucket `mefali-files` au demarrage (service minio-init ephemere)
- [x] **T8** Tester le cycle complet (AC: tous)
  - [x] T8.1 `docker compose up -d` → 5 services healthy verifies
  - [x] T8.2 `curl http://localhost:8090/api/v1/health` → 200 OK
  - [x] T8.3 `docker compose down && docker compose up -d` → donnees PostgreSQL persistantes verifiees

## Dev Notes

### Architecture des services

```
                    ┌──────────┐
       :80/:443     │  Caddy   │
  ◄────────────────►│ (proxy)  │
                    └────┬─────┘
                         │ :8080
                    ┌────▼─────┐
                    │   API    │ :8090 (host)
                    │ (Actix)  │
                    └──┬──┬──┬─┘
              ┌────────┘  │  └────────┐
         :5432│      :6379│      :9000│
        ┌─────▼──┐ ┌──────▼─┐ ┌──────▼──┐
        │Postgres│ │ Redis  │ │  MinIO  │
        │  :5433 │ │  :6380 │ │  :9000  │
        │ (host) │ │ (host) │ │ (host)  │
        └────────┘ └────────┘ └─────────┘
```

- Les services communiquent entre eux via le reseau Docker (`mefali-net`) sur les ports standard internes (5432, 6379, 9000, 8080)
- Seuls les ports host sont remappes via `.env` pour eviter les conflits

### Variables d'environnement requises

Reprendre et etendre le `.env.example` existant dans `server/`. Le nouveau `.env` racine doit contenir:

```env
# === PostgreSQL ===
POSTGRES_USER=mefali
POSTGRES_PASSWORD=mefali
POSTGRES_DB=mefali
PG_PORT=5433

# === Redis ===
REDIS_PORT=6380

# === MinIO ===
MINIO_ROOT_USER=mefali
MINIO_ROOT_PASSWORD=mefali_secret
MINIO_PORT=9000
MINIO_CONSOLE_PORT=9001
MINIO_BUCKET=mefali-files

# === API ===
API_PORT=8090

# === URLs internes Docker (utilises par le container api) ===
DATABASE_URL=postgres://mefali:mefali@postgres:5432/mefali
REDIS_URL=redis://redis:6379
MINIO_ENDPOINT=http://minio:9000
MINIO_ACCESS_KEY=mefali
MINIO_SECRET_KEY=mefali_secret

# === JWT ===
JWT_SECRET=dev-secret-change-in-prod
JWT_ACCESS_EXPIRY=900
JWT_REFRESH_EXPIRY=604800

# === Logging ===
RUST_LOG=info,api=debug

# === Caddy ===
CADDY_DOMAIN=localhost
```

**ATTENTION** : Les URLs internes (`DATABASE_URL`, `REDIS_URL`, `MINIO_ENDPOINT`) utilisent les noms de service Docker (pas `localhost`) et les ports internes standard (5432, 6379, 9000). Le `server/.env.example` existant utilise `localhost` avec ports remappes — c'est pour le dev sans Docker. Ne pas confondre.

### Healthchecks par service

| Service    | Type    | Commande                                    | Interval | Timeout | Retries |
|------------|---------|---------------------------------------------|----------|---------|---------|
| PostgreSQL | CMD     | `pg_isready -U mefali`                      | 10s      | 5s      | 5       |
| Redis      | CMD     | `redis-cli ping`                            | 10s      | 5s      | 5       |
| MinIO      | HTTP    | `curl -f http://localhost:9000/minio/health/live` | 10s | 5s      | 5       |
| API        | HTTP    | `curl -f http://localhost:8080/api/v1/health`     | 10s | 5s      | 5       |

### Dockerfile multi-stage (`server/Dockerfile`)

```dockerfile
# Stage 1: Build
FROM rust:1.85-slim AS builder
WORKDIR /app
COPY Cargo.toml Cargo.lock ./
COPY crates/ crates/
RUN cargo build --release --bin api

# Stage 2: Runtime
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y ca-certificates curl && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/api /usr/local/bin/api
EXPOSE 8080
CMD ["api"]
```

Points critiques:
- `curl` requis dans l'image runtime pour les healthchecks
- `ca-certificates` requis pour les appels HTTPS sortants (CinetPay futur)
- Le binaire ecoute sur `8080` (port interne), mappe vers `${API_PORT}` sur l'hote
- Pas de `.env` copie dans l'image — les vars passent via `environment:` ou `env_file:` dans le compose

### Caddyfile

```caddyfile
{$CADDY_DOMAIN:localhost} {
    reverse_proxy /api/* api:8080
    # Future: reverse_proxy /minio/* minio:9000
}
```

En dev local, Caddy genere un certificat auto-signe pour `localhost`. En prod, remplacer `CADDY_DOMAIN` par le vrai domaine pour Let's Encrypt auto.

### Initialisation du bucket MinIO

Option recommandee : service `minio-init` ephemere dans le compose:

```yaml
minio-init:
  image: minio/mc
  depends_on:
    minio:
      condition: service_healthy
  entrypoint: >
    /bin/sh -c "
    mc alias set local http://minio:9000 $${MINIO_ROOT_USER} $${MINIO_ROOT_PASSWORD} &&
    mc mb --ignore-existing local/$${MINIO_BUCKET}
    "
```

### Contrainte MinIO : `force_path_style`

Le code Rust existant dans `server/crates/infrastructure/src/storage/mod.rs` utilise deja `force_path_style(true)` pour MinIO. C'est obligatoire car MinIO n'utilise pas les virtual-hosted buckets.

### Project Structure Notes

Fichiers a creer/modifier:

```
mefali/                          (racine du projet)
├── .env.example                 # CREER — template avec toutes les variables
├── .env                         # CREER (gitignore) — copie locale
├── docker-compose.yml           # CREER — dev config
├── docker-compose.prod.yml      # CREER — prod overrides
├── Caddyfile                    # CREER — reverse proxy config
├── .gitignore                   # MODIFIER — ajouter .env si absent
└── server/
    ├── Dockerfile               # CREER — multi-stage Rust build
    ├── .dockerignore            # CREER — exclure target/, .git
    └── .env.example             # EXISTE — ne pas modifier (dev sans Docker)
```

**NE PAS** deplacer ou modifier les fichiers existants dans `server/`. Le `server/.env.example` reste pour le dev hors Docker.

### Patterns etablis par les stories precedentes (1.1 & 1.2)

- **Config Rust** : `AppConfig::from_env()` dans `common/src/config.rs` — charge `dotenvy::dotenv().ok()` puis lit les env vars. Variables requises : `DATABASE_URL`, `REDIS_URL`, `MINIO_*`. Optionnelles avec defaults : `API_HOST` (0.0.0.0), `API_PORT` (8090).
- **Port interne API** : Le `main.rs` bind sur `API_HOST:API_PORT`. Dans Docker, mettre `API_PORT=8080` dans l'environment du service (port interne), mapper vers `${API_PORT}` sur l'hote.
- **Infrastructure clients** : `create_pool()` (PgPool, max_connections=10), `create_connection()` (Redis ConnectionManager async), `create_s3_client()` (force_path_style=true)
- **Health endpoint** : `GET /api/v1/health` retourne `{"data":{"status":"ok"}}` (1 test existant dans `api/src/routes/health.rs`)
- **Logging** : `tracing-subscriber` avec format JSON, filtre via `RUST_LOG`. Pas de `println!`.
- **Erreurs** : `AppError` enum avec `ResponseError` impl → JSON `{"error":{"code":"...","message":"...","details":null}}`

### Anti-patterns a eviter

- **NE PAS** utiliser `localhost` dans les URLs Docker internes — utiliser les noms de service (`postgres`, `redis`, `minio`)
- **NE PAS** hardcoder les ports — tout via `.env` et interpolation `${VAR}`
- **NE PAS** copier `.env` dans les images Docker — passer via `env_file:` dans le compose
- **NE PAS** utiliser `latest` pour les images Docker — fixer les versions majeures (postgres:16, redis:7, minio/minio:latest est OK car pas de breaking changes frequents)
- **NE PAS** creer de volume pour `target/` Rust dans le container — le build multi-stage s'en charge
- **NE PAS** exposer PostgreSQL/Redis sur l'interface publique en prod — seulement via le reseau Docker interne

### References

- [Source: _bmad-output/planning-artifacts/architecture.md] Infrastructure stack, ports, deployment
- [Source: _bmad-output/planning-artifacts/epics.md] Epic 1 Story 1.3 acceptance criteria
- [Source: _bmad-output/planning-artifacts/prd.md] NFR20 (uptime 99%), NFR25 (backup quotidien), NFR8 (TLS 1.2+)
- [Source: server/.env.example] Configuration existante du backend Rust
- [Source: server/crates/infrastructure/src/] Clients PostgreSQL, Redis, MinIO existants
- [Source: server/crates/api/src/main.rs] Point d'entree Actix, binding sur API_HOST:API_PORT
- [Source: server/crates/common/src/config.rs] AppConfig::from_env() avec parse_or_default

## Dev Agent Record

### Agent Model Used

Claude Opus 4.6 (1M context)

### Debug Log References

- Dockerfile initialement avec `rust:1.85-slim` → echec build car dependances necessitent >= 1.91.1 (actix-web 4.13, aws-sdk-s3 1.119). Corrige vers `rust:1.93-slim` (version locale).
- Ajout de `pkg-config` et `libssl-dev` dans le stage builder pour la compilation de `aws-lc-sys`.

### Completion Notes List

- AC1: `.env.example` et `.env` crees a la racine avec toutes les variables documentees (ports, credentials, URLs internes Docker)
- AC2: `docker compose up` demarre 5 services + minio-init (6 containers) sur ports configures
- AC3: Console MinIO accessible sur port 9001, bucket `mefali-files` cree automatiquement via service ephemere `minio-init`
- AC4: API Rust builde en multi-stage (rust:1.93-slim → debian:bookworm-slim), `/api/v1/health` retourne 200
- AC5: PostgreSQL accepte connexions sur port 5433, base `mefali` existe et fonctionne
- AC6: Redis repond `PONG` sur port 6380
- AC7: Caddy reverse proxy HTTPS auto-signe vers `api:8080`, retourne 200 via `https://localhost/api/v1/health`
- AC8: Donnees PostgreSQL persistent apres `docker compose down` / `up` (verifie avec table test)
- AC9: `docker-compose.prod.yml` cree avec limites CPU/memoire et `restart: unless-stopped`
- 30 tests Rust existants passent sans regression

### Change Log

- 2026-03-16: Implementation complete de l'infrastructure Docker Compose (Story 1.3)
- 2026-03-16: Code review — M1: ajout utilisateur non-root dans Dockerfile, M2: bind PG/Redis sur 127.0.0.1 (securite prod)

### File List

- .env.example (CREE)
- .env (CREE, gitignore)
- docker-compose.yml (CREE)
- docker-compose.prod.yml (CREE)
- Caddyfile (CREE)
- server/Dockerfile (CREE)
- server/.dockerignore (CREE)
