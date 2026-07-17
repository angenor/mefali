//! Surface réservée au DÉVELOPPEMENT : relire le dernier code OTP tracé.
//!
//! `SMS_MODE=traces` journalise déjà le code au lieu de l'envoyer (research
//! R6) ; ce module évite d'aller le tailler dans les logs de l'API pour
//! dérouler un parcours à la main sur un appareil.
//!
//! # Ce que ce module ne fait PAS
//!
//! Il ne touche pas au domaine OTP : il ne pose ni ne consomme de défi, ne lit
//! pas Redis, et ne connaît pas l'empreinte HMAC. Les garde-fous (3 essais, TTL
//! de 5 min, 3 SMS/h/numéro, 10 demandes/h/IP, réponses neutres — SC-002/003)
//! valent exactement pareil avec ou sans lui : il RELIT un journal d'envoi,
//! écrit par [`SmsTraces`], et rien d'autre. Le code rendu reste soumis à son
//! TTL et à ses essais.
//!
//! # Pourquoi le journal et pas Redis
//!
//! Redis ne détient que l'empreinte HMAC-SHA256 du code (`otp.rs`) — le code en
//! clair n'y est jamais. Sa seule trace est le journal mémoire de [`SmsTraces`],
//! d'où la lecture ici.
//!
//! # Montage
//!
//! Monté par le SEUL gate `prod` de `lib.rs`, celui de Swagger UI
//! (constitution VIII) : en production, la route n'existe pas — elle rend 404
//! comme n'importe quel chemin inconnu, sans même dire qu'elle aurait pu
//! exister. Le gate est en défaut FERMÉ (`AppEnv::depuis_env`) : cet endpoint
//! rend un code OTP en clair à qui connaît un numéro, soit la prise de contrôle
//! du compte — il ne doit pas dépendre d'un `.env` correctement rempli.

use actix_web::{web, HttpResponse, Responder};
use comptes::otp::{normaliser_e164, SMS_CODE_CLE};
use comptes::{PgComptes, SmsTraces};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use uuid::Uuid;

/// Requête : le numéro TEL QUE SAISI, et sa zone (comme `/auth/otp/demander`).
///
/// La zone n'est pas un ornement : l'indicatif par défaut en dépend (FR-024),
/// donc « 0707070707 » ne devient « +2250707070707 » que par elle.
#[derive(Debug, Deserialize)]
pub struct RequeteCodeDev {
    telephone: String,
    zone: Uuid,
}

/// Réponse : le dernier code tracé pour ce numéro.
#[derive(Debug, Serialize)]
pub struct CodeDev {
    /// Le code à 6 chiffres.
    code: String,
    /// Le numéro normalisé auquel il a été « envoyé » — permet de voir tout de
    /// suite qu'on interroge le numéro qu'on croit.
    telephone_e164: String,
}

/// `GET /dev/otp?telephone=…&zone=…` — dernier code OTP tracé pour ce numéro.
///
/// Hors contrat OpenAPI, délibérément : le contrat est public et généré en
/// clients Dart/TS ; une surface qui n'existe pas en production n'a rien à y
/// faire, et un client généré ne doit pas savoir l'appeler.
///
/// 404 quand aucun code n'a été tracé — cas le plus fréquent d'un plafond
/// atteint : `/auth/otp/demander` a rendu 202 (neutre, SC-003) SANS envoyer de
/// SMS. Le message le dit, pour ne pas laisser chercher un code qui n'existe
/// pas (piège noté en mémoire : Redis à vider entre deux essais).
pub async fn dernier_code(
    depot: web::Data<PgComptes>,
    traces: web::Data<Arc<SmsTraces>>,
    requete: web::Query<RequeteCodeDev>,
) -> impl Responder {
    let e164 = match normaliser_e164(depot.zones(), requete.zone, &requete.telephone).await {
        Ok(e164) => e164,
        Err(e) => {
            return HttpResponse::BadRequest().json(serde_json::json!({
                "erreur": format!("numéro ou zone inexploitable : {e}"),
            }))
        }
    };

    // Le DERNIER d'abord : un renvoi de code périme le précédent, et c'est
    // toujours le plus récent qu'on cherche.
    match traces
        .envoyes()
        .into_iter()
        .rev()
        .find(|sms| sms.e164 == e164 && sms.message_cle == SMS_CODE_CLE)
        .and_then(|sms| sms.params.get("code")?.as_str().map(str::to_owned))
    {
        Some(code) => HttpResponse::Ok().json(CodeDev {
            code,
            telephone_e164: e164,
        }),
        None => HttpResponse::NotFound().json(serde_json::json!({
            "erreur": format!(
                "aucun code tracé pour {e164} — le SMS n'est peut-être pas parti \
                 (plafond atteint : /auth/otp/demander répond 202 sans envoyer)",
            ),
        })),
    }
}
