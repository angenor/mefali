//! US6 (cycle PAY 011, T068) — **le test qui fait foi du cycle**.
//!
//! Il parcourt la table de vérité de [`data-model.md` §5] état par état et
//! vérifie que la ventilation équilibre **sans écart d'une seule unité
//! mineure**. C'est lui qui empêche le livre de mentir.
//!
//! # Ce qu'il mesure, et pourquoi c'est cette forme-là
//!
//! Trois grandeurs, à chaque état :
//!
//! | Grandeur | Ce qu'elle dit | D'où elle vient |
//! |---|---|---|
//! | **solde livre** | ce que Yao a en poche, en plus ou en moins | Σ signée des écritures |
//! | **dû par Mefali** | ce que Mefali lui doit, formellement | Σ des créances `due` |
//! | **détenu pour Mefali** | ce qu'il a sur lui sans que ce soit à lui | `Σ min(frais, marge) − reversements` |
//!
//! Aucune n'est stockée. Les asserter contre des constantes écrites à la main
//! donnerait un test qui passe même si la tarification change ; elles sont donc
//! comparées à des grandeurs **lues indépendamment** (les montants des arrêts,
//! le devis figé), ou à zéro quand l'invariant l'exige.
//!
//! # La convergence (SC-006)
//!
//! Les quatre chemins de livraison — cash ordinaire, cash avec retenue VND-08,
//! promotion Mefali, prépayée — doivent aboutir au **même gain** pour Yao une
//! fois les créances réglées : `+P`. C'est la vérification de bout en bout, et
//! elle est faite ici, sur quatre bacs distincts qui ne diffèrent que par leur
//! devis figé.
//!
//! ⚠ Le cas « cash ordinaire » vaut `+P+M` avec `M = 0` au MVP : la marge est
//! nulle jusqu'à M4, ce qui rend ce cas trompeusement facile à lire. Le test le
//! dit explicitement à chaque assertion plutôt que de laisser croire que
//! `P + M = P` est une règle.
//!
//! **Pourquoi `drainer_caisse` plutôt que le worker** : un test de comptabilité
//! qui attend un ordonnancement asynchrone n'est pas un test, c'est un pari
//! (leçon du cycle 010). `consommer_pour_caisse` est exactement ce que
//! l'adaptateur appelle en production.

mod bac_coursier;

use bac_coursier::{Bac, Course, DEVIS_PART_COURSIER, DEVIS_PRIX_CLIENT};
use serde_json::json;
use sqlx::PgPool;
use uuid::Uuid;

/// Σ des montants avancés aux arrêts d'une course, lue sur les ARRÊTS — la
/// seule référence indépendante du livre de caisse.
async fn avances_attendues(bac: &Bac, course: &Course) -> i64 {
    sqlx::query_scalar::<_, i64>(
        "SELECT COALESCE(SUM(montant_avance), 0)::bigint FROM commandes.arret
          WHERE id = ANY($1)",
    )
    .bind(&course.collectes)
    .fetch_one(&bac.pool)
    .await
    .unwrap()
}

/// Total dû par le client, tel que le tronc le porte (ajusté par les retraits).
async fn total_du(bac: &Bac, course: &Course) -> i64 {
    sqlx::query_scalar::<_, i64>("SELECT total_unites FROM commandes.commande WHERE id = $1")
        .bind(course.commande)
        .fetch_one(&bac.pool)
        .await
        .unwrap()
}

/// Confirme la remise par le code du client — la course se termine.
async fn livrer(bac: &Bac, course: &Course) {
    bac.arriver_chez_le_client(course).await;
    let secrets = bac.secrets_remise(course.commande).await;
    let (statut, corps) = bac
        .remise(
            course.livraison,
            json!({ "mode": "code", "code": secrets.code }),
            false,
        )
        .await;
    assert_eq!(statut, 200, "remise refusée : {corps}");
    bac.drainer_caisse().await;
}

/// La ventilation d'un coursier à un instant donné : les trois grandeurs de la
/// table de vérité, lues ensemble.
struct Ventilation {
    solde_livre: i64,
    du_par_mefali: i64,
    detenu_pour_mefali: i64,
}

