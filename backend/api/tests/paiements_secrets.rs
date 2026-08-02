//! US3 — **rien ne fuit** (FR-006, FR-103).
//!
//! Trois surfaces, une seule règle : ni l'accès de paiement, ni une signature,
//! ni une référence de fournisseur ne doivent apparaître dans
//!
//! - un **événement outbox** — relu, exporté, archivé, potentiellement rejoué ;
//! - une **réponse d'API** autre que celle qui sert légitimement l'accès à son
//!   propriétaire ;
//! - un **journal** — sur un serveur, les logs partent souvent plus loin que la
//!   base.
//!
//! # Pourquoi capturer les journaux plutôt que relire le code
//!
//! Une revue de code prouve l'état d'aujourd'hui. Un `tracing::warn!` ajouté
//! demain pour diagnostiquer un incident — le réflexe le plus naturel du monde —
//! la contournerait sans que rien ne s'allume. Ce test capture la sortie
//! `tracing` du parcours complet et y cherche les secrets : il échouera le jour
//! où quelqu'un journalisera le corps d'une notification.

mod bac_paiements;

use std::io;
use std::sync::{Arc, Mutex};

use bac_paiements::Bac;
use paiements::IssuePaiement;

/// Tampon partagé où `tracing` écrit, pour être relu par le test.
#[derive(Clone, Default)]
struct Journal(Arc<Mutex<Vec<u8>>>);

impl Journal {
    fn contenu(&self) -> String {
        String::from_utf8_lossy(&self.0.lock().expect("journal").clone()).into_owned()
    }
}

impl io::Write for Journal {
    fn write(&mut self, octets: &[u8]) -> io::Result<usize> {
        self.0.lock().expect("journal").extend_from_slice(octets);
        Ok(octets.len())
    }
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

impl<'a> tracing_subscriber::fmt::MakeWriter<'a> for Journal {
    type Writer = Journal;
    fn make_writer(&'a self) -> Self::Writer {
        self.clone()
    }
}

/// Ce qui ne doit **jamais** sortir.
struct Secrets {
    acces: String,
    signature: String,
    reference_fournisseur: String,
}

/// Déroule un parcours complet — ouverture, refus de signature, notification —
/// en capturant les journaux, et rend les secrets à traquer.
async fn parcours(bac: &Bac, journal: &Journal) -> (uuid::Uuid, Secrets) {
    let _garde = tracing::subscriber::set_default(
        tracing_subscriber::fmt()
            .with_writer(journal.clone())
            .with_ansi(false)
            .with_max_level(tracing::Level::TRACE)
            .finish(),
    );

    let commande = bac.commande_prepayee().await;
    let (statut, session) = bac
        .post_vide(
            &format!("/commandes/{commande}/paiement"),
            &bac.cmd.jeton_client,
        )
        .await;
    assert_eq!(statut, 200, "{session}");
    let transaction: uuid::Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();
    let acces = session["acces_paiement"].as_str().unwrap().to_owned();

    // Une signature REFUSÉE : le chemin où la tentation de journaliser le corps
    // est la plus forte.
    let corps = Bac::corps_notification(transaction, montant, "XOF", IssuePaiement::Reussi);
    let signature_forgee = "t=1,v1=forgee-par-un-attaquant-0123456789abcdef".to_owned();
    let (statut, _) = bac
        .post_brut(
            "/paiements/notifications/simule",
            &corps,
            &[(
                paiements::fournisseur::simule::ENTETE_SIGNATURE,
                signature_forgee.clone(),
            )],
        )
        .await;
    assert_eq!(statut, 401);

    // Puis la vraie notification, qui confirme.
    let signature = bac.entete_signature(&corps).1;
    let (statut, _) = bac
        .notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;
    assert_eq!(statut, 200);

    let reference_fournisseur: String =
        sqlx::query_scalar("SELECT reference_fournisseur FROM paiements.transaction WHERE id = $1")
            .bind(transaction)
            .fetch_one(&bac.cmd.pool)
            .await
            .expect("la référence du fournisseur est stockée pour rapprocher les comptes");

    (
        commande,
        Secrets {
            acces,
            signature,
            reference_fournisseur,
        },
    )
}

/// FR-103 — **aucun événement outbox ne porte de secret**.
///
/// Un événement est relu, exporté, archivé. Y déposer une URL d'encaissement
/// reviendrait à la publier — et une URL d'encaissement encore vivante permet
/// de payer.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_evenement_ne_porte_de_secret(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let journal = Journal::default();
    let (_, secrets) = parcours(&bac, &journal).await;

