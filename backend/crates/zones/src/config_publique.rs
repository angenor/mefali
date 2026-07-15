//! Assemblage du document de configuration produit public (ZON-04, research R3/R4).
//!
//! LISTE BLANCHE de namespaces (constitution VIII, clarification Q1) : seuls
//! `devise`, `drapeau.*`, `texte.*`, `client.*` + les vues dérivées `categories`
//! (actives), `transports_actifs`, `note_vocale_duree_max_s` et
//! `consentement_artci_version` sortent par `/config`. Les namespaces internes
//! (`dispatch.*`, `tarification.*`, `categorie.*.seuil_activation`,
//! `transport.actifs` brut…) ne sont JAMAIS exposés.
//!
//! Une vue DÉRIVÉE est la porte de sortie d'un paramètre interne dont le client
//! a un besoin légitime et borné : `transport.actifs` devient `transports_actifs`
//! parce que le coursier doit savoir quoi déclarer ; `medias.note_vocale_duree_max_s`
//! devient `note_vocale_duree_max_s` parce que l'enregistreur doit se borner
//! lui-même ; `consentement.artci_version` devient `consentement_artci_version`
//! parce que l'app doit ENVOYER la version du texte qu'elle a réellement affiché
//! (FR-006/FR-024 : jamais en dur dans l'app). Élargir la liste blanche à ces
//! namespaces entiers exposerait, lui, tout ce qu'ils contiendront demain.
//!
//! `version` = SHA-256 (hex) du document canonique servi (clés triées) : elle
//! change si et seulement si la configuration effective change, y compris via un
//! ancêtre (FR-019) ; déterministe → ETag HTTP gratuit + seeds rejouables (SC-008).

use std::collections::BTreeMap;

use serde::{Deserialize, Serialize};
use serde_json::Value;
use sha2::{Digest, Sha256};
use uuid::Uuid;

use crate::modele::{CategorieActive, ConfigurationEffective, Devise};

/// Document `/config` — sous-ensemble public de la configuration effective.
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct ConfigZonePublique {
    /// Zone servie.
    pub zone: Uuid,
    /// Empreinte SHA-256 (hex) du document canonique (hors ce champ).
    pub version: String,
    /// Devise résolue.
    pub devise: Devise,
    /// Drapeaux (clés `drapeau.*` sans préfixe).
    pub drapeaux: BTreeMap<String, bool>,
    /// Catégories ACTIVES (slug, clé i18n de nom, mixable).
    pub categories: Vec<CategorieActive>,
    /// Slugs des types de transport actifs (vue dérivée).
    pub transports_actifs: Vec<String>,
    /// Durée maximale d'une note vocale, en secondes (vue dérivée de
    /// `medias.note_vocale_duree_max_s`).
    ///
    /// `None` si la zone ne la résout pas : l'app doit alors laisser le serveur
    /// trancher plutôt que d'inventer une borne (FR-024).
    pub note_vocale_duree_max_s: Option<i64>,
    /// Version du texte de consentement ARTCI en vigueur dans la zone (vue
    /// dérivée de `consentement.artci_version`).
    ///
    /// L'app l'affiche et la RENVOIE telle quelle à l'inscription (FR-006) :
    /// c'est ce qui permet de changer le texte par la configuration, sans
    /// release. `None` si la zone ne la résout pas.
    pub consentement_artci_version: Option<String>,
    /// Textes (clés `texte.*` sans préfixe) — clés i18n fr.
    pub textes: BTreeMap<String, String>,
    /// Paramètres client (clés `client.*` sans préfixe).
    pub parametres: BTreeMap<String, Value>,
}

/// Construit le document public à partir de la configuration effective résolue
/// et des vues dérivées (devise, catégories actives, transports actifs). Applique
/// la liste blanche puis calcule la `version`.
pub fn assembler(
    config: &ConfigurationEffective,
    devise: Devise,
    categories: Vec<CategorieActive>,
    transports_actifs: Vec<String>,
) -> ConfigZonePublique {
    let mut drapeaux = BTreeMap::new();
    let mut textes = BTreeMap::new();
    let mut parametres = BTreeMap::new();

    for (cle, vp) in &config.valeurs {
        if let Some(suffixe) = cle.strip_prefix("drapeau.") {
            if let Some(b) = vp.valeur.as_bool() {
                drapeaux.insert(suffixe.to_owned(), b);
            }
        } else if let Some(suffixe) = cle.strip_prefix("texte.") {
            if let Some(s) = vp.valeur.as_str() {
                textes.insert(suffixe.to_owned(), s.to_owned());
            }
        } else if let Some(suffixe) = cle.strip_prefix("client.") {
            parametres.insert(suffixe.to_owned(), vp.valeur.clone());
        }
        // devise.*, categorie.*, transport.actifs, medias.*, dispatch.*… : NON
        // exposés tels quels — seules leurs vues dérivées le sont.
    }

    let note_vocale_duree_max_s = config
        .valeurs
        .get("medias.note_vocale_duree_max_s")
        .and_then(|vp| vp.valeur.as_i64());
    let consentement_artci_version = config
        .valeurs
        .get("consentement.artci_version")
        .and_then(|vp| vp.valeur.as_str().map(str::to_owned));

    let mut document = ConfigZonePublique {
        zone: config.zone,
        version: String::new(),
        devise,
        drapeaux,
        categories,
        transports_actifs,
        note_vocale_duree_max_s,
        consentement_artci_version,
        textes,
        parametres,
    };
    document.version = empreinte(&document);
    document
}

