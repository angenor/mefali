//! US2 (CMD-02) — donner une adresse qu'un coursier peut TROUVER.
//!
//! Un pin GPS ne suffit pas à Tiassalé : les rues n'ont pas toujours de nom et
//! les numéros n'existent pas. C'est le **repère** qui fait la différence entre
//! une livraison et un appel — d'où son caractère obligatoire, en texte **ou**
//! en vocal (FR-018), et le téléphone vérifié qui permet de rappeler (FR-019).
//!
//! L'adresse est **dénormalisée** sur le tronc à la création (research R3) : le
//! carnet peut être renommé, purgé de son repère vocal ou supprimé sans jamais
//! altérer une commande passée.

mod bac_commandes;

use actix_web::{test as atest, App};
use bac_commandes::Bac;
use serde_json::{json, Value};
use uuid::Uuid;

/// `POST /commandes` avec une clé d'idempotence donnée.
async fn creer(bac: &Bac, jeton: &str, cle: Uuid, corps: Value) -> (u16, Value) {
    let app = atest::init_service(App::new().configure(bac.configurer())).await;
    let req = atest::TestRequest::post()
        .uri("/commandes")
        .insert_header(("authorization", format!("Bearer {jeton}")))
        .insert_header(("idempotency-key", cle.to_string()))
        .set_json(corps)
        .to_request();
    let resp = atest::call_service(&app, req).await;
    let statut = resp.status().as_u16();
    (statut, atest::read_body_json(resp).await)
}

/// Corps de création nominal : 3 vendeurs, repère écrit assez long, cash.
fn demande(bac: &Bac, lignes: Vec<Value>) -> Value {
    json!({
        "zone_id": bac.ville,
        "categorie_slug": "marche",
        "transport_slug": "moto",
        "lieu": { "lat": 5.9050, "lon": -4.8300 },
        "repere_texte": "Près de la pharmacie Sainte-Marie",
        "lignes": lignes,
        "mode_paiement": "cash",
    })
}

/// **US2** — les cinq cas du repère (FR-018) : texte assez long accepté, texte
/// trop court refusé, vocal seul accepté, aucun repère refusé, et un repère
/// vocal PURGÉ sans texte fait redemander le repère.
#[sqlx::test(migrations = "../migrations")]
async fn repere_obligatoire_texte_ou_vocal(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let lignes = vec![bac.vendeurs[0].ligne(1)];

    // 1. Repère écrit de 10 caractères minimum → accepté.
    let mut corps = demande(&bac, lignes.clone());
    corps["repere_texte"] = json!("Face au marché");
    let (statut, _) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201);

    // 2. Repère écrit TROP COURT (< 10) et sans vocal → refusé.
    let mut corps = demande(&bac, lignes.clone());
    corps["repere_texte"] = json!("là-bas");
    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 422);
    assert_eq!(refus["code"], "repere_manquant");
    assert_eq!(refus["message_cle"], "commande.erreur.repere_manquant");

    // 3. Repère VOCAL seul → accepté (sa durée est bornée au cycle 003).
    let mut corps = demande(&bac, lignes.clone());
    corps["repere_texte"] = Value::Null;
    corps["repere_vocal_cle"] = json!("comptes/reperes/abc.m4a");
    let (statut, _) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201);

    // 4. AUCUN repère → refusé.
    let mut corps = demande(&bac, lignes.clone());
    corps["repere_texte"] = Value::Null;
    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 422);
    assert_eq!(refus["code"], "repere_manquant");

    // 5. Un repère vocal PURGÉ (rétention écoulée) sans texte : le repère est
    // REDEMANDÉ avant confirmation, pas découvert manquant devant la porte.
    let mut corps = demande(&bac, lignes);
    corps["repere_texte"] = json!("court");
    corps["repere_vocal_cle"] = Value::Null;
    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 422);
    assert_eq!(refus["code"], "repere_manquant");
}

/// L'adresse du carnet est DÉNORMALISÉE sur le tronc, et son usage est marqué
/// (la rétention du repère vocal repart de là — FR-022).
#[sqlx::test(migrations = "../migrations")]
async fn adresse_du_carnet_denormalisee_et_usage_marque(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let adresse_id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO comptes.adresse
             (id, compte_id, libelle, lat, lng, repere_texte, zone_id,
              derniere_utilisation_le)
         VALUES ($1, $2, 'Maison', 5.9051, -4.8301, 'Près de la pharmacie', $3,
                 now() - interval '200 days')",
    )
    .bind(adresse_id)
    .bind(bac.client)
    .bind(bac.ville)
    .execute(&bac.pool)
    .await
    .unwrap();

    let mut corps = demande(&bac, vec![bac.vendeurs[0].ligne(1)]);
    corps["adresse_id"] = json!(adresse_id);
    corps["lieu"] = Value::Null;
    corps["repere_texte"] = Value::Null;
    let (statut, _) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 201);

    let (lat, repere, adresse): (f64, Option<String>, Option<Uuid>) = sqlx::query_as(
        "SELECT lieu_lat, repere_texte, adresse_id FROM commandes.commande",
    )
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert!((lat - 5.9051).abs() < 1e-9, "pin COPIÉ sur le tronc");
    assert_eq!(repere.as_deref(), Some("Près de la pharmacie"));
    assert_eq!(adresse, Some(adresse_id));

    // FR-022 — la rétention repart de cette utilisation.
    let recent: bool = sqlx::query_scalar(
        "SELECT derniere_utilisation_le > now() - interval '1 minute'
         FROM comptes.adresse WHERE id = $1",
    )
    .bind(adresse_id)
    .fetch_one(&bac.pool)
    .await
    .unwrap();
    assert!(recent, "l'usage de l'adresse est marqué à la commande");
}

/// L'adresse d'AUTRUI n'est pas utilisable : la propriété est dans le `WHERE`.
#[sqlx::test(migrations = "../migrations")]
async fn adresse_d_autrui_refusee(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let adresse_id = Uuid::now_v7();
    sqlx::query(
        "INSERT INTO comptes.adresse (id, compte_id, libelle, lat, lng, repere_texte, zone_id)
         VALUES ($1, $2, 'Maison', 5.9, -4.8, 'Près de la pharmacie', $3)",
    )
    .bind(adresse_id)
    .bind(bac.intrus)
    .bind(bac.ville)
    .execute(&bac.pool)
    .await
    .unwrap();

    let mut corps = demande(&bac, vec![bac.vendeurs[0].ligne(1)]);
    corps["adresse_id"] = json!(adresse_id);
    let (statut, refus) = creer(&bac, &bac.jeton_client, Uuid::now_v7(), corps).await;
    assert_eq!(statut, 403);
    assert_eq!(refus["code"], "non_proprietaire");
}
