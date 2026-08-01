//! Les **7 paramètres de zone** du cycle, plus le seuil d'essais **existant**
//! qu'il réutilise (research R17, R5).
//!
//! Constitution I : aucun de ces nombres n'existe en dur dans le code. Une clé
//! absente est une **erreur de configuration**, jamais un défaut silencieux
//! (patron `dispatch::config` et `parametre_i64` du cycle 008) — une exigence de
//! présence qui tomberait à 0 par accident rendrait tous les échecs déclarables
//! sans preuve, en silence.
//!
//! **Un paramètre réutilisé, jamais redéclaré** : `commande.essais_code_livraison`
//! = 3 vit depuis le cycle 008 et est lu en production par `valider_remise`. En
//! créer un second (`coursier.essais_…`) aurait donné deux clés pour un même
//! seuil ; elles auraient divergé au premier réglage d'exploitation, et la
//! moitié du code aurait bloqué à 3 pendant que l'autre bloquait à 5 (FR-106).
//!
//! **Pourquoi refuser au chargement plutôt qu'au moment d'agir.** Les deux
//! incohérences que ce module attrape ne produisent pas d'erreur : elles
//! produisent une preuve **truquée**. Un espacement d'appels supérieur à la
//! durée de présence exigée rend la preuve « appels » impossible à réunir dans
//! le temps que la preuve « présence » accorde ; un trou plus long que la
//! présence exigée fait passer un aller-retour pour une attente. Les deux se
//! remarquent des semaines plus tard, à la première contestation.

use uuid::Uuid;
use zones::ConfigurationZones;

use crate::modele::{ErreurCoursier, SeuilsPreuves};

/// Clés des paramètres — le seul endroit où ces chaînes sont écrites.
pub mod cles {
    /// Appels `client_absent` exigés par la preuve d'échec.
    pub const PREUVE_APPELS_MIN: &str = "coursier.preuve_appels_min";
    /// Espacement minimal entre deux appels retenus (secondes).
    pub const PREUVE_APPELS_ESPACEMENT_S: &str = "coursier.preuve_appels_espacement_s";
    /// Présence continue exigée sur le lieu de livraison (secondes).
    pub const PREUVE_PRESENCE_S: &str = "coursier.preuve_presence_s";
    /// Rayon dans lequel un relevé compte comme « sur place » (mètres).
    pub const PREUVE_PRESENCE_RAYON_M: &str = "coursier.preuve_presence_rayon_m";
    /// Intervalle au-delà duquel deux relevés ne comptent plus comme une
    /// présence continue (secondes) — ce qui distingue une attente d'un
    /// aller-retour (R8).
    pub const PREUVE_PRESENCE_TROU_MAX_S: &str = "coursier.preuve_presence_trou_max_s";
    /// Rétention de la photo de preuve d'échec (jours).
    pub const RETENTION_PHOTO_PREUVE_JOURS: &str = "coursier.retention_photo_preuve_jours";
    /// Période d'interrogation d'offre en ARRIÈRE-PLAN (secondes) — le premier
    /// plan garde la sienne (R13).
    pub const OFFRE_INTERROGATION_ARRIERE_PLAN_S: &str =
        "coursier.offre_interrogation_arriere_plan_s";

    // ── RÉUTILISÉ — propriétaire : cycle 008 ──────────────────────────────
    /// Essais du code de remise avant blocage. **Existe depuis le cycle 008**
    /// (`60_commandes_parametres.sql`) et lu en production : ce cycle le lit,
    /// il ne le redéclare pas (R5, FR-106).
    pub const ESSAIS_CODE_LIVRAISON: &str = "commande.essais_code_livraison";

    /// Les 7 clés créées par ce cycle — l'inventaire opposable.
    ///
    /// `ESSAIS_CODE_LIVRAISON` n'y est **pas** : il appartient au cycle 008.
    pub const TOUTES: [&str; 7] = [
        PREUVE_APPELS_MIN,
        PREUVE_APPELS_ESPACEMENT_S,
        PREUVE_PRESENCE_S,
        PREUVE_PRESENCE_RAYON_M,
        PREUVE_PRESENCE_TROU_MAX_S,
        RETENTION_PHOTO_PREUVE_JOURS,
        OFFRE_INTERROGATION_ARRIERE_PLAN_S,
    ];
}

/// Photos de preuve exigées par une déclaration d'échec.
///
/// **Pas un paramètre de zone**, et c'est délibéré : la maquette K4-1e affiche
/// « 1 photo » comme une des trois preuves, et le compteur « N sur 3 » n'a de
/// sens que si chaque preuve est une. Rendre ce nombre réglable permettrait
/// d'écrire 0 — c'est-à-dire de supprimer une preuve sans toucher au code, ce
/// que FR-056 interdit.
pub const PHOTOS_PREUVE_MIN: i64 = 1;

