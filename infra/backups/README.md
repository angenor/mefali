# Sauvegardes & restauration (TRX-04)

RPO ≤ 24 h, rétention 30 jours (SC-007). Perte maximale bornée à 24 h.

## Composants

| Élément | Rôle |
|---|---|
| `backup.sh` | `pg_dump \| age` → Backblaze B2 + sync Garage → B2 (rclone), rotation 30 j |
| `restore-test.sh` | Restaure la dernière archive chiffrée dans un Postgres jetable, vérifie le schéma |
| **Clé privée age** | Déchiffre les archives. **JAMAIS sur le VPS, JAMAIS dans Git** (gestionnaire de mots de passe + copie hors-ligne) |

## Clé de chiffrement (âge)

```bash
age-keygen -o mefali-backup.age-key        # génère la paire
# → clé PUBLIQUE (age1...) : BACKUP_AGE_RECIPIENT dans le .env du VPS
# → fichier PRIVÉ : conservé HORS VPS (coffre + copie hors-ligne)
```

Le VPS ne connaît que la clé **publique** : il peut chiffrer, pas déchiffrer.
Une compromission du VPS n'expose donc pas les sauvegardes.

## Immutabilité

Portée par le **bucket externe B2** (object lock + règle de cycle de vie 30 j),
**jamais** par Garage (research.md R7). Configurer côté B2 :
object lock activé + lifecycle « expire après 30 jours ».

## Planification (VPS)

Systemd timer quotidien (dépend de T028/US7 pour l'activation en prod) :

```ini
# /etc/systemd/system/mefali-backup.service
[Service]
Type=oneshot
EnvironmentFile=/srv/mefali/.env
ExecStart=/srv/mefali/backup.sh

# /etc/systemd/system/mefali-backup.timer
[Timer]
OnCalendar=*-*-* 02:30:00
Persistent=true
[Install]
WantedBy=timers.target
```

```bash
systemctl enable --now mefali-backup.timer
```

## Procédure de restauration complète (VPS → poste, AVANT la bêta)

1. **Récupérer** l'archive depuis B2 (`aws s3 cp --endpoint … s3://…/postgres/mefali-<stamp>.sql.age`).
2. **Déchiffrer** avec la clé privée age : `age -d -i mefali-backup.age-key -o dump.sql dump.sql.age`.
3. **Restaurer** dans un Postgres cible : `pg_restore -d <cible> dump.sql`.
4. **Basculer** l'application sur la base restaurée.

`restore-test.sh` automatise 1→3 contre un Postgres jetable (à lancer
régulièrement — une sauvegarde non testée n'est pas une sauvegarde). La
restauration RÉELLE de bout en bout est déroulée et documentée avant la bêta.
