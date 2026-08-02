//! Surface HTTP **FOURNISSEUR** — la seule route non authentifiée du produit.
//!
//! Un agrégateur ne porte pas de JWT : la notification vient d'un tiers, pas
//! d'un utilisateur. Sa garde est **cryptographique** (plan.md, Complexity
//! Tracking ligne 1) — signature HMAC vérifiée sur le corps brut avant toute
//! désérialisation.
//!
//! # Pourquoi un corps BRUT (`web::Bytes`) et jamais `web::Json`
//!
//! `web::Json` désérialiserait le corps **avant** que le handler ne s'exécute,
//! donc avant toute vérification de signature : on ferait confiance à la
//! structure d'un inconnu, et la signature ne porterait plus sur les octets
//! réellement reçus mais sur une re-sérialisation. Un espace en plus, un ordre
//! de clés différent, et la vérification échoue sur une notification honnête —
//! ou pire, réussit sur une falsifiée (research R6).
//!
//! Le plafond de 64 Kio est posé par [`config_payload`], enregistrée au niveau
//! de l'application : actix **coupe pendant la réception** et rend `413` de
//! lui-même. Le contrôle en tête de handler n'est qu'une seconde barrière, au
//! cas où cette configuration serait oubliée sur un point de montage.
//!
//! # Les trois protections d'une surface publique
//!
//! 1. **Corps plafonné à 64 Kio** — une notification de paiement pèse quelques
//!    centaines d'octets ; au-delà, ce n'est plus une notification.
//! 2. **Débit limité par IP** — le gouverneur global protège toute l'API ;
//!    celui-ci est propre au webhook et beaucoup plus serré, parce qu'un
//!    agrégateur légitime n'envoie pas cent notifications par seconde.
//! 3. **Swagger UI exclu en production** — assuré en amont par `mount_docs`,
//!    qui ne monte l'interface que hors production (constitution VIII).
//!
//! # Le segment `{fournisseur}`
//!
//! Il sélectionne l'implémentation à laquelle déléguer la vérification. C'est
//! **le point d'accroche du routage de phase 2+** (FR-043) : aujourd'hui il ne
//! porte aucune règle, et un fournisseur inconnu répond `404`. Le nommer dès
//! maintenant évite qu'ajouter un second fournisseur demande de changer l'URL
//! déclarée chez le premier — ce qui, chez un agrégateur, est une démarche
//! commerciale, pas un déploiement.

use std::collections::HashMap;
use std::net::IpAddr;
use std::sync::{LazyLock, Mutex};
use std::time::{Duration, Instant};

use actix_web::{post, web, HttpRequest, HttpResponse};
use paiements::{EntetesNotification, NotificationEntrante, PaymentProvider, PgPaiements};
use serde::Serialize;
use std::sync::Arc;
use utoipa::ToSchema;

use crate::erreurs_paiements::ErreurPaiementsHttp;

/// Taille maximale d'une notification acceptée (64 Kio).
pub const CORPS_MAX_OCTETS: usize = 64 * 1024;

/// Plafond de corps brut, à enregistrer sur l'application.
///
/// Actix coupe la réception au-delà et rend `413` sans que le handler ne soit
/// jamais appelé : un corps démesuré n'est donc pas bufferisé avant d'être
/// refusé. **Le webhook est la seule route du produit à extraire un corps
/// brut** (`web::Bytes`), donc ce plafond ne restreint personne d'autre — les
/// corps JSON ont leur propre `JsonConfig`, et le multipart le sien.
pub fn config_payload() -> web::PayloadConfig {
    web::PayloadConfig::new(CORPS_MAX_OCTETS)
}

/// Fenêtre de limitation de débit du webhook.
pub const FENETRE_DEBIT: Duration = Duration::from_secs(10);

/// Notifications acceptées par IP et par fenêtre.
///
/// Large pour un agrégateur (un lot de retentes après incident passe), serré
/// pour quelqu'un qui sonde des signatures : cent essais par dix secondes ne
/// permettent pas de forcer un HMAC-SHA256, et le refus est journalisé.
pub const DEBIT_MAX: usize = 100;

/// Ce que le webhook répond — **toujours `200`, sauf signature invalide**.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ReponseNotification)]
pub struct ReponseNotificationDto {
    /// Vrai si la notification a produit un effet.
    pub traite: bool,
    /// Pourquoi elle n'en a produit aucun : `rejeu`, `en_cours`, `orpheline`,
    /// `etat_incompatible`, `divergence`. Absent quand `traite` vaut `true`.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub motif: Option<String>,
}

