//! US7 (cycle PAY 011, T076) — le client HTTP vers l'agrégateur, contre un
//! **serveur bouchon**.
//!
//! Ce que le test mesure : le contrat sortant (méthode, chemin, en-tête
//! d'autorisation, forme du corps), la traduction des codes d'état vers les
//! cinq variantes d'`ErreurFournisseur`, la reprise sur panne transitoire, et
//! le fait que les montants voyagent en **entiers**.
//!
//! # Pourquoi un serveur à la main plutôt qu'une bibliothèque de bouchons
//!
//! Constitution X : les dépendances ne s'ajoutent pas au milieu d'un cycle pour
//! le confort d'un test. Un `TcpListener` tokio et quarante lignes suffisent, et
//! ce que le test exerce est alors le VRAI client `reqwest` sur une VRAIE
//! socket — pas un adaptateur qui court-circuite la couche transport.
//!
//! ⚠ **Réserve, écrite ici pour qu'elle ne se perde pas** : ce serveur parle le
//! contrat que NOUS avons défini. Il valide la forme de l'abstraction, pas son
//! contact avec un agrégateur réel — aucun sandbox n'est disponible, le choix
//! n'étant pas fait (cadrage §10.7). La leçon du cycle 010 vaut mot pour mot :
//! 9 défauts invisibles de 758 tests attendaient la première exécution réelle.

use std::sync::{Arc, Mutex};

use paiements::fournisseur::agregateur::AgregateurHttp;
use paiements::{
    DemandeCheckout, EntetesNotification, ErreurFournisseur, IssuePaiement, MoyenPaiement,
    NotificationEntrante, PaymentProvider,
};
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use uuid::Uuid;

const SECRET: &[u8] = b"secret-de-test-de-32-octets-mini";

/// Ce qu'une requête a réellement envoyé — la ligne de requête et le corps.
#[derive(Debug, Clone, Default)]
struct RequeteRecue {
    ligne: String,
    autorisation: String,
    corps: String,
}

/// Serveur HTTP bouchon : rend les réponses de la file, dans l'ordre, et garde
/// trace de ce qu'il a reçu.
struct Bouchon {
    base_url: String,
    recues: Arc<Mutex<Vec<RequeteRecue>>>,
}

impl Bouchon {
    /// Démarre le serveur. `reponses` est consommée dans l'ordre ; la dernière
    /// est répétée si d'autres requêtes arrivent.
    async fn demarrer(reponses: Vec<(u16, String)>) -> Self {
        let ecouteur = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
        let port = ecouteur.local_addr().unwrap().port();
        let recues = Arc::new(Mutex::new(Vec::new()));
        let trace = recues.clone();

        tokio::spawn(async move {
            let mut restantes = reponses.into_iter().collect::<Vec<_>>();
            let mut derniere = (200u16, "{}".to_owned());
            loop {
                let Ok((mut flux, _)) = ecouteur.accept().await else {
                    return;
                };
                let mut tampon = vec![0u8; 8192];
                let n = flux.read(&mut tampon).await.unwrap_or(0);
                let brut = String::from_utf8_lossy(&tampon[..n]).into_owned();

                let ligne = brut.lines().next().unwrap_or_default().to_owned();
                let autorisation = brut
                    .lines()
                    .find(|l| l.to_ascii_lowercase().starts_with("authorization:"))
                    .unwrap_or_default()
                    .to_owned();
                let corps = brut.split("\r\n\r\n").nth(1).unwrap_or_default().to_owned();
                trace.lock().unwrap().push(RequeteRecue {
                    ligne,
                    autorisation,
                    corps,
                });

                if !restantes.is_empty() {
                    derniere = restantes.remove(0);
                }
                let (statut, charge) = derniere.clone();
                let reponse = format!(
                    "HTTP/1.1 {statut} X\r\nContent-Type: application/json\r\n\
                     Content-Length: {}\r\nConnection: close\r\n\r\n{charge}",
                    charge.len(),
                );
                let _ = flux.write_all(reponse.as_bytes()).await;
                let _ = flux.shutdown().await;
            }
        });

        Self {
            base_url: format!("http://127.0.0.1:{port}"),
            recues,
        }
    }