async fn ventilation(bac: &Bac) -> Ventilation {
    let caisse = bac.lire_caisse().await;
    let positions = &caisse["positions"];
    Ventilation {
        solde_livre: bac.solde_livre(bac.coursier).await,
        du_par_mefali: positions["du_par_mefali_unites"].as_i64().unwrap(),
        detenu_pour_mefali: positions["detenu_pour_mefali_unites"].as_i64().unwrap(),
    }
}

// ── Les états SANS aucun mouvement ────────────────────────────────────────

/// **Quatre états du tableau à zéro partout** : créée / en attente de paiement,
/// prépayée non assignée, assignée, expirée.
///
/// Rien n'a été acheté, donc rien n'est sorti de la poche de Yao — et rien ne
/// lui est dû. Un test qui ne vérifierait que les états « riches » laisserait
/// passer une écriture parasite à la création ou à l'affectation, c'est-à-dire
/// exactement le genre de bug qui ne se voit qu'au bilan de fin de mois.
#[sqlx::test(migrations = "../migrations")]
async fn les_etats_sans_achat_ne_bougent_rien(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;

    // 1. Créée (cash, pas encore assignée) — aucun événement de caisse.
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(2)])
        .await;
    bac.drainer_caisse().await;
    let v = ventilation(&bac).await;
    assert_eq!(v.solde_livre, 0, "créée : rien au livre");
    assert_eq!(v.du_par_mefali, 0);
    assert_eq!(v.detenu_pour_mefali, 0);

    // 2. Prépayée, réglée, NON assignée — le paiement du client ne fait rien
    //    entrer dans la poche du coursier.
    let prepayee = bac
        .creer_commande_mode("marche", vec![bac.vendeurs[0].ligne(2)], "mobile_money")
        .await;
    bac.commandes
        .confirmer_prepaiement(prepayee, chrono::Utc::now())
        .await
        .unwrap();
    bac.drainer_caisse().await;
    let v = ventilation(&bac).await;
    assert_eq!(v.solde_livre, 0, "prépayée non assignée : rien au livre");
    assert_eq!(v.du_par_mefali, 0, "aucune créance avant la livraison");

    // 3. Assignée — le coursier a la course, il n'a encore rien acheté.
    bac.commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    bac.drainer_caisse().await;
    let v = ventilation(&bac).await;
    assert_eq!(v.solde_livre, 0, "assignée : rien au livre");
    assert_eq!(v.du_par_mefali, 0);

    // 4. Expirée (session de paiement échue → commande annulée avant achat).
    //    Même forme que « annulée avant achat » : rien n'a été engagé.
    let expiree = bac
        .creer_commande_mode("marche", vec![bac.vendeurs[0].ligne(2)], "mobile_money")
        .await;
    commandes::CommandesAPayer::annuler_pour_expiration(
        &bac.commandes,
        expiree,
        chrono::Utc::now(),
    )
    .await
    .expect("annulation pour expiration");
    bac.drainer_caisse().await;
    let v = ventilation(&bac).await;
    assert_eq!(v.solde_livre, 0, "expirée : rien au livre");
    assert_eq!(v.du_par_mefali, 0);
    assert_eq!(v.detenu_pour_mefali, 0);
}

/// **Partiellement collectée** : `avance ×n`, solde `−A`, rien de dû.
///
/// L'argent est dehors, et c'est tout ce que le livre doit dire. Une créance à
/// ce stade serait fausse : personne n'a encore promis de rembourser quoi que
/// ce soit — le client va payer à la livraison.
#[sqlx::test(migrations = "../migrations")]
async fn partiellement_collectee_porte_les_avances_et_rien_d_autre(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    bac.collecter(course.collectes[0]).await;
    bac.drainer_caisse().await;

    let avance_du_premier =
        sqlx::query_scalar::<_, i64>("SELECT montant_avance FROM commandes.arret WHERE id = $1")
            .bind(course.collectes[0])
            .fetch_one(&bac.pool)
            .await
            .unwrap();

    let v = ventilation(&bac).await;
    assert_eq!(
        v.solde_livre, -avance_du_premier,
        "l'argent est SORTI : le solde est négatif du montant avancé",
    );
    assert_eq!(v.du_par_mefali, 0, "aucune créance avant la livraison");
    assert_eq!(v.detenu_pour_mefali, 0);
    assert!(
        bac.creances(bac.coursier).await.is_empty(),
        "une créance ici serait une promesse que personne n'a faite",
    );
}

