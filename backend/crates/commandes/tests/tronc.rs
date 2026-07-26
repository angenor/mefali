//! **T037** — le tronc `commande` est un TRONC : la livraison en est un
//! composant **optionnel (0..n)**, pas une partie de lui (constitution II).
//!
//! Ce test ne vérifie pas un comportement du MVP : aucun vertical actuel ne
//! crée de commande sans livraison. Il vérifie une **frontière**, et c'est
//! précisément parce qu'aucun parcours ne l'exerce qu'elle doit être testée —
//! sinon la première colonne logistique glissée sur le tronc passerait sans
//! qu'aucune suite ne bronche, et le premier vertical sans livraison (un
//! artisan qui intervient chez le client, cadrage §11.11) découvrirait à son
//! cycle que le socle ne le supporte plus.
//!
//! Deux assertions, complémentaires :
//! 1. une commande **sans aucune livraison** s'écrit et se relit sans erreur ;
//! 2. le tronc ne porte **aucune** colonne logistique — la liste est extraite
//!    du catalogue Postgres, pas d'une relecture humaine du fichier de
//!    migration.

use std::sync::Arc;

use commandes::{PgCommandes, RestrictionsSimulees, TarifFixe};
use uuid::Uuid;

/// Compose le dépôt du domaine. Le chemin exercé ici — le REJEU idempotent —
/// rend la main avant tout appel à un collaborateur : les doubles ne servent
/// qu'à construire le dépôt, aucun n'est sollicité.
fn depot(pool: &sqlx::PgPool) -> PgCommandes {
    let objets: Arc<dyn socle::DepotObjets> = Arc::new(socle::MemoireObjets::new());
    let comptes = comptes::PgComptes::new(
        pool.clone(),
        Arc::new(comptes::MemoireEphemere::new()),
        Arc::new(comptes::SmsTraces::new()),
        objets.clone(),
        Arc::from(&b"secret-de-test-de-32-octets-mini"[..]),
    );
    let presta = prestataires::PgPrestataires::new(
        pool.clone(),
        comptes,
        objets.clone(),
        Arc::new(prestataires::AucuneCommandeActive),
        Arc::from(&b"secret-plaque-de-test-32-octets!"[..]),
    );
    let tarif = Arc::new(TarifFixe::simple(2_500, 2_500, 0));
    PgCommandes::new(
        pool.clone(),
        presta,
        tarif.clone(),
        tarif,
        Arc::new(RestrictionsSimulees::nouveau()),
        objets,
        Arc::new(commandes::PositionFixe::nouveau()),
        Arc::new(commandes::PreuvesFixes::nouveau()),
    )
}

/// Sème les FK minimales et une commande SANS livraison. Renvoie son id.
async fn commande_sans_livraison(pool: &sqlx::PgPool) -> Uuid {
    let pays = Uuid::now_v7();
    let ville = Uuid::now_v7();
    let categorie = Uuid::now_v7();
    let client = Uuid::now_v7();
    let commande = Uuid::now_v7();

    sqlx::query("INSERT INTO zones.zone (id, type, nom) VALUES ($1, 'pays', 'CI')")
        .bind(pays).execute(pool).await.unwrap();
    sqlx::query(
        "INSERT INTO zones.zone (id, parent_id, type, nom) VALUES ($1, $2, 'ville', 'Tiassalé')",
    ).bind(ville).bind(pays).execute(pool).await.unwrap();
    // Une catégorie de service SANS livraison : le vertical « artisan »
    // qu'aucun cycle n'a encore construit, mais que le socle doit accepter.
    sqlx::query(
        "INSERT INTO zones.categorie (id, slug, nom_cle, workflow_vendeur)
         VALUES ($1, 'artisanat', 'categorie.artisanat.nom', 'marche_etals')",
    ).bind(categorie).execute(pool).await.unwrap();
    sqlx::query(
        "INSERT INTO comptes.compte (id, telephone_e164, zone_id, consentement_version, consentement_le)
         VALUES ($1, '+2250700000009', $2, '2026-07', now())",
    ).bind(client).bind(ville).execute(pool).await.unwrap();

    sqlx::query(
        "INSERT INTO commandes.commande
            (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon, repere_texte,
             montant_articles_unites, total_unites, devise, mode_paiement,
             code_livraison, code_livraison_hash, jeton_reception, jeton_reception_hash)
         VALUES ($1, $2, $3, $4, 5.900, -4.820, 'Cour de la mosquée',
                 12000, 12000, 'XOF', 'cash', '4821', 'h-code', 'jeton', 'h-jeton')",
    ).bind(commande).bind(client).bind(ville).bind(categorie)
        .execute(pool).await.unwrap();

    commande
}