/// SHA-256 hex du document canonique (JSON à clés triées, hors `version`).
fn empreinte(document: &ConfigZonePublique) -> String {
    let mut valeur = serde_json::to_value(document).expect("sérialisation du document config");
    if let Some(objet) = valeur.as_object_mut() {
        objet.remove("version");
    }
    // serde_json::Map = BTreeMap par défaut → clés triées → sérialisation canonique.
    let canonique = serde_json::to_vec(&valeur).expect("sérialisation canonique");
    let digest = Sha256::digest(&canonique);
    digest.iter().map(|octet| format!("{octet:02x}")).collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;

    fn config(valeurs: &[(&str, Value)]) -> ConfigurationEffective {
        use crate::modele::ValeurProvenance;
        let zone = Uuid::from_u128(1);
        let mut map = BTreeMap::new();
        for (cle, valeur) in valeurs {
            map.insert(
                (*cle).to_owned(),
                ValeurProvenance {
                    valeur: valeur.clone(),
                    provenance: zone,
                },
            );
        }
        ConfigurationEffective { zone, valeurs: map }
    }

    fn xof() -> Devise {
        Devise {
            code: "XOF".to_owned(),
            decimales: 0,
        }
    }

    /// Deux assemblages identiques → même version (déterminisme, SC-008).
    #[test]
    fn determinisme() {
        let c = config(&[("drapeau.pluie", json!(false)), ("texte.a", json!("x"))]);
        let a = assembler(&c, xof(), vec![], vec!["a_pied".to_owned()]);
        let b = assembler(&c, xof(), vec![], vec!["a_pied".to_owned()]);
        assert_eq!(a.version, b.version);
        assert!(!a.version.is_empty());
    }

    /// Changement d'un paramètre (même provenant d'un ancêtre) → version change (FR-019).
    #[test]
    fn changement_parametre_change_version() {
        let a = assembler(
            &config(&[("drapeau.pluie", json!(false))]),
            xof(),
            vec![],
            vec![],
        );
        let b = assembler(
            &config(&[("drapeau.pluie", json!(true))]),
            xof(),
            vec![],
            vec![],
        );
        assert_ne!(a.version, b.version);
    }

    /// Les namespaces internes ne sortent jamais du document public (liste blanche R4).
    #[test]
    fn parametres_internes_absents() {
        let c = config(&[
            ("drapeau.pluie", json!(false)),
            ("dispatch.rayon_km", json!(3)),
            ("categorie.marche.seuil_activation", json!(3)),
            ("transport.actifs", json!(["a_pied"])),
            ("client.theme", json!("clair")),
            ("texte.bandeau", json!("Bienvenue")),
        ]);
        let doc = assembler(&c, xof(), vec![], vec!["a_pied".to_owned()]);

        assert_eq!(doc.drapeaux.get("pluie"), Some(&false));
        assert_eq!(
            doc.textes.get("bandeau").map(String::as_str),
            Some("Bienvenue")
        );
        assert_eq!(doc.parametres.get("theme"), Some(&json!("clair")));
        assert_eq!(doc.transports_actifs, vec!["a_pied"]);

        let rendu = serde_json::to_string(&doc).unwrap();
        assert!(!rendu.contains("dispatch"), "namespace interne exposé");
        assert!(!rendu.contains("rayon_km"));
        assert!(!rendu.contains("seuil_activation"));
    }

    /// FR-019/FR-024 — la durée max de note vocale sort en vue DÉRIVÉE : les
    /// apps doivent borner leur enregistreur sans jamais coder 30 en dur.
    #[test]
    fn duree_max_note_vocale_derivee_sans_exposer_le_namespace() {
        let c = config(&[
            ("medias.note_vocale_duree_max_s", json!(30)),
            ("medias.futur_parametre_interne", json!("secret")),
        ]);
        let doc = assembler(&c, xof(), vec![], vec![]);

        assert_eq!(doc.note_vocale_duree_max_s, Some(30));
        let rendu = serde_json::to_string(&doc).unwrap();
        assert!(
            !rendu.contains("futur_parametre_interne"),
            "la vue dérivée expose UNE valeur, pas le namespace `medias.*` entier"
        );
        assert!(!rendu.contains("secret"));
    }

    /// Une zone qui ne résout pas la durée ne la rend pas : l'app laissera le
    /// serveur trancher plutôt que d'inventer une borne.
    #[test]
    fn duree_max_note_vocale_absente_rend_null() {
        let doc = assembler(&config(&[]), xof(), vec![], vec![]);
        assert_eq!(doc.note_vocale_duree_max_s, None);
    }

    /// FR-006/FR-024 — la version du texte ARTCI sort en vue dérivée : l'app
    /// doit RENVOYER la version qu'elle a affichée, sans jamais la coder en dur.
    #[test]
    fn version_artci_derivee_sans_exposer_le_namespace() {
        let c = config(&[
            ("consentement.artci_version", json!("2026-07")),
            ("consentement.texte_interne", json!("brouillon juridique")),
        ]);
        let doc = assembler(&c, xof(), vec![], vec![]);

        assert_eq!(doc.consentement_artci_version.as_deref(), Some("2026-07"));
        let rendu = serde_json::to_string(&doc).unwrap();
        assert!(
            !rendu.contains("brouillon juridique"),
            "la vue dérivée expose UNE valeur, pas le namespace `consentement.*` entier"
        );
    }

    #[test]
    fn version_artci_absente_rend_null() {
        let doc = assembler(&config(&[]), xof(), vec![], vec![]);
        assert_eq!(doc.consentement_artci_version, None);
    }
}