    fn client(&self) -> AgregateurHttp {
        AgregateurHttp::nouveau(&self.base_url, "cle-api-de-test", SECRET.to_vec(), "x-signature")
            .unwrap()
    }

    fn recues(&self) -> Vec<RequeteRecue> {
        self.recues.lock().unwrap().clone()
    }
}

fn demande(montant: i64) -> DemandeCheckout {
    DemandeCheckout {
        reference_marchande: Uuid::now_v7(),
        montant_unites: montant,
        devise: "XOF".to_owned(),
        description_cle: "paiement.description.commande",
        retour_succes: "mefali://commande/x".to_owned(),
        retour_annulation: "mefali://commande/x?annule".to_owned(),
    }
}

/// L'ouverture d'encaissement part au bon endroit, authentifiée, avec un
/// montant **entier**.
#[tokio::test]
async fn l_ouverture_envoie_un_montant_entier_et_s_authentifie() {
    let bouchon = Bouchon::demarrer(vec![(
        200,
        r#"{"reference":"agg-42","url_paiement":"https://pay.invalid/42"}"#.to_owned(),
    )])
    .await;

    let checkout = bouchon
        .client()
        .create_checkout(demande(12_500))
        .await
        .expect("ouverture acceptée");

    assert_eq!(checkout.reference_fournisseur, "agg-42");
    assert_eq!(checkout.acces_paiement, "https://pay.invalid/42");
    assert!(
        checkout.expire_le.is_none(),
        "le fournisseur n'a annoncé aucune échéance — la nôtre fait foi (R7)",
    );

    let recue = &bouchon.recues()[0];
    assert!(recue.ligne.starts_with("POST /checkouts "), "{}", recue.ligne);
    assert!(
        recue.autorisation.to_ascii_lowercase().contains("bearer cle-api-de-test"),
        "la clé d'API voyage en Bearer : {}",
        recue.autorisation,
    );
    assert!(
        recue.corps.contains("\"montant\":12500"),
        "le montant part en ENTIER, sans décimale : {}",
        recue.corps,
    );
    assert!(
        !recue.corps.contains("12500.0") && !recue.corps.contains("125.00"),
        "aucun flottant ne franchit la frontière (constitution III)",
    );
}

/// Un `4xx` devient `RefuseParFournisseur`, un `5xx` devient `Indisponible`.
/// La distinction compte : l'un se réessaie, l'autre jamais.
#[tokio::test]
async fn les_codes_d_etat_se_traduisent_vers_nos_cinq_variantes() {
    let refus = Bouchon::demarrer(vec![(
        422,
        r#"{"erreur":"montant hors bornes"}"#.to_owned(),
    )])
    .await;
    let erreur = refus.client().create_checkout(demande(1)).await.unwrap_err();
    assert!(
        matches!(erreur, ErreurFournisseur::RefuseParFournisseur(_)),
        "un 4xx : le fournisseur a COMPRIS et a dit non — {erreur}",
    );

    // Deux 500 d'affilée : la reprise s'épuise et l'erreur remonte.
    let panne = Bouchon::demarrer(vec![
        (500, "boom".to_owned()),
        (500, "boom".to_owned()),
    ])
    .await;
    let erreur = panne.client().create_checkout(demande(1)).await.unwrap_err();
    assert!(
        matches!(erreur, ErreurFournisseur::Indisponible(_)),
        "un 5xx : la panne n'est pas la nôtre — {erreur}",
    );
    assert_eq!(
        panne.recues().len(),
        2,
        "une reprise, pas plus : réessayer une ouverture déjà acceptée créerait \
         deux sessions pour une commande",
    );
}

/// Une panne **transitoire** est rattrapée par la reprise.
#[tokio::test]
async fn une_panne_transitoire_est_rattrapee() {
    let bouchon = Bouchon::demarrer(vec![
        (503, "indisponible".to_owned()),
        (
            200,
            r#"{"reference":"agg-7","url_paiement":"https://pay.invalid/7"}"#.to_owned(),
        ),
    ])
    .await;

    let checkout = bouchon
        .client()
        .create_checkout(demande(3_000))
        .await
        .expect("la reprise rattrape le 503");

    assert_eq!(checkout.reference_fournisseur, "agg-7");
    assert_eq!(bouchon.recues().len(), 2);
}