/// Une commande **sans aucune livraison** existe, se relit, et porte un total
/// cohérent : la livraison est un composant optionnel (0..n).
#[sqlx::test(migrations = "../../migrations")]
async fn une_commande_sans_livraison_est_valide(pool: sqlx::PgPool) {
    let commande = commande_sans_livraison(&pool).await;

    let (etat, total, devise): (String, i64, String) = sqlx::query_as(
        "SELECT etat::text, total_unites, devise FROM commandes.commande WHERE id = $1",
    )
    .bind(commande)
    .fetch_one(&pool)
    .await
    .unwrap();
    assert_eq!(etat, "nouvelle");
    assert_eq!(total, 12_000, "montant en entiers, unités mineures (III)");
    assert_eq!(devise, "XOF");

    let livraisons: i64 =
        sqlx::query_scalar("SELECT count(*) FROM commandes.livraison WHERE commande_id = $1")
            .bind(commande)
            .fetch_one(&pool)
            .await
            .unwrap();
    assert_eq!(livraisons, 0, "0..n — et 0 est une valeur légitime");
}

/// Le REJEU d'une commande sans livraison rend `None` — **jamais** un
/// identifiant nul.
///
/// C'est la moitié manquante du test précédent : celui-ci prouvait que la base
/// accepte l'absence, pas que le domaine sait la dire. Il ne le savait pas —
/// `relire_commande_creee` recomposait un `Uuid::nil()`, deux arrêts à zéro et
/// un devis vide, qu'aucune assertion n'attrapait et que l'API servait tels
/// quels. Un identifiant nul a la forme d'un identifiant : il traverse tout.
#[sqlx::test(migrations = "../../migrations")]
async fn le_rejeu_d_une_commande_sans_livraison_ne_fabrique_aucun_identifiant(
    pool: sqlx::PgPool,
) {
    let commande = commande_sans_livraison(&pool).await;

    // Rejeu : la clé d'idempotence EST l'identifiant, et la commande existe
    // déjà — `creer_commande` rend la main sur la relecture, sans rien créer.
    let creee = depot(&pool)
        .creer_commande(commandes::creation::DemandeCreation {
            id: commande,
            client_id: Uuid::now_v7(),
            zone_id: Uuid::now_v7(),
            categorie_slug: "artisanat".to_owned(),
            transport_slug: "moto".to_owned(),
            adresse_id: None,
            lieu: None,
            repere_texte: None,
            repere_vocal_cle: None,
            lignes: Vec::new(),
            mode_paiement: commandes::ModePaiement::Cash,
        })
        .await
        .expect("le rejeu relit la commande existante");

    assert!(creee.rejeu, "la commande existait : 200, pas 201");
    assert!(
        creee.livraison.is_none(),
        "aucune livraison en base — le type doit le DIRE, pas le combler"
    );
    // Le tronc, lui, est bien relu : l'absence porte sur la livraison seule.
    assert_eq!(creee.total_unites, 12_000);
    assert_eq!(creee.devise, "XOF");
    assert_eq!(creee.secrets.code_livraison, "4821");
}

/// Le tronc ne porte **AUCUNE** colonne logistique. La liste est lue dans le
/// catalogue Postgres : une colonne ajoutée par une future migration serait
/// attrapée ici, pas à la relecture.
#[sqlx::test(migrations = "../../migrations")]
async fn le_tronc_ne_porte_aucune_colonne_logistique(pool: sqlx::PgPool) {
    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name FROM information_schema.columns
         WHERE table_schema = 'commandes' AND table_name = 'commande'",
    )
    .fetch_all(&pool)
    .await
    .unwrap();

    // Ce qui appartient à `livraison`, `segment` ou `arret` — jamais au tronc.
    for interdite in [
        "coursier_id",
        "livraison_id",
        "segment_id",
        "arret_id",
        "devis_prix_client",
        "devis_part_coursier",
        "devis_marge",
        "devis_distance_m",
        "devis_eta_s",
        "distance_m",
        "eta_s",
        "ordre_arrets",
        "mode_remise",
        "livree_le",
        "assignee_le",
        "montant_avance",
    ] {
        assert!(
            !colonnes.iter().any(|c| c == interdite),
            "« {interdite} » est LOGISTIQUE : elle vit sur livraison/segment/arret, \
             jamais sur le tronc (constitution II)",
        );
    }

    // Contrôle NÉGATIF : sans lui, ce test passerait aussi sur une table vide
    // ou mal nommée. Le tronc porte bien ses colonnes de TRONC.
    for attendue in ["client_id", "zone_id", "categorie_id", "total_unites", "etat"] {
        assert!(
            colonnes.iter().any(|c| c == attendue),
            "le tronc doit porter « {attendue} »",
        );
    }

    // Et les colonnes logistiques existent bel et bien — sur `livraison`.
    let colonnes_livraison: Vec<String> = sqlx::query_scalar(
        "SELECT column_name FROM information_schema.columns
         WHERE table_schema = 'commandes' AND table_name = 'livraison'",
    )
    .fetch_all(&pool)
    .await
    .unwrap();
    for attendue in ["coursier_id", "devis_prix_client", "mode_remise"] {
        assert!(
            colonnes_livraison.iter().any(|c| c == attendue),
            "« {attendue} » doit exister sur la LIVRAISON",
        );
    }
}
