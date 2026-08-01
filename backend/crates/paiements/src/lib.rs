//! Crate `paiements` — chaîne d'argent : prépaiement mobile money et anomalies.
//!
//! Le cycle PAY 011 remplit le crate posé **vide au socle** (« prêt ≠
//! construit », constitution IX), exactement comme le cycle 010 l'a fait pour
//! `coursier`. Il ne réécrit rien : il **branche** les chemins que le cycle 008
//! avait laissés ouverts (`confirmer_prepaiement`, l'annulation), **comble**
//! deux trous du code livré (`etat_paiement = 'en_attente'` jamais posé, montant
//! à encaisser faux sur une commande prépayée) et **ajoute** la seule chose qui
//! manquait vraiment : un fournisseur.
//!
//! | Module | Rôle |
//! |---|---|
//! | [`modele`] | types purs, machine à états de la transaction, erreurs et clés i18n |
//! | [`config`] | les 4 paramètres de zone du cycle, hérités pays → ville |
//! | [`fournisseur`] | **la frontière réversible** — trait, double, agrégateur HTTP |
//! | [`session`] | ouverture idempotente, état, temps restant |
//! | [`webhook`] | signature → idempotence → confirmation |
//! | [`expiration`] | réconciliation **puis** annulation |
//! | [`dossier`] | anomalies d'argent, et le consommateur outbox qui les ouvre |
//! | [`registre`] | lectures d'exploitation |
//! | [`depot`] | `PgPaiements` — racine de composition du domaine |
//!
//! Conventions du dépôt : **lectures sur pool**, **écritures sur
//! `&mut PgTransaction`** avec l'événement outbox dans la MÊME transaction
//! (constitution VI). Montants en entiers d'unités mineures + devise ISO 4217
//! (III) — aucun flottant n'entre dans ce crate, y compris dans les échanges
//! avec le fournisseur.
//!
//! # La frontière, et pourquoi elle est mécanique
//!
//! Le cadrage §10.7 dit l'agrégateur **non choisi**. Tout ce qui lui est propre
//! — vocabulaire, codes d'état, algorithme de signature, forme des montants —
//! est confiné à [`fournisseur`]. Aucun nom d'agrégateur n'apparaît ailleurs, et
//! `scripts/verifier-frontiere-paiement.sh` le vérifie en CI plutôt que de
//! l'espérer (SC-010, FR-003).
//!
//! Le corollaire tient en une phrase : **aucune règle métier de ce crate ne lit
//! `transaction.fournisseur` ni `transaction.reference_fournisseur`.** Ces
//! colonnes existent pour rapprocher les comptes, jamais pour décider.
//!
//! # Ce que ce crate ne fait pas, et pourquoi
//!
//! - Il **n'écrit pas dans le schéma `coursier`** : la créance est de la caisse
//!   (research R12). Ce qu'il ne peut pas atteindre par dépendance, il l'atteint
//!   par l'outbox — `dossier::PaiementsOutbox`.
//! - Il **n'appelle jamais `refund`** : PAY-04 est hors périmètre. La méthode
//!   est définie pour honorer PAY-05, et un test vérifie qu'aucun chemin de code
//!   ne l'invoque (FR-041, FR-111).
//! - Il **ne rembourse ni ne ressuscite** une commande annulée : un succès
//!   tardif ouvre un dossier (R8).

pub mod config;
pub mod depot;
pub mod fournisseur;
pub mod modele;

pub use config::{cles as cles_config, ConfigPaiements};
pub use depot::PgPaiements;
pub use fournisseur::{
    Checkout, DemandeCheckout, DemandeRemboursement, EntetesNotification, ErreurFournisseur,
    FournisseurSimule, IssuePaiement, Notification, NotificationEntrante, PaymentProvider,
    Remboursement, ScenarioSimule,
};
pub use modele::{
    transition_existe, verifier_transition, Dossier, ErreurPaiements, EtatDossier, EtatTransaction,
    MoyenPaiement, Transaction, TypeDossier,
};