/// Une réponse `200` qui n'est pas du JSON est `ChargeIllisible`, pas une
/// panique — un agrégateur qui rend une page HTML d'erreur derrière un `200`
/// n'est pas une hypothèse d'école.
#[tokio::test]
async fn une_reponse_non_json_est_illisible_pas_fatale() {
    let bouchon = Bouchon::demarrer(vec![(200, "<html>maintenance</html>".to_owned())]).await;
    let erreur = bouchon
        .client()
        .create_checkout(demande(1_000))
        .await
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::ChargeIllisible(_)), "{erreur}");
}

/// La consultation lit l'état d'un encaissement — c'est elle qui empêche un
/// webhook perdu de coûter la commande (R7, FR-027).
#[tokio::test]
async fn la_consultation_lit_l_etat_chez_le_fournisseur() {
    let reference_marchande = Uuid::now_v7();
    let bouchon = Bouchon::demarrer(vec![(
        200,
        format!(
            r#"{{"reference":"agg-9","reference_marchande":"{reference_marchande}",
                 "statut":"SUCCESS","montant":7500,"devise":"XOF","moyen":"WAVE"}}"#
        ),
    )])
    .await;

    let notification = bouchon
        .client()
        .consulter("agg-9")
        .await
        .expect("consultation acceptée");

    assert_eq!(notification.issue, IssuePaiement::Reussi);
    assert_eq!(notification.reference_marchande, Some(reference_marchande));
    assert_eq!(notification.montant_unites, 7_500);
    assert_eq!(notification.moyen, Some(MoyenPaiement::Wave));

    let recue = &bouchon.recues()[0];
    assert!(
        recue.ligne.starts_with("GET /checkouts/agg-9 "),
        "{}",
        recue.ligne,
    );
}

/// La vérification de notification emploie **le même** signataire que le
/// produit — pas une réimplémentation de test.
#[tokio::test]
async fn la_notification_signee_est_acceptee_et_traduite() {
    let bouchon = Bouchon::demarrer(vec![(200, "{}".to_owned())]).await;
    let client = bouchon.client();

    let reference_marchande = Uuid::now_v7();
    let corps = format!(
        r#"{{"reference":"agg-11","reference_marchande":"{reference_marchande}",
             "statut":"paid","montant":12500,"devise":"XOF","moyen":"orange"}}"#
    );
    let maintenant = chrono::Utc::now();
    let signature = client.signature().signer(corps.as_bytes(), maintenant);
    let entetes = EntetesNotification::depuis([("X-Signature", signature.as_str())]);

    let notification = client
        .verify_webhook(&NotificationEntrante {
            corps_brut: corps.as_bytes(),
            entetes: &entetes,
            recue_le: maintenant,
        })
        .expect("signature valide");

    assert_eq!(notification.issue, IssuePaiement::Reussi);
    assert_eq!(notification.montant_unites, 12_500);
    assert_eq!(notification.moyen, Some(MoyenPaiement::OrangeMoney));
    assert!(
        !notification.empreinte_charge.is_empty(),
        "l'empreinte du corps brut porte l'idempotence (R5)",
    );
}

/// Une signature **absente** ou **forgée** est refusée — et le corps n'est
/// jamais désérialisé avant la vérification (R6).
#[tokio::test]
async fn une_signature_absente_ou_forgee_est_refusee() {
    let bouchon = Bouchon::demarrer(vec![(200, "{}".to_owned())]).await;
    let client = bouchon.client();
    let corps = br#"{"reference":"x","statut":"paid","montant":1,"devise":"XOF"}"#;
    let maintenant = chrono::Utc::now();

    // Absente.
    let vides = EntetesNotification::default();
    let erreur = client
        .verify_webhook(&NotificationEntrante {
            corps_brut: corps,
            entetes: &vides,
            recue_le: maintenant,
        })
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::SignatureInvalide));

    // Forgée.
    let entetes = EntetesNotification::depuis([("x-signature", "t=1,v1=deadbeef")]);
    let erreur = client
        .verify_webhook(&NotificationEntrante {
            corps_brut: corps,
            entetes: &entetes,
            recue_le: maintenant,
        })
        .unwrap_err();
    assert!(matches!(erreur, ErreurFournisseur::SignatureInvalide));
}
