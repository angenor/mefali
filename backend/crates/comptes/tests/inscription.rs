//! Tests d'intégration du flux unique inscription/connexion (CPT-01, T007).
//!
//!   cargo test -p comptes --test inscription   (DATABASE_URL requis)
//!
//! Base éphémère par test (`#[sqlx::test]`), ports en mémoire : ce qui est
//! vérifié ici, ce sont les invariants qui vivent en BASE — atomicité de la
//! création, unicité du numéro, événements outbox écrits dans LA transaction
//! de la transition (constitution VI).

use std::sync::Arc;

use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

use comptes::inscription::IssueVerification;
use comptes::{
    Appareil, Comptes, ErreurComptes, MemoireEphemere, MemoireObjets, PgComptes, Plateforme, Role,
    SmsTraces, StatutRole,
};
use zones::{PgZones, TypeZone};

const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";
const SAISIE_LOCALE: &str = "0701020304";
const E164: &str = "+2250701020304";

/// Dépôt monté sur une zone Tiassalé minimale (indicatif hérité du pays), avec
/// des ports en mémoire.
struct Bac {
    depot: PgComptes,
    sms: Arc<SmsTraces>,
    zone: Uuid,
    pool: PgPool,
}

impl Bac {
    async fn nouveau(pool: PgPool) -> Self {
        let z = PgZones::new(pool.clone());
        let mut tx = pool.begin().await.unwrap();
        let pays = z
            .creer_zone(&mut tx, None, TypeZone::Pays, "Côte d'Ivoire")
            .await
            .unwrap()
            .id;
        let ville = z
            .creer_zone(&mut tx, Some(pays), TypeZone::Ville, "Tiassalé")
            .await
            .unwrap()
            .id;
        // Posé au PAYS, hérité par la ville — comme le seed 20_comptes.sql.
        z.definir_parametre(
            &mut tx,
            pays,
            "telephone.indicatif_defaut",
            json!("+225"),
            "test",
        )
        .await
        .unwrap();
        tx.commit().await.unwrap();

        let sms = Arc::new(SmsTraces::new());
        let depot = PgComptes::new(
            pool.clone(),
            Arc::new(MemoireEphemere::new()),
            sms.clone(),
            Arc::new(MemoireObjets::new()),
            Arc::from(SECRET),
        );
        Self {
            depot,
            sms,
            zone: ville,
            pool,
        }
    }

    fn appareil(&self) -> Appareil {
        Appareil {
            nom: "Pixel de test".to_owned(),
            plateforme: Plateforme::Android,
        }
    }

    /// Demande un code et renvoie celui qui est parti au SMS.
    async fn code(&self, saisie: &str) -> String {
        self.depot
            .demander_otp(self.zone, saisie, "1.2.3.4")
            .await
            .unwrap();
        self.sms.envoyes().last().unwrap().params["code"]
            .as_str()
            .unwrap()
            .to_owned()
    }

    /// Parcours complet jusqu'au compte créé.
    async fn inscrire(&self, saisie: &str) -> Uuid {
        let code = self.code(saisie).await;
        let issue = self
            .depot
            .verifier_otp(self.zone, saisie, &code, &self.appareil())
            .await
            .unwrap();
        let IssueVerification::ConsentementRequis { jeton_inscription } = issue else {
            panic!("un numéro inconnu doit exiger le consentement");
        };
        self.depot
            .inscrire(&jeton_inscription, "2026-07")
            .await
            .unwrap()
            .compte
            .id
    }

    async fn compter(&self, sql: &'static str) -> i64 {
        sqlx::query_scalar(sql).fetch_one(&self.pool).await.unwrap()
    }

    async fn evenements(&self, type_evenement: &str) -> Vec<serde_json::Value> {
        sqlx::query_scalar("SELECT payload FROM outbox.evenement WHERE type_evenement = $1")
            .bind(type_evenement)
            .fetch_all(&self.pool)
            .await
            .unwrap()
    }
}

/// FR-005/006 — la première vérification d'un numéro inconnu crée un compte
/// RÉDUIT au numéro, avec son consentement horodaté et son rôle client.
#[sqlx::test(migrations = "../../migrations")]
async fn inscription_cree_un_compte_reduit_au_numero(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte_id = bac.inscrire(SAISIE_LOCALE).await;

    let compte = bac.depot.compte(compte_id).await.unwrap();
    assert_eq!(compte.telephone_e164, E164, "numéro normalisé (R4)");
    assert_eq!(
        compte.zone_id, bac.zone,
        "rattaché à la zone de l'app (R13)"
    );
    assert_eq!(compte.consentement_version, "2026-07");
    assert!(
        compte.derniere_connexion_le.is_none(),
        "aucune reconnexion depuis la création"
    );

    // SC-008 — le consentement est horodaté, garanti par le schéma (NOT NULL).
    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.compte WHERE consentement_le IS NULL")
            .await,
        0
    );

    // FR-005 — le rôle client naît valide, et c'est le SEUL rôle.
    assert_eq!(
        bac.depot.roles_valides(compte_id).await.unwrap(),
        vec![Role::Client]
    );
    let attributions = bac.depot.attributions(compte_id).await.unwrap();
    assert_eq!(attributions.len(), 1);
    assert_eq!(attributions[0].statut, StatutRole::Valide);
    assert!(
        attributions[0].decide_par.is_none(),
        "attribution automatique — aucun décideur"
    );

    // La porte coursier est fermée : un client n'est pas un coursier (SC-005).
    assert!(!bac
        .depot
        .coursier_autorise_en_ligne(compte_id)
        .await
        .unwrap());
}