// ── Les QUATRE chemins de livraison (SC-006) ──────────────────────────────

/// **Livrée, cash ordinaire** : `avance ×n`, `remboursement +A`,
/// `frais_encaisses +PC`. Solde `+P+M`, rien de dû.
#[sqlx::test(migrations = "../migrations")]
async fn livree_cash_ordinaire(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    let avances = avances_attendues(&bac, &course).await;
    let total = total_du(&bac, &course).await;

    livrer(&bac, &course).await;

    let v = ventilation(&bac).await;
    // `M = 0` au MVP : le solde vaut donc `P`. On l'écrit `P + M` pour que la
    // ligne reste juste le jour où la marge cesse d'être nulle.
    assert_eq!(
        v.solde_livre, DEVIS_PART_COURSIER,
        "solde = +P+M (M nulle au MVP) — Yao a récupéré son avance ET encaissé \
         les frais",
    );
    assert_eq!(total - avances, DEVIS_PRIX_CLIENT, "frais encaissés = PC");
    assert_eq!(v.du_par_mefali, 0, "tout a été encaissé : rien n'est dû");
    assert_eq!(v.detenu_pour_mefali, 0, "marge nulle au MVP");
    assert!(bac.creances(bac.coursier).await.is_empty());
}

/// **Livrée, cash + retenue VND-08** (PC = 0, R = P+M) : les avances sont
/// NETTES de la retenue, et `frais_encaisses` vaut `R`. Solde `+P+M`.
///
/// C'est le cas qui a fait rejeter la formule naïve `frais_encaisses =
/// devis_prix_client` : le prix client vaut 0, et un livre qui porterait 0
/// mentirait exactement là où la retenue existe pour qu'il dise vrai.
#[sqlx::test(migrations = "../migrations")]
async fn livree_cash_avec_retenue_vendeur(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_vendeur(pool).await;
    // Mono-vendeur : la retenue ne joue que là (FR-051).
    let commande = bac
        .creer_commande_api("marche", vec![bac.vendeurs[0].ligne(10)])
        .await;
    let livraison = bac
        .commandes
        .assigner_coursier(commande, bac.coursier, chrono::Utc::now())
        .await
        .unwrap();
    let (collectes, remise) = bac.arrets_de(livraison).await;
    let course = Course {
        commande,
        livraison,
        collectes,
        remise,
    };
    bac.collecter_tout(&course).await;

    let avances = avances_attendues(&bac, &course).await;
    let total = total_du(&bac, &course).await;
    assert_eq!(
        total - avances,
        DEVIS_PRIX_CLIENT,
        "les frais encaissés valent la RETENUE (2 500), pas le prix client (0)",
    );

    livrer(&bac, &course).await;

    let v = ventilation(&bac).await;
    assert_eq!(
        v.solde_livre, DEVIS_PART_COURSIER,
        "solde = +P+M — identique au cash ordinaire, alors que le prix client \
         vaut ZÉRO. C'est tout l'objet de la formule R13.",
    );
    assert_eq!(
        v.du_par_mefali, 0,
        "la retenue a payé la part : rien n'est dû"
    );
    assert!(bac.creances(bac.coursier).await.is_empty());
}