    let tout: String = sqlx::query_scalar::<_, String>(
        "SELECT string_agg(payload::text, ' ') FROM outbox.evenement",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .expect("le journal d'outbox se lit");

    for (quoi, secret) in [
        ("l'accès de paiement", &secrets.acces),
        ("la signature", &secrets.signature),
        (
            "la référence du fournisseur",
            &secrets.reference_fournisseur,
        ),
    ] {
        assert!(
            !tout.contains(secret.as_str()),
            "{quoi} ne doit JAMAIS entrer dans un événement outbox (FR-103)",
        );
    }
    assert!(
        !tout.contains("acces_paiement"),
        "pas même le NOM du champ : sa présence signalerait une charge à revoir",
    );
}

/// **Aucun journal ne porte de secret**, y compris sur le chemin d'un refus.
///
/// Le refus est le cas le plus tentant : diagnostiquer une signature qui ne
/// passe pas donne envie de journaliser le corps et la signature reçue. C'est
/// exactement ce que ce test interdit.
#[sqlx::test(migrations = "../migrations")]
async fn aucun_journal_ne_porte_de_secret(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let journal = Journal::default();
    let (_, secrets) = parcours(&bac, &journal).await;

    let trace = journal.contenu();
    assert!(
        !trace.is_empty(),
        "le parcours doit produire des traces — sans quoi ce test ne prouve rien",
    );
    assert!(
        trace.contains("REFUSÉE"),
        "le refus de signature EST journalisé : ce qu'on interdit, c'est son \
         contenu, pas sa trace — journal capturé :\n{trace}",
    );

    for (quoi, secret) in [
        ("l'accès de paiement", &secrets.acces),
        ("la signature", &secrets.signature),
    ] {
        assert!(
            !trace.contains(secret.as_str()),
            "{quoi} ne doit JAMAIS être journalisé (FR-006)",
        );
    }
    assert!(
        !trace.contains("reference_marchande"),
        "le corps reçu n'est pas journalisé — seulement sa taille",
    );
    assert!(
        !trace.contains("forgee-par-un-attaquant"),
        "la signature PRÉSENTÉE par un attaquant n'entre pas dans nos journaux",
    );
}

/// L'accès n'est servi **qu'à son propriétaire**, et seulement tant que la
/// session accepte un paiement.
#[sqlx::test(migrations = "../migrations")]
async fn l_acces_n_est_servi_qu_a_son_proprietaire(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let commande = bac.commande_prepayee().await;
    let uri = format!("/commandes/{commande}/paiement");

    let (_, session) = bac.post_vide(&uri, &bac.cmd.jeton_client).await;
    assert!(session["acces_paiement"].as_str().is_some());

    // Un tiers ne lit rien du tout.
    let (statut, corps) = bac.get(&uri, &bac.cmd.jeton_intrus).await;
    assert_eq!(statut, 403);
    assert!(
        !corps.to_string().contains("acces_paiement"),
        "un refus ne laisse pas fuiter le champ qu'il refuse",
    );

    // Une fois réglée, l'accès disparaît — de la réponse ET de la base.
    let transaction: uuid::Uuid = session["transaction_id"].as_str().unwrap().parse().unwrap();
    let montant = session["montant_unites"].as_i64().unwrap();
    bac.notifier(transaction, montant, "XOF", IssuePaiement::Reussi)
        .await;

    let (_, etat) = bac.get(&uri, &bac.cmd.jeton_client).await;
    assert!(etat["acces_paiement"].is_null());

    let en_base: Option<String> =
        sqlx::query_scalar("SELECT acces_paiement FROM paiements.transaction WHERE id = $1")
            .bind(transaction)
            .fetch_one(&bac.cmd.pool)
            .await
            .unwrap();
    assert!(
        en_base.is_none(),
        "l'accès est EFFACÉ en base à l'issue : une URL d'encaissement qui \
         survit à son paiement est une surface d'attaque sans usage",
    );
}

/// La table des notifications ne conserve **ni corps brut ni signature** — sa
/// seule trace est une empreinte, qui ne permet de reconstituer aucun paiement.
#[sqlx::test(migrations = "../migrations")]
async fn la_table_des_notifications_ne_conserve_ni_corps_ni_signature(pool: sqlx::PgPool) {
    let bac = Bac::nouveau(pool).await;
    let journal = Journal::default();
    let (_, secrets) = parcours(&bac, &journal).await;

    let colonnes: Vec<String> = sqlx::query_scalar(
        "SELECT column_name::text FROM information_schema.columns
          WHERE table_schema = 'paiements' AND table_name = 'notification_recue'",
    )
    .fetch_all(&bac.cmd.pool)
    .await
    .unwrap();

    for interdite in ["corps", "corps_brut", "charge", "signature", "payload"] {
        assert!(
            !colonnes.iter().any(|c| c == interdite),
            "la colonne « {interdite} » ne doit pas exister — colonnes = {colonnes:?}",
        );
    }

    // Et rien de ce qui est stocké ne contient la signature.
    let tout: String = sqlx::query_scalar(
        "SELECT coalesce(string_agg(t::text, ' '), '') FROM paiements.notification_recue t",
    )
    .fetch_one(&bac.cmd.pool)
    .await
    .unwrap();
    assert!(!tout.contains(&secrets.signature));
    assert!(!tout.contains(&secrets.acces));
}