/// Toute la configuration coursier d'une zone, chargée en une fois.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ConfigCoursier {
    /// Zone résolue.
    pub zone: Uuid,
    /// Devise ISO 4217 de la zone (jamais écrite en dur).
    pub devise: String,
    /// Appels exigés par la preuve.
    pub preuve_appels_min: i64,
    /// Espacement minimal entre deux appels retenus.
    pub preuve_appels_espacement_s: i64,
    /// Présence continue exigée.
    pub preuve_presence_s: i64,
    /// Rayon dans lequel un relevé compte.
    pub preuve_presence_rayon_m: i64,
    /// Trou au-delà duquel la présence n'est plus continue.
    pub preuve_presence_trou_max_s: i64,
    /// Rétention de la photo de preuve.
    pub retention_photo_preuve_jours: i64,
    /// Période d'interrogation d'offre en arrière-plan.
    pub offre_interrogation_arriere_plan_s: i64,
    /// Essais du code de remise — **paramètre du cycle 008**, lu tel quel.
    pub essais_code_livraison: i64,
}

impl ConfigCoursier {
    /// Charge et **valide** la configuration d'une zone.
    pub async fn charger(
        zones: &dyn ConfigurationZones,
        zone: Uuid,
    ) -> Result<Self, ErreurCoursier> {
        let devise = zones.devise(zone).await?;
        let config = Self {
            zone,
            devise: devise.code,
            preuve_appels_min: entier(zones, zone, cles::PREUVE_APPELS_MIN).await?,
            preuve_appels_espacement_s: entier(zones, zone, cles::PREUVE_APPELS_ESPACEMENT_S)
                .await?,
            preuve_presence_s: entier(zones, zone, cles::PREUVE_PRESENCE_S).await?,
            preuve_presence_rayon_m: entier(zones, zone, cles::PREUVE_PRESENCE_RAYON_M).await?,
            preuve_presence_trou_max_s: entier(zones, zone, cles::PREUVE_PRESENCE_TROU_MAX_S)
                .await?,
            retention_photo_preuve_jours: entier(zones, zone, cles::RETENTION_PHOTO_PREUVE_JOURS)
                .await?,
            offre_interrogation_arriere_plan_s: entier(
                zones,
                zone,
                cles::OFFRE_INTERROGATION_ARRIERE_PLAN_S,
            )
            .await?,
            essais_code_livraison: entier(zones, zone, cles::ESSAIS_CODE_LIVRAISON).await?,
        };
        config.valider()?;
        Ok(config)
    }

    /// Les gardes, isolées pour être testables sans base.
    pub fn valider(&self) -> Result<(), ErreurCoursier> {
        // Deux appels espacés de `espacement_s` doivent tenir dans la fenêtre de
        // présence : sinon la preuve « appels » exige plus de temps que la
        // preuve « présence » n'en accorde, et les trois ne se réunissent
        // jamais — un échec cesse d'être déclarable, en silence.
        let etendue_appels = self.preuve_appels_espacement_s * (self.preuve_appels_min - 1).max(0);
        if etendue_appels > self.preuve_presence_s {
            return Err(ErreurCoursier::ConfigurationInvalide(format!(
                "{} appels espacés de {} s couvrent {} s, plus que {} = {} s : \
                 les trois preuves ne pourraient jamais se réunir",
                self.preuve_appels_min,
                self.preuve_appels_espacement_s,
                etendue_appels,
                cles::PREUVE_PRESENCE_S,
                self.preuve_presence_s,
            )));
        }
        // Un trou toléré aussi long que la présence exigée ferait passer deux
        // relevés distants de dix minutes pour dix minutes d'attente — ce que
        // la règle du trou existe précisément pour empêcher (R8).
        if self.preuve_presence_trou_max_s >= self.preuve_presence_s {
            return Err(ErreurCoursier::ConfigurationInvalide(format!(
                "{} ({} s) doit rester strictement inférieur à {} ({} s) : \
                 sinon un aller-retour vaut une présence",
                cles::PREUVE_PRESENCE_TROU_MAX_S,
                self.preuve_presence_trou_max_s,
                cles::PREUVE_PRESENCE_S,
                self.preuve_presence_s,
            )));
        }
        if self.preuve_presence_rayon_m <= 0 {
            return Err(ErreurCoursier::ConfigurationInvalide(format!(
                "{} vaut {} : aucun relevé ne compterait jamais",
                cles::PREUVE_PRESENCE_RAYON_M,
                self.preuve_presence_rayon_m,
            )));
        }
        Ok(())
    }

