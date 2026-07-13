-- Marqueur du jeu de démonstration (data-model.md §3).
-- Idempotent : re-jouable sans doublon (upsert d'une ligne unique).
-- Les données Tiassalé / vendeurs / articles arrivent avec les schémas des
-- cycles ZON / CPT / VND / TRF (fichiers NN_<module>.sql ajoutés alors).

CREATE SCHEMA IF NOT EXISTS demo;

CREATE TABLE IF NOT EXISTS demo.marqueur (
    cle        text        PRIMARY KEY,
    charge_le  timestamptz NOT NULL DEFAULT now()
);

INSERT INTO demo.marqueur (cle) VALUES ('jeu_demo')
ON CONFLICT (cle) DO UPDATE SET charge_le = now();
