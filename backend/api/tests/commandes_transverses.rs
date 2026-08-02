//! Phase 12 — vérifications TRANSVERSES du cycle CMD (T063, T064, T065, T066).
//!
//! Ces tests ne portent aucune story : ils portent des **règles de projet** que
//! rien d'autre ne surveille. Une règle qu'aucun test ne tient finit toujours
//! par être contournée un jour de fatigue — pas par mauvaise volonté, mais
//! parce qu'elle n'est écrite que dans un document.

mod bac_commandes;

use bac_commandes::Bac;
use serde_json::json;
use uuid::Uuid;
use zones::ConfigurationZones;

// ── T063 — rétention des photos de substitution ───────────────────────────

/// La photo d'un remplacement est purgée au-delà de la rétention de zone
/// (constitution VIII), **mais la ligne survit** : elle porte la trace d'une
/// décision d'argent, pas une donnée personnelle. C'est l'image — qui peut
/// montrer un lieu ou une personne — qui est minimisée.
#[sqlx::test(migrations = "../migrations")]
async fn photo_de_substitution_purgee_la_ligne_survit(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac
        .creer_commande_api(
            "marche",
            vec![bac.vendeurs[2].ligne_avec_preference(0, 2, "remplacer")],
        )
        .await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let ligne: Uuid =
        sqlx::query_scalar("SELECT id FROM commandes.ligne_commande WHERE commande_id = $1")
            .bind(commande)
            .fetch_one(&bac.pool)
            .await
            .unwrap();

    // Une proposition, donc une photo dans le stockage objet.
    let (statut, corps) = bac
        .post_multipart(
            &format!("/courses/{livraison}/substitutions"),
            &bac.jeton_coursier,
            json!({
                "ligne_id": ligne,
                "uuid_client": Uuid::now_v7(),
                "resolution": "remplacer",
                "article_propose_id": bac.vendeurs[2].articles[0],
                "prix_propose_unites": 770,
            }),
            true,
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    let photo_cle: String =
        sqlx::query_scalar("SELECT photo_cle FROM commandes.substitution LIMIT 1")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert!(bac.commandes.objets().existe(&photo_cle).await.unwrap());

    // Rien n'est purgé avant l'échéance (365 jours dans le bac).
    assert_eq!(bac.commandes.purger_photos_substitution().await.unwrap(), 0);

    // On fait vieillir la proposition au-delà de la rétention.
    sqlx::query("UPDATE commandes.substitution SET proposee_le = now() - interval '400 days'")
        .execute(&bac.pool)
        .await
        .unwrap();
    assert_eq!(bac.commandes.purger_photos_substitution().await.unwrap(), 1);

    assert!(
        !bac.commandes.objets().existe(&photo_cle).await.unwrap(),
        "l'objet est supprimé du stockage, pas seulement déréférencé",
    );
    let (restantes, cle_videe): (i64, String) =
        sqlx::query_as("SELECT count(*), max(photo_cle) FROM commandes.substitution")
            .fetch_one(&bac.pool)
            .await
            .unwrap();
    assert_eq!(restantes, 1, "la LIGNE survit : c'est une trace d'argent");
    assert_eq!(cle_videe, "", "seule la clé de l'image est effacée");

    // Rejouable : une seconde passe ne repurge rien et n'échoue pas.
    assert_eq!(bac.commandes.purger_photos_substitution().await.unwrap(), 0);
}

// ── T065 — tous les paramètres du cycle viennent de la ZONE ───────────────

/// Les 12 paramètres de [data-model §6] sont résolus **par héritage** depuis le
/// pays, et `mixable` (cycle 002) avec eux.
///
/// Ce test protège la constitution I par le seul moyen efficace : en listant
/// les clés. Un paramètre qu'on aurait mis en dur dans le code n'apparaîtrait
/// pas ici — mais un paramètre qu'on aurait oublié de seeder, si.
#[sqlx::test(migrations = "../migrations")]
async fn tous_les_parametres_du_cycle_sont_resolus_par_zone(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let zones = zones::PgZones::new(bac.pool.clone());

    for cle in [
        // Mixage et nature de la marchandise (une clé par catégorie).
        "categorie.marche.mixable",
        "categorie.restauration.mixable",
        "categorie.marche.perissable",
        "categorie.restauration.perissable",
        // Adresse et création.
        "commande.repere_texte_min_caracteres",
        "commande.essais_code_livraison",
        "commande.historique_min_commandes_terminees",
        // Paiement.
        "commande.plafond_cash_unites",
        "commande.plafond_cash_restauration_sans_historique_unites",
        // File d'attente.
        "commande.escalade_attente_coursier_s",
        // Substitutions.
        "substitution.delai_validation_s",
        "substitution.ecart_prix_max_pourcent",
        "substitution.photo_retention_jours",
        // Suivi.
        "suivi.position_periode_s",
    ] {
        let valeur = zones
            .parametre(bac.ville, cle)
            .await
            .unwrap_or_else(|e| panic!("« {cle} » : {e}"));
        assert!(
            valeur.is_some(),
            "« {cle} » doit être résolu à Tiassalé — par héritage du pays si \
             besoin. Un paramètre absent est une erreur de CONFIGURATION, pas \
             un défaut silencieux (constitution I)",
        );
    }
}

/// Les paramètres posés au PAYS sont bien hérités par la ville : c'est
/// l'héritage qui rend une nouvelle ville exploitable sans re-saisie.
#[sqlx::test(migrations = "../migrations")]
async fn les_parametres_du_pays_sont_herites_par_la_ville(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let zones = zones::PgZones::new(bac.pool.clone());

    // Posé au PAYS dans le bac, jamais à la ville.
    assert_eq!(
        zones
            .parametre(bac.ville, "substitution.delai_validation_s")
            .await
            .unwrap(),
        Some(json!(60)),
    );
    // Posé à la VILLE : elle prime, comme le veut l'héritage.
    assert_eq!(
        zones
            .parametre(bac.ville, "commande.plafond_cash_unites")
            .await
            .unwrap(),
        Some(json!(15_000)),
    );
}

// ── T064 — aucune chaîne utilisateur en dur côté API ──────────────────────

/// **Chaque refus métier porte sa clé i18n**, et aucun ne rend de phrase.
///
/// Le test passe par les VRAIS endpoints : c'est le seul moyen de vérifier ce
/// que le client reçoit réellement, plutôt que ce que le domaine croit rendre.
#[sqlx::test(migrations = "../migrations")]
async fn chaque_refus_de_l_api_porte_une_cle_i18n(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // Un échantillon des trois surfaces — client, coursier, admin.
    let refus: Vec<(u16, serde_json::Value)> = vec![
        // Coursier : transition hors séquence.
        bac.action_coursier(
            course.livraison,
            course.collectes[0],
            "arrive",
            Uuid::now_v7(),
        )
        .await,
        // Client : commande d'autrui.
        bac.get(
            &format!("/commandes/{}", course.commande),
            &bac.jeton_intrus,
        )
        .await,
        // Admin : annulation sans motif.
        bac.post(
            &format!("/admin/commandes/{}/annuler", course.commande),
            &bac.jeton_admin,
            json!({}),
        )
        .await,
        // Coursier : échec sans preuves.
        bac.post(
            &format!("/courses/{}/echec", course.livraison),
            &bac.jeton_coursier,
            json!({
                // `uuid_client` OBLIGATOIRE depuis CRS 010 (idempotence, R4) :
                // sans lui, la demande est mal formée et le refus n'est plus
                // celui qu'on veut mesurer.
                "uuid_client": Uuid::now_v7(),
                "type_issue": "faux_billet",
                "motif_cle": "echec.motif.x",
            }),
        )
        .await,
    ];

    for (statut, corps) in refus {
        assert!((400..500).contains(&statut), "refus attendu, reçu {statut}");
        let code = corps["code"].as_str().unwrap_or_default();
        let cle = corps["message_cle"].as_str().unwrap_or_default();
        assert!(!code.is_empty(), "tout refus porte un code : {corps}");
        assert_ne!(
            code, "erreur_interne",
            "un refus MÉTIER n'est pas une erreur technique : {corps}",
        );
        assert!(
            cle.starts_with("commande.erreur."),
            "la clé i18n doit être préfixée : {corps}",
        );
        // Aucune phrase utilisateur : une clé i18n ne contient ni espace, ni
        // majuscule accentuée — c'est un identifiant, pas un message.
        assert!(
            !cle.contains(' '),
            "« {cle} » ressemble à une phrase, pas à une clé (constitution VII)",
        );
    }
}

// ── T066 — P3 et P5, les deux points obligatoires vérifiables ici ─────────

/// **P3** — aucune requête du crate `commandes` n'écrit dans `comptes.compte`.
///
/// La sanction CPT-06 passe par le port [`commandes::RestrictionsCompte`],
/// implémenté par le crate `comptes` (research R12). Ce test lit le SOURCE :
/// c'est le seul moyen d'attraper un `UPDATE comptes.compte` qu'on aurait
/// glissé « juste une fois ».
#[test]
fn p3_commandes_n_ecrit_jamais_dans_comptes_compte() {
    let racine = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../crates/commandes/src");
    let mut fautives = Vec::new();
    for entree in std::fs::read_dir(&racine).expect("source du crate commandes") {
        let chemin = entree.unwrap().path();
        if chemin.extension().is_none_or(|e| e != "rs") {
            continue;
        }
        let source = std::fs::read_to_string(&chemin).unwrap();
        let minuscule = source.to_lowercase();
        for verbe in [
            "update comptes.compte",
            "insert into comptes.compte",
            "delete from comptes.compte",
        ] {
            if minuscule.contains(verbe) {
                fautives.push(format!("{} → « {verbe} »", chemin.display()));
            }
        }
    }
    assert!(
        fautives.is_empty(),
        "P3 — la SQL qui touche `comptes.compte` vit dans le crate `comptes` \
         (`restriction.rs`), jamais dans `commandes` : {fautives:?}",
    );
}

/// **P5** — `backend/crates/` contient toujours **13 crates**.
///
/// Le cycle CMD étend le crate `commandes` ; il n'en crée aucun. Un 14ᵉ crate
/// signifierait qu'une frontière a bougé sans arbitrage (constitution II).
#[test]
fn p5_le_workspace_compte_toujours_treize_crates() {
    let crates = std::path::Path::new(env!("CARGO_MANIFEST_DIR")).join("../crates");
    let mut noms: Vec<String> = std::fs::read_dir(&crates)
        .expect("dossier crates")
        .filter_map(|e| e.ok())
        .filter(|e| e.path().join("Cargo.toml").exists())
        .map(|e| e.file_name().to_string_lossy().into_owned())
        .collect();
    noms.sort();
    assert_eq!(noms.len(), 13, "P5 — 13 crates attendus, trouvés {noms:?}",);
}
