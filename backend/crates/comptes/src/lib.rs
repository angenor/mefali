//! Crate `comptes` — Comptes, authentification OTP et rôles (cycle 003).
//!
//! Identité Mefali = un numéro E.164 vérifié par OTP, rien d'autre. Autour :
//! des sessions par appareil (jeton d'accès court + refresh révocable, R1/R2),
//! des rôles CUMULABLES portés par une UNIQUE machine à états (R9), le dossier
//! coursier (CPT-04) et les adresses à repère vocal (CPT-05).
//!
//! Domaine PUR (constitution II) : l'infrastructure n'entre que par les ports
//! [`DepotEphemere`] (Redis), [`EnvoiSms`] (fournisseur NTF) et [`DepotObjets`]
//! (Garage/S3), dont les impls réelles vivent dans la couche `api`.
//!
//! Découpage identique au cycle 002 :
//! - LECTURES : le trait `Comptes`, consommé par les modules suivants — la
//!   porte de mise en ligne du coursier (CRS) et le filtre de transport (DSP) ;
//! - ÉCRITURES : méthodes inhérentes de `PgComptes` sur `&mut PgTransaction`,
//!   de sorte que l'atomicité « transition + événement outbox » soit
//!   impossible à contourner (constitution VI).

pub mod depot;
pub mod inscription;
pub mod modele;
pub mod otp;
pub mod ports;
pub mod session;
#[cfg(test)]
mod test_zones;

pub use depot::{Comptes, PgComptes};
pub use inscription::{IssueVerification, SessionOuverte};
pub use modele::{
    Adresse, Appareil, AttributionRole, Compte, DossierCoursier, ErreurComptes, ErreurEphemere,
    ErreurObjets, ErreurSms, OrigineRevocation, Plateforme, Role, Session, StatutRole,
    TypeTransport, VehiculeDeclare,
};
pub use ports::{
    Compteur, DepotEphemere, DepotObjets, EnvoiSms, HorlogeManuelle, IssueDefi, JetonInscription,
    MemoireEphemere, MemoireObjets, SmsEnvoye, SmsTraces, UrlPresignee,
};
pub use session::{verifier_acces, Claims, Jetons, OrigineSession, ACCES_TTL};