/// Notification signée d'un fournisseur de paiement.
#[utoipa::path(
    post,
    path = "/paiements/notifications/{fournisseur}",
    tag = "paiements",
    params(("fournisseur" = String, Path,
            description = "Identifiant stable de l'implémentation destinataire. Point d'accroche \
                           du routage par moyen (phase 2+) — sans règle aujourd'hui.")),
    request_body(content = String, description = "Charge BRUTE du fournisseur, signée. Jamais \
                 désérialisée avant vérification de la signature. Plafonnée à 64 Kio.",
                 content_type = "application/json"),
    responses(
        (status = 200, description = "Notification traitée, ou sans effet avec son motif. Un \
         rejeu répond 200 `{traite: false, motif: \"rejeu\"}` et NON une erreur : un fournisseur \
         qui reçoit une erreur retente en boucle (FR-022).", body = ReponseNotificationDto),
        (status = 401, description = "Signature absente, invalide ou périmée. Une ligne de \
         notification refusée est écrite ; rien d'autre, et jamais le corps reçu (FR-020)."),
        (status = 404, description = "Segment `{fournisseur}` inconnu."),
        (status = 413, description = "Corps au-delà de 64 Kio — coupé pendant la réception."),
        (status = 429, description = "Débit dépassé pour cette adresse."),
    ),
)]
#[post("/paiements/notifications/{fournisseur}")]
pub async fn recevoir_notification(
    requete: HttpRequest,
    chemin: web::Path<String>,
    corps: web::Bytes,
    paiements: web::Data<PgPaiements>,
    commandes: web::Data<commandes::PgCommandes>,
    fournisseur: web::Data<Arc<dyn PaymentProvider>>,
) -> Result<HttpResponse, ErreurPaiementsHttp> {
    let segment = chemin.into_inner();
    let fournisseur = fournisseur.get_ref().as_ref();

    // Aucune règle métier ne lit ce nom (FR-003) : il ne sert qu'à choisir à
    // qui déléguer la vérification. Le comparer ici est un aiguillage, pas une
    // décision d'argent. La garde vient AVANT la lecture du corps : inutile de
    // recevoir 64 Kio pour une route qui n'existe pas.
    if segment != fournisseur.nom() {
        return Err(paiements::ErreurPaiements::FournisseurInconnu(segment).into());
    }

    if let Some(ip) = ip_appelante(&requete) {
        if !LIMITEUR.autorise(ip) {
            tracing::warn!(
                fournisseur = fournisseur.nom(),
                "débit de notifications dépassé — requête refusée",
            );
            return Ok(HttpResponse::TooManyRequests().json(serde_json::json!({
                "code": "debit_depasse",
                "message_cle": "paiement.erreur.debit_depasse",
            })));
        }
    }

    // Seconde barrière. La première est `config_payload`, qui coupe pendant la
    // réception ; celle-ci ne sert que si un point de montage l'oubliait — et
    // un plafond qui dépend d'un enregistrement fait ailleurs mérite sa
    // ceinture.
    if corps.len() > CORPS_MAX_OCTETS {
        tracing::warn!(
            fournisseur = fournisseur.nom(),
            plafond = CORPS_MAX_OCTETS,
            "notification au-delà du plafond",
        );
        return Ok(HttpResponse::PayloadTooLarge().json(serde_json::json!({
            "code": "corps_trop_grand",
            "message_cle": "paiement.erreur.corps_trop_grand",
        })));
    }

    let entetes = EntetesNotification::depuis(
        requete
            .headers()
            .iter()
            .filter_map(|(nom, valeur)| valeur.to_str().ok().map(|v| (nom.as_str(), v))),
    );

    let resultat = paiements::traiter_notification(
        paiements.get_ref(),
        commandes.get_ref(),
        fournisseur,
        NotificationEntrante {
            corps_brut: &corps,
            entetes: &entetes,
            recue_le: paiements.maintenant(),
        },
    )
    .await?;

    Ok(HttpResponse::Ok().json(ReponseNotificationDto {
        traite: resultat.traite,
        motif: resultat.motif.map(str::to_owned),
    }))
}

/// Adresse de l'appelant, telle que le serveur la voit.
fn ip_appelante(requete: &HttpRequest) -> Option<IpAddr> {
    requete.peer_addr().map(|a| a.ip())
}