/// Constitution VI — les deux événements sont écrits dans LA transaction de la
/// transition, avec les payloads déclarés à la taxonomie (T004).
#[sqlx::test(migrations = "../../migrations")]
async fn inscription_emet_compte_cree_et_session_creee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte_id = bac.inscrire(SAISIE_LOCALE).await;

    let crees = bac.evenements("compte.cree").await;
    assert_eq!(crees.len(), 1);
    assert_eq!(crees[0]["zone"], json!(bac.zone));
    assert_eq!(
        crees[0]["role"], "client",
        "l'attribution client y est INCLUSE"
    );
    assert_eq!(crees[0]["consentement_version"], "2026-07");
    assert!(crees[0]["consentement_le"].is_string());
    // Minimisation ARTCI : aucun numéro dans le payload.
    assert!(
        !crees[0].to_string().contains(E164),
        "le payload ne doit porter aucune donnée nominative"
    );

    let sessions = bac.evenements("session.creee").await;
    assert_eq!(sessions.len(), 1);
    assert_eq!(sessions[0]["compte"], json!(compte_id));
    assert_eq!(sessions[0]["origine"], "inscription");
    assert_eq!(sessions[0]["appareil_plateforme"], "android");
}

/// FR-005 — le même numéro re-vérifié ouvre une SESSION, jamais un doublon.
#[sqlx::test(migrations = "../../migrations")]
async fn numero_connu_ouvre_une_session_sans_doublon(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte_id = bac.inscrire(SAISIE_LOCALE).await;

    let code = bac.code(SAISIE_LOCALE).await;
    let issue = bac
        .depot
        .verifier_otp(bac.zone, SAISIE_LOCALE, &code, &bac.appareil())
        .await
        .unwrap();

    let IssueVerification::Session(ouverte) = issue else {
        panic!("un numéro connu doit ouvrir une session, pas exiger un consentement");
    };
    assert_eq!(ouverte.compte.id, compte_id, "le MÊME compte");
    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.compte").await,
        1,
        "aucun doublon (FR-005)"
    );
    // Chaque appareil a sa session (FR-007).
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.session").await, 2);
    assert!(!ouverte.jetons.acces.is_empty());
    assert!(!ouverte.jetons.rafraichissement.is_empty());
}

/// La reconnexion met à jour `derniere_connexion_le` (data-model §2).
#[sqlx::test(migrations = "../../migrations")]
async fn reconnexion_met_a_jour_derniere_connexion(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let compte_id = bac.inscrire(SAISIE_LOCALE).await;
    assert!(bac
        .depot
        .compte(compte_id)
        .await
        .unwrap()
        .derniere_connexion_le
        .is_none());

    let code = bac.code(SAISIE_LOCALE).await;
    bac.depot
        .verifier_otp(bac.zone, SAISIE_LOCALE, &code, &bac.appareil())
        .await
        .unwrap();

    let compte = bac.depot.compte(compte_id).await.unwrap();
    let connexion = compte
        .derniere_connexion_le
        .expect("renseignée après une reconnexion");
    assert!(connexion >= compte.cree_le);
}

/// FR-006 — sans consentement, AUCUN compte n'est créé. Et le jeton n'est pas
/// brûlé : refuser la case ne doit pas coûter un nouveau SMS.
#[sqlx::test(migrations = "../../migrations")]
async fn sans_consentement_aucun_compte_et_jeton_preserve(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let code = bac.code(SAISIE_LOCALE).await;
    let IssueVerification::ConsentementRequis { jeton_inscription } = bac
        .depot
        .verifier_otp(bac.zone, SAISIE_LOCALE, &code, &bac.appareil())
        .await
        .unwrap()
    else {
        panic!("numéro inconnu attendu");
    };

    for vide in ["", "   "] {
        assert!(
            matches!(
                bac.depot.inscrire(&jeton_inscription, vide).await,
                Err(ErreurComptes::ConsentementRequis)
            ),
            "consentement « {vide} » doit être refusé"
        );
    }
    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.compte").await,
        0,
        "aucun compte créé sans consentement (FR-006)"
    );
    assert_eq!(
        bac.evenements("compte.cree").await.len(),
        0,
        "aucun événement : rien ne s'est passé"
    );

    // Le jeton a survécu au refus : l'utilisateur coche et poursuit.
    assert!(bac
        .depot
        .inscrire(&jeton_inscription, "2026-07")
        .await
        .is_ok());
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.compte").await, 1);
}