/// **Livrée, cash + promotion Mefali** (PC = 0, aucune retenue) : rien
/// d'encaissé, solde `0`, et la part devient une **créance** `P`.
#[sqlx::test(migrations = "../migrations")]
async fn livree_cash_avec_promo_mefali(pool: PgPool) {
    let bac = Bac::nouveau_livraison_offerte_par_mefali(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    let avances = avances_attendues(&bac, &course).await;
    let total = total_du(&bac, &course).await;
    assert_eq!(total - avances, 0, "Mefali offre : aucun frais encaissé");

    livrer(&bac, &course).await;

    let v = ventilation(&bac).await;
    assert_eq!(
        v.solde_livre, 0,
        "le livre dit vrai en n'affichant AUCUN gain : rien n'est entré",
    );
    assert_eq!(
        v.du_par_mefali, DEVIS_PART_COURSIER,
        "la part devient une créance — le seul endroit où elle peut être vue",
    );
    let creances = bac.creances(bac.coursier).await;
    assert_eq!(creances.len(), 1);
    assert_eq!(creances[0].0, "part_course");
    assert_eq!(creances[0].1, DEVIS_PART_COURSIER);
    assert_eq!(creances[0].2, "due");
}

/// **Livrée, prépayée** : `avance ×n` seules. Solde `−A`, et DEUX créances —
/// l'avance engagée et la part de course. Dû = `A + P`.
#[sqlx::test(migrations = "../migrations")]
async fn livree_prepayee(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;
    let avances = avances_attendues(&bac, &course).await;

    livrer(&bac, &course).await;

    let v = ventilation(&bac).await;
    assert_eq!(
        v.solde_livre, -avances,
        "aucun cash n'a changé de main : l'avance reste dehors, et le livre \
         le dit plutôt que d'écrire un remboursement fictif (R10)",
    );
    assert_eq!(v.du_par_mefali, avances + DEVIS_PART_COURSIER, "dû = A + P",);

    let creances = bac.creances(bac.coursier).await;
    assert_eq!(creances.len(), 2, "deux créances, deux causes distinctes");
    let natures: Vec<&str> = creances.iter().map(|c| c.0.as_str()).collect();
    assert!(natures.contains(&"avance_prepayee"));
    assert!(natures.contains(&"part_course"));
    let avance_prepayee = creances.iter().find(|c| c.0 == "avance_prepayee").unwrap();
    assert_eq!(avance_prepayee.1, avances);
    let part = creances.iter().find(|c| c.0 == "part_course").unwrap();
    assert_eq!(part.1, DEVIS_PART_COURSIER);
}

// ── Les états d'ÉCHEC ──────────────────────────────────────────────────────

/// **Annulée avant achat** : rien au livre, rien de dû.
#[sqlx::test(migrations = "../migrations")]
async fn annulee_avant_achat(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;

    // Par la route ADMIN : le bac coursier ne monte pas la surface cliente, et
    // ce test porte sur le livre, pas sur qui a le droit d'annuler (couvert
    // par le cycle 008).
    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/annuler", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "commande.annulation.admin.incident" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    bac.drainer_caisse().await;

    let v = ventilation(&bac).await;
    assert_eq!(v.solde_livre, 0, "rien n'a été acheté");
    assert_eq!(v.du_par_mefali, 0);
    assert_eq!(v.detenu_pour_mefali, 0);
}

/// **Annulée APRÈS achat** : `avance ×n` restent au livre, solde `−A`, et le
/// dû passe par l'**indemnisation** (cycle 010) — pas par une créance de ce
/// cycle.
///
/// La distinction compte : une indemnisation se décide (l'exploitation la
/// valide ou la refuse), une créance naît seule. Les mélanger ferait valider
/// automatiquement des indemnisations que personne n'a examinées.
#[sqlx::test(migrations = "../migrations")]
async fn annulee_apres_achat(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete().await;
    bac.collecter(course.collectes[0]).await;
    bac.drainer_caisse().await;
    let avance_engagee = -bac.solde_livre(bac.coursier).await;
    assert!(avance_engagee > 0, "précondition : de l'argent est dehors");

    let (statut, corps) = bac
        .post(
            &format!("/admin/commandes/{}/annuler", course.commande),
            &bac.jeton_admin,
            json!({ "motif_cle": "commande.annulation.admin.incident" }),
        )
        .await;
    assert_eq!(statut, 200, "{corps}");
    bac.drainer_caisse().await;

    let v = ventilation(&bac).await;
    assert_eq!(
        v.solde_livre, -avance_engagee,
        "l'avance reste dehors : l'annulation ne la rend pas",
    );
    assert_eq!(
        v.du_par_mefali, 0,
        "AUCUNE créance de ce cycle : le dû passe par l'indemnisation du \
         cycle 010, qui se DÉCIDE au lieu de naître seule",
    );
}

// ── La convergence (SC-006) ───────────────────────────────────────────────

/// **SC-006 — les quatre chemins convergent sur le même gain.**
///
/// Après règlement des créances, Yao gagne `P` dans les quatre cas. C'est la
/// propriété que tout le cycle existe pour tenir : la façon dont une course est
/// financée — client, vendeur, ou Mefali — ne change pas ce que le coursier
/// touche.
///
/// Le règlement passe par le domaine plutôt que par l'endpoint admin : ce test
/// mesure l'arithmétique, pas le contrôle d'accès (couvert par T073).
#[sqlx::test(migrations = "../migrations")]
async fn les_quatre_chemins_convergent_sur_le_meme_gain(pool: PgPool) {
    // Chemin 3 (promotion Mefali) : le seul des quatre qui laisse une créance
    // sur une course cash. Les trois autres sont vérifiés par leurs tests
    // dédiés ; celui-ci prouve que le RÈGLEMENT ferme l'écart.
    let bac = Bac::nouveau_livraison_offerte_par_mefali(pool).await;
    let course = bac.course_prete().await;
    bac.collecter_tout(&course).await;
    livrer(&bac, &course).await;

    let avant = ventilation(&bac).await;
    assert_eq!(avant.solde_livre, 0);
    assert_eq!(avant.du_par_mefali, DEVIS_PART_COURSIER);

    // L'exploitation verse la créance.
    let creance = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM coursier.creance WHERE coursier_id = $1 AND etat = 'due'",
    )
    .bind(bac.coursier)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    bac.coursier_depot
        .regler_creance(creance, bac.admin, "creance.reglement.virement_agence")
        .await
        .expect("règlement de la créance");

    let apres = ventilation(&bac).await;
    assert_eq!(
        apres.solde_livre, DEVIS_PART_COURSIER,
        "après règlement, le livre porte le MÊME gain que le cash ordinaire : \
         +P. Les quatre chemins convergent (SC-006).",
    );
    assert_eq!(apres.du_par_mefali, 0, "plus rien n'est dû");
    assert_eq!(
        apres.solde_livre + apres.du_par_mefali,
        DEVIS_PART_COURSIER,
        "invariant : livre + dû = gain total, avant comme après règlement",
    );
    // Avant le règlement, la même somme : 0 + P. L'argent a changé de place,
    // pas de quantité — et c'est ce que « la ventilation équilibre » veut dire.
    assert_eq!(avant.solde_livre + avant.du_par_mefali, DEVIS_PART_COURSIER);
}