/// Limiteur de débit par IP, propre au webhook.
///
/// En mémoire du processus, et c'est suffisant : l'API tourne en un seul
/// processus sur un VPS unique (plan.md). Le porter en Redis ajouterait une
/// dépendance réseau sur le chemin d'une route qui doit répondre vite, pour une
/// précision dont personne n'a besoin ici.
///
/// ⚠ Ce compteur ne porte **aucune** garantie d'argent : l'idempotence des
/// paiements repose sur une contrainte de base, jamais sur un cache (research
/// R5). Il ne fait que fermer la porte au bruit.
static LIMITEUR: LazyLock<LimiteurIp> =
    LazyLock::new(|| LimiteurIp::nouveau(FENETRE_DEBIT, DEBIT_MAX));

struct LimiteurIp {
    fenetre: Duration,
    max: usize,
    /// Nombre d'entrées au-delà duquel on purge les fenêtres écoulées.
    ///
    /// Sans ce plafond, un flot d'adresses forgées ferait croître la table
    /// indéfiniment — le limiteur deviendrait lui-même le levier de saturation
    /// qu'il existe pour empêcher.
    plafond_entrees: usize,
    etat: Mutex<HashMap<IpAddr, (Instant, usize)>>,
}

impl LimiteurIp {
    fn nouveau(fenetre: Duration, max: usize) -> Self {
        Self {
            fenetre,
            max,
            plafond_entrees: 10_000,
            etat: Mutex::new(HashMap::new()),
        }
    }

    /// Vrai si cette adresse peut envoyer une notification de plus.
    fn autorise(&self, ip: IpAddr) -> bool {
        let maintenant = Instant::now();
        // Un verrou empoisonné (panique d'un autre fil pendant la mise à jour)
        // ne doit pas faire tomber la route : on récupère l'état plutôt que de
        // propager la panique à toutes les requêtes suivantes.
        let mut etat = match self.etat.lock() {
            Ok(etat) => etat,
            Err(empoisonne) => empoisonne.into_inner(),
        };

        if etat.len() > self.plafond_entrees {
            etat.retain(|_, (debut, _)| maintenant.duration_since(*debut) < self.fenetre);
        }

        let entree = etat.entry(ip).or_insert((maintenant, 0));
        if maintenant.duration_since(entree.0) >= self.fenetre {
            *entree = (maintenant, 0);
        }
        entree.1 += 1;
        entree.1 <= self.max
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ip(dernier: u8) -> IpAddr {
        IpAddr::from([127, 0, 0, dernier])
    }

    /// Le quota est atteint puis refusé — et la fenêtre suivante le rouvre.
    #[test]
    fn le_quota_se_ferme_puis_se_rouvre() {
        let limiteur = LimiteurIp::nouveau(Duration::from_millis(50), 3);
        assert!(limiteur.autorise(ip(1)));
        assert!(limiteur.autorise(ip(1)));
        assert!(limiteur.autorise(ip(1)));
        assert!(!limiteur.autorise(ip(1)), "le 4ᵉ dépasse le quota de 3");

        std::thread::sleep(Duration::from_millis(60));
        assert!(
            limiteur.autorise(ip(1)),
            "la fenêtre écoulée rouvre le quota",
        );
    }

    /// Une adresse ne consomme pas le quota d'une autre — sinon un attaquant
    /// couperait le webhook pour l'agrégateur légitime.
    #[test]
    fn les_adresses_ne_se_partagent_pas_leur_quota() {
        let limiteur = LimiteurIp::nouveau(Duration::from_secs(10), 2);
        assert!(limiteur.autorise(ip(1)));
        assert!(limiteur.autorise(ip(1)));
        assert!(!limiteur.autorise(ip(1)));
        assert!(
            limiteur.autorise(ip(2)),
            "l'adresse voisine garde son propre quota",
        );
    }

    /// La table ne croît pas indéfiniment : au-delà du plafond, les fenêtres
    /// écoulées sont purgées.
    #[test]
    fn la_table_est_purgee_au_dela_du_plafond() {
        let mut limiteur = LimiteurIp::nouveau(Duration::from_millis(1), 100);
        limiteur.plafond_entrees = 4;
        for i in 0..5u8 {
            limiteur.autorise(ip(i));
        }
        std::thread::sleep(Duration::from_millis(5));
        limiteur.autorise(ip(200));
        assert!(
            limiteur.etat.lock().unwrap().len() <= 2,
            "les fenêtres écoulées ont été purgées",
        );
    }

    /// Le plafond de corps est celui du contrat, et il est LARGE devant une
    /// notification réelle (quelques centaines d'octets).
    #[test]
    fn le_plafond_de_corps_est_celui_du_contrat() {
        assert_eq!(CORPS_MAX_OCTETS, 65_536);
    }
}