    /// Les seuils tels que le pré-provisionnement les sert à l'app.
    pub fn seuils_preuves(&self) -> SeuilsPreuves {
        SeuilsPreuves {
            appels_min: self.preuve_appels_min,
            espacement_s: self.preuve_appels_espacement_s,
            presence_s: self.preuve_presence_s,
            rayon_m: self.preuve_presence_rayon_m,
            photos_min: PHOTOS_PREUVE_MIN,
        }
    }
}

/// Paramètre de zone entier, résolu par héritage.
async fn entier(
    zones: &dyn ConfigurationZones,
    zone: Uuid,
    cle: &str,
) -> Result<i64, ErreurCoursier> {
    zones
        .parametre(zone, cle)
        .await?
        .and_then(|v| v.as_i64())
        .ok_or_else(|| ErreurCoursier::ParametreAbsent(cle.to_owned()))
}

#[cfg(test)]
mod tests {
    use super::*;

    fn config_saine() -> ConfigCoursier {
        ConfigCoursier {
            zone: Uuid::now_v7(),
            devise: "XOF".to_owned(),
            preuve_appels_min: 2,
            preuve_appels_espacement_s: 180,
            preuve_presence_s: 600,
            preuve_presence_rayon_m: 100,
            preuve_presence_trou_max_s: 120,
            retention_photo_preuve_jours: 365,
            offre_interrogation_arriere_plan_s: 5,
            essais_code_livraison: 3,
        }
    }

    /// Les valeurs seedées passent la validation — un test qui échouerait ici
    /// signalerait que le seed et le code ne parlent pas de la même chose.
    #[test]
    fn les_valeurs_seedees_sont_coherentes() {
        assert!(config_saine().valider().is_ok());
        assert_eq!(config_saine().seuils_preuves().photos_min, 1);
    }

    /// Une preuve « appels » qui exige plus de temps que la présence accordée
    /// rendrait l'échec indéclarable — en silence, et seulement chez les
    /// coursiers qui tombent sur un client absent.
    #[test]
    fn des_appels_plus_longs_que_la_presence_sont_refuses() {
        let mut config = config_saine();
        config.preuve_appels_min = 5; // 4 × 180 s = 720 s > 600 s
        let e = config.valider().unwrap_err();
        assert!(matches!(e, ErreurCoursier::ConfigurationInvalide(_)));
        assert!(e.to_string().contains("720"), "{e}");

        config.preuve_appels_min = 4; // 3 × 180 s = 540 s ≤ 600 s
        assert!(config.valider().is_ok());
    }

    /// Un seul appel exigé n'impose aucun espacement : l'étendue vaut 0, et la
    /// garde ne doit pas se déclencher sur une soustraction négative.
    #[test]
    fn un_seul_appel_n_impose_aucun_espacement() {
        let mut config = config_saine();
        config.preuve_appels_min = 1;
        config.preuve_appels_espacement_s = 100_000;
        assert!(config.valider().is_ok());
    }

    /// R8 — un trou aussi long que la présence exigée ferait passer un
    /// aller-retour pour une attente.
    #[test]
    fn un_trou_aussi_long_que_la_presence_est_refuse() {
        let mut config = config_saine();
        config.preuve_presence_trou_max_s = 600;
        let e = config.valider().unwrap_err();
        assert!(e.to_string().contains("trou_max_s"), "{e}");

        config.preuve_presence_trou_max_s = 599;
        assert!(config.valider().is_ok());
    }

    /// Un rayon nul n'éliminerait pas un relevé : il les éliminerait tous.
    #[test]
    fn un_rayon_nul_est_refuse() {
        let mut config = config_saine();
        config.preuve_presence_rayon_m = 0;
        assert!(config.valider().is_err());
    }

    /// L'inventaire : 7 clés créées, sans doublon, toutes préfixées
    /// `coursier.` — le seuil d'essais du cycle 008 n'y est PAS, parce que ce
    /// cycle le lit sans le posséder (FR-106).
    #[test]
    fn l_inventaire_compte_sept_cles_sans_doublon() {
        let uniques: std::collections::HashSet<_> = cles::TOUTES.iter().collect();
        assert_eq!(uniques.len(), 7);
        assert!(cles::TOUTES.iter().all(|c| c.starts_with("coursier.")));
        assert!(!cles::TOUTES.contains(&cles::ESSAIS_CODE_LIVRAISON));
    }
}
