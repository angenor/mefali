# OSRM — routage Côte d'Ivoire

Distances par itinéraire routier (constitution IV — jamais de vol d'oiseau hors
dégradé ×1,4 journalisé). OSRM `v26.7.3`, algorithme MLD.

## Préparation (obligatoire avant le premier démarrage)

```bash
infra/osrm/prepare.sh    # télécharge l'extrait + extract/partition/customize
docker compose -f infra/docker-compose.yml up -d osrm
```

Les fichiers `*.osm.pbf` et `*.osrm*` sont volumineux et **non commités**
(voir `.gitignore`).

## L'indisponibilité d'OSRM ne bloque rien

Le service `osrm` n'a **aucun `depends_on` entrant** : s'il n'a pas encore ses
données (ou plante), Postgres/Redis/Garage démarrent quand même, et le build/les
tests du backend passent (edge case de la spec). Le backend consommera `OSRM_URL`
dans les cycles suivants.
