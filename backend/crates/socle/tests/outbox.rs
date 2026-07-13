//! Tests d'intégration OBLIGATOIRES de l'outbox (constitution VII, plan T1–T3).
//! Chaque test tourne sur une base éphémère isolée (`#[sqlx::test]`), migrations
//! `backend/migrations` appliquées automatiquement.
//!
//!   cargo test -p socle --test outbox   (DATABASE_URL requis)

use std::collections::HashSet;
use std::sync::{Arc, Mutex};

use chrono::Utc;
use socle::outbox::{
    ecrire_evenement, ConsommateurOutbox, ConsommationError, EvenementPublie, NouvelEvenement,
    WorkerOutbox,
};
use sqlx::PgPool;
use uuid::Uuid;

fn evenement_test(entite_id: Uuid) -> NouvelEvenement<'static> {
    NouvelEvenement {
        type_evenement: "socle.ping",
        entite_type: "socle",
        entite_id,
        payload: serde_json::json!({ "test": true }),
        survenu_le: Utc::now(),
    }
}

/// Consommateur de test : compte les livraisons (avec doublons) et les effets
/// uniques (dédoublonnés par `id`). Peut échouer les N premières fois.
#[derive(Default)]
struct ConsommateurCompteur {
    vus: Mutex<Vec<Uuid>>,
    effets: Mutex<HashSet<Uuid>>,
    echecs_restants: Mutex<u32>,
}

impl ConsommateurCompteur {
    fn avec_echecs(n: u32) -> Self {
        Self {
            echecs_restants: Mutex::new(n),
            ..Default::default()
        }
    }
    fn nb_livraisons(&self) -> usize {
        self.vus.lock().unwrap().len()
    }
    fn nb_effets(&self) -> usize {
        self.effets.lock().unwrap().len()
    }
}

#[async_trait::async_trait]
impl ConsommateurOutbox for ConsommateurCompteur {
    fn nom(&self) -> &'static str {
        "compteur-test"
    }

    async fn consommer(&self, evenement: &EvenementPublie) -> Result<(), ConsommationError> {
        {
            let mut restants = self.echecs_restants.lock().unwrap();
            if *restants > 0 {
                *restants -= 1;
                return Err(ConsommationError("échec simulé".to_owned()));
            }
        }
        self.vus.lock().unwrap().push(evenement.id);
        self.effets.lock().unwrap().insert(evenement.id); // idempotent par id
        Ok(())
    }
}

async fn compter(pool: &PgPool, id: Uuid) -> i64 {
    sqlx::query_scalar("SELECT count(*) FROM outbox.evenement WHERE id = $1")
        .bind(id)
        .fetch_one(pool)
        .await
        .unwrap()
}

/// T1 — commit → événement présent ; rollback → absent.
#[sqlx::test(migrations = "../../migrations")]
async fn commit_present_rollback_absent(pool: PgPool) {
    let id_commit = {
        let mut tx = pool.begin().await.unwrap();
        let id = ecrire_evenement(&mut tx, evenement_test(Uuid::now_v7()))
            .await
            .unwrap();
        tx.commit().await.unwrap();
        id
    };
    assert_eq!(compter(&pool, id_commit).await, 1, "présent après commit");

    let id_rollback = {
        let mut tx = pool.begin().await.unwrap();
        let id = ecrire_evenement(&mut tx, evenement_test(Uuid::now_v7()))
            .await
            .unwrap();
        tx.rollback().await.unwrap();
        id
    };
    assert_eq!(
        compter(&pool, id_rollback).await,
        0,
        "absent après rollback"
    );
}

/// T2 — worker publie (`publie_le` renseigné) ; rejeu → zéro double effet.
#[sqlx::test(migrations = "../../migrations")]
async fn worker_publie_puis_rejeu_idempotent(pool: PgPool) {
    let id = {
        let mut tx = pool.begin().await.unwrap();
        let id = ecrire_evenement(&mut tx, evenement_test(Uuid::now_v7()))
            .await
            .unwrap();
        tx.commit().await.unwrap();
        id
    };

    let conso = Arc::new(ConsommateurCompteur::default());
    let worker = WorkerOutbox::new(pool.clone(), vec![conso.clone()]);

    assert_eq!(worker.traiter_un_lot().await.unwrap(), 1, "1 publié");
    let publie_le: Option<chrono::DateTime<Utc>> =
        sqlx::query_scalar("SELECT publie_le FROM outbox.evenement WHERE id = $1")
            .bind(id)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!(publie_le.is_some(), "publie_le renseigné");
    assert_eq!(conso.nb_effets(), 1);

    // Simule un crash entre publication et marquage : publie_le remis à NULL.
    sqlx::query("UPDATE outbox.evenement SET publie_le = NULL WHERE id = $1")
        .bind(id)
        .execute(&pool)
        .await
        .unwrap();

    assert_eq!(worker.traiter_un_lot().await.unwrap(), 1, "redélivré");
    assert_eq!(conso.nb_livraisons(), 2, "at-least-once : revu");
    assert_eq!(
        conso.nb_effets(),
        1,
        "zéro double effet (idempotent par id)"
    );
}

/// T3 — échec du consommateur : `tentatives`++, `derniere_erreur`, reprise au lot suivant.
#[sqlx::test(migrations = "../../migrations")]
async fn echec_incremente_tentatives_puis_reprise(pool: PgPool) {
    let id = {
        let mut tx = pool.begin().await.unwrap();
        let id = ecrire_evenement(&mut tx, evenement_test(Uuid::now_v7()))
            .await
            .unwrap();
        tx.commit().await.unwrap();
        id
    };

    let conso = Arc::new(ConsommateurCompteur::avec_echecs(1));
    let worker = WorkerOutbox::new(pool.clone(), vec![conso.clone()]);

    // 1er lot : échec → non publié, tentatives=1, derniere_erreur renseignée.
    assert_eq!(worker.traiter_un_lot().await.unwrap(), 0, "aucun publié");
    let (tentatives, publie_le, erreur): (i32, Option<chrono::DateTime<Utc>>, Option<String>) =
        sqlx::query_as(
            "SELECT tentatives, publie_le, derniere_erreur FROM outbox.evenement WHERE id = $1",
        )
        .bind(id)
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(tentatives, 1);
    assert!(publie_le.is_none());
    assert!(erreur.is_some(), "derniere_erreur renseignée");

    // 2e lot : reprise → succès.
    assert_eq!(
        worker.traiter_un_lot().await.unwrap(),
        1,
        "repris et publié"
    );
    let publie_le2: Option<chrono::DateTime<Utc>> =
        sqlx::query_scalar("SELECT publie_le FROM outbox.evenement WHERE id = $1")
            .bind(id)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!(publie_le2.is_some());
}