/// R3 — le jeton d'inscription ne sert qu'une fois : deux appels ne peuvent pas
/// créer deux comptes.
#[sqlx::test(migrations = "../../migrations")]
async fn jeton_inscription_non_rejouable(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let code = bac.code(SAISIE_LOCALE).await;
    let IssueVerification::ConsentementRequis { jeton_inscription } = bac
        .depot
        .verifier_otp(bac.zone, SAISIE_LOCALE, &code, &bac.appareil())
        .await
        .unwrap()
    else {
        panic!("numéro inconnu attendu");
    };

    bac.depot
        .inscrire(&jeton_inscription, "2026-07")
        .await
        .unwrap();
    assert!(
        matches!(
            bac.depot.inscrire(&jeton_inscription, "2026-07").await,
            Err(ErreurComptes::JetonInscriptionInvalide)
        ),
        "second usage refusé"
    );
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.compte").await, 1);
}

/// Un jeton inventé ne crée rien.
#[sqlx::test(migrations = "../../migrations")]
async fn jeton_inscription_inconnu_refuse(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    assert!(matches!(
        bac.depot.inscrire("jeton-inexistant", "2026-07").await,
        Err(ErreurComptes::JetonInscriptionInvalide)
    ));
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.compte").await, 0);
}

/// L'unicité du numéro est portée par le SCHÉMA, pas par une vérification
/// applicative contournable : deux créations directes du même numéro échouent
/// même si le flux les a laissées passer.
#[sqlx::test(migrations = "../../migrations")]
async fn numero_unique_impose_par_le_schema(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;

    let mut tx = pool.begin().await.unwrap();
    bac.depot
        .creer_compte(&mut tx, E164, bac.zone, "2026-07")
        .await
        .unwrap();
    let doublon = bac
        .depot
        .creer_compte(&mut tx, E164, bac.zone, "2026-07")
        .await;
    assert!(
        matches!(doublon, Err(ErreurComptes::Sql(_))),
        "la contrainte UNIQUE refuse le doublon"
    );
    drop(tx);

    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.compte").await,
        0,
        "transaction avortée → aucun compte, aucun événement"
    );
    assert_eq!(bac.evenements("compte.cree").await.len(), 0);
}

/// Constitution VI — un échec après l'écriture de l'événement n'en laisse
/// AUCUNE trace : l'atomicité n'est pas déclarative, elle est vérifiée.
#[sqlx::test(migrations = "../../migrations")]
async fn transaction_annulee_ne_laisse_ni_compte_ni_evenement(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;

    let mut tx = pool.begin().await.unwrap();
    bac.depot
        .creer_compte(&mut tx, E164, bac.zone, "2026-07")
        .await
        .unwrap();
    tx.rollback().await.unwrap();

    assert_eq!(bac.compter("SELECT count(*) FROM comptes.compte").await, 0);
    assert_eq!(
        bac.compter("SELECT count(*) FROM comptes.attribution_role")
            .await,
        0
    );
    assert_eq!(bac.evenements("compte.cree").await.len(), 0);
}

/// Deux appareils, deux numéros : les comptes et sessions restent distincts.
#[sqlx::test(migrations = "../../migrations")]
async fn deux_numeros_donnent_deux_comptes(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let awa = bac.inscrire(SAISIE_LOCALE).await;
    let yao = bac.inscrire("0705060708").await;

    assert_ne!(awa, yao);
    assert_eq!(bac.compter("SELECT count(*) FROM comptes.compte").await, 2);
    assert_eq!(
        bac.depot.compte(yao).await.unwrap().telephone_e164,
        "+2250705060708"
    );
}

/// Le refresh n'est JAMAIS stocké en clair : la base n'en connaît que le hash.
#[sqlx::test(migrations = "../../migrations")]
async fn refresh_stocke_hache_uniquement(pool: PgPool) {
    let bac = Bac::nouveau(pool.clone()).await;
    let code = bac.code(SAISIE_LOCALE).await;
    let IssueVerification::ConsentementRequis { jeton_inscription } = bac
        .depot
        .verifier_otp(bac.zone, SAISIE_LOCALE, &code, &bac.appareil())
        .await
        .unwrap()
    else {
        panic!("numéro inconnu attendu");
    };
    let ouverte = bac
        .depot
        .inscrire(&jeton_inscription, "2026-07")
        .await
        .unwrap();

    let hash: Vec<u8> = sqlx::query_scalar("SELECT refresh_hash FROM comptes.session")
        .fetch_one(&pool)
        .await
        .unwrap();
    assert_eq!(hash.len(), 32, "SHA-256");
    assert_ne!(
        hash,
        ouverte.jetons.rafraichissement.as_bytes(),
        "le jeton en clair n'est pas en base"
    );
    let en_clair: i64 = sqlx::query_scalar(
        "SELECT count(*) FROM comptes.session WHERE encode(refresh_hash, 'escape') = $1",
    )
    .bind(&ouverte.jetons.rafraichissement)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(en_clair, 0);

    // La session naît ACTIVE et sans jeton précédent (aucune rotation encore).
    let precedent: Option<Vec<u8>> =
        sqlx::query_scalar("SELECT refresh_precedent_hash FROM comptes.session")
            .fetch_one(&pool)
            .await
            .unwrap();
    assert!(precedent.is_none());
}