/// **Le cas prépayé converge aussi** : `−A + (A + P) = P`.
#[sqlx::test(migrations = "../migrations")]
async fn le_chemin_prepaye_converge_apres_reglement(pool: PgPool) {
    let bac = Bac::nouveau(pool).await;
    let course = bac.course_prete_mode("mobile_money").await;
    bac.collecter_tout(&course).await;
    let avances = avances_attendues(&bac, &course).await;
    livrer(&bac, &course).await;

    let avant = ventilation(&bac).await;
    assert_eq!(
        avant.solde_livre + avant.du_par_mefali,
        DEVIS_PART_COURSIER,
        "−A + (A + P) = P — l'équilibre tient AVANT même le règlement",
    );

    // Les deux créances sont réglées.
    let creances = sqlx::query_scalar::<_, Uuid>(
        "SELECT id FROM coursier.creance WHERE coursier_id = $1 AND etat = 'due'
         ORDER BY cree_le",
    )
    .bind(bac.coursier)
    .fetch_all(&bac.pool)
    .await
    .unwrap();
    assert_eq!(creances.len(), 2);
    for creance in creances {
        bac.coursier_depot
            .regler_creance(creance, bac.admin, "creance.reglement.virement_agence")
            .await
            .expect("règlement");
    }

    let apres = ventilation(&bac).await;
    assert_eq!(
        apres.solde_livre, DEVIS_PART_COURSIER,
        "−A + A + P = P : le même gain que les trois autres chemins",
    );
    assert_eq!(apres.du_par_mefali, 0);
    assert!(
        avances > 0,
        "précondition : des avances ont bien été engagées"
    );
}
