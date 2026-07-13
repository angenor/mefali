# Infra Mefali

| Dossier | Contenu |
|---|---|
| `docker-compose.yml` | Environnement de dev (Postgres, Redis, Garage, OSRM) |
| `garage/` | `garage.toml` (mono-nœud) + `init.sh` (layout, buckets, clés) |
| `osrm/` | `prepare.sh` (extrait Geofabrik + pipeline MLD) |
| `vps/` | `provision.sh`, `compose.prod.yml`, `Caddyfile` (production, US7) |
| `backups/` | `backup.sh`, `restore-test.sh`, procédure (TRX-04) |
| `.env.example` | Contrat du `.env` (data-model.md §4) |

Démarrage dev : `docker compose -f infra/docker-compose.yml up -d`
(voir `README.md` racine et `specs/001-socle-monorepo/quickstart.md`).

## Observabilité (TRX-03)

- **Logs** : JSON structurés + request id (tracing / tracing-actix-web) → `docker logs`.
- **Erreurs** : Sentry SaaS (plan Developer gratuit). `SENTRY_DSN` dans le `.env`
  du VPS (jamais commité) ; vide en dev = désactivé.
- **Sonde uptime** (détection < 2 min, SC-006) — à enregistrer une fois la prod en ligne :
  - **cron-job.org** : check `https://<domaine>/health` **1×/min**, alerte e-mail
    échec **et** rétablissement (détecteur principal < 2 min).
  - **Better Stack (free)** : check 3 min, alertes e-mail + push mobile, status page.

  **Test réel à documenter** : arrêter le service > 2 min (`docker compose … stop api`)
  → alerte reçue ; redémarrer → notification de rétablissement.

## Digests des images tierces (prod)

`compose.prod.yml` doit épingler Garage et Caddy **par digest** (research.md R5) :

```bash
docker buildx imagetools inspect dxflrs/garage:v2.3.0   # → @sha256:…
docker buildx imagetools inspect caddy:2                # → @sha256:…
```
