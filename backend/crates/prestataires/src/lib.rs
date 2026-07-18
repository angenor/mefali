//! Crate `prestataires` — Prestataires agréés et catalogue vendeur (cycle 005).
//!
//! L'entité générale est le PRESTATAIRE — agrément, charte signée, identité de
//! plaque (jeton HMAC + code de secours), sites, plan ; le VENDEUR en est la
//! spécialisation MVP, qui porte le catalogue et le stock. Un artisan de
//! phase N sera un autre type de prestataire réutilisant tout le socle sans
//! migration (cadrage §11.13, constitution II).
//!
//! Dérivations structurantes (specs/005) : la validité du jeton de plaque, la
//! commandabilité, l'état effectif de boutique et les capacités vendeur d'un
//! compte rattaché DÉRIVENT toutes de l'état d'agrément — aucune cascade,
//! aucune liste de révocation, aucun ordonnanceur.
//!
//! Découpage des cycles 002/003 :
//! - LECTURES : traits `Prestataires` (entité générale — QRC, CMD, WEB, CRS)
//!   et `Vendeurs` (spécialisation — CMD), impl `PgPrestataires` ;
//! - ÉCRITURES : méthodes inhérentes de `PgPrestataires` sur
//!   `&mut PgTransaction` — l'atomicité « transition + événement outbox » est
//!   impossible à contourner (constitution VI).

pub mod modele;

pub use modele::{ErreurPrestataires, SourceBascule, StatutBoutique, StatutPrestataire};
