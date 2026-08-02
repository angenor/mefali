//! Pipeline de création d'une commande (data-model §4) — idempotent par clé
//! client, prix verrouillés, devis figé, code et QR remis immédiatement.
//!
//! **Ordre imposé** : les étapes 1 à 6 sont HORS transaction (dont l'appel
//! réseau OSRM — research R11), les étapes 7 à 18 sont dans UNE seule
//! transaction. Tenir une transaction ouverte pendant un appel HTTP externe
//! serait la meilleure façon de bloquer la base un jour de panne OSRM.

use crate::modele::ErreurCommandes;

/// Clés des paramètres de zone lus par la décision de paiement. Aucune valeur
/// n'est en dur : tout se règle en configuration de zone (constitution I).
mod cles {
    /// Plafond d'encaissement en espèces (unités mineures).
    pub const PLAFOND_CASH: &str = "commande.plafond_cash_unites";
    /// Plafond RÉDUIT, restauration d'un client sans historique.
    pub const PLAFOND_CASH_RESTAURATION_SANS_HISTORIQUE: &str =
        "commande.plafond_cash_restauration_sans_historique_unites";
    /// En deçà de ce nombre de commandes TERMINÉES, le client est « sans historique ».
    pub const HISTORIQUE_MIN: &str = "commande.historique_min_commandes_terminees";
}

/// Pourquoi le cash est refusé. Chaque motif a sa clé i18n : le client voit la
/// RAISON du grisage, jamais un bouton mort (maquette C3-3b).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MotifPrepaiement {
    /// Total au-dessus du plafond d'encaissement de la zone (FR-024).
    Plafond,
    /// Le compte porte `prepaiement_impose` (sanction CPT-06, FR-025).
    PrepaiementImpose,
    /// Restauration commandée par un client sans historique (FR-024).
    RestaurationSansHistorique,
}

impl MotifPrepaiement {
    /// Représentation textuelle (payload `commande.paiement_requis`).
    pub fn comme_str(self) -> &'static str {
        match self {
            MotifPrepaiement::Plafond => "plafond",
            MotifPrepaiement::PrepaiementImpose => "prepaiement_impose",
            MotifPrepaiement::RestaurationSansHistorique => "restauration_sans_historique",
        }
    }

    /// Clé i18n fr affichée sous l'option cash grisée.
    pub fn message_cle(self) -> &'static str {
        match self {
            MotifPrepaiement::Plafond => "commande.cash.plafond_depasse",
            MotifPrepaiement::PrepaiementImpose => "commande.cash.prepaiement_impose",
            MotifPrepaiement::RestaurationSansHistorique => {
                "commande.cash.restauration_sans_historique"
            }
        }
    }
}

/// Décision d'encaissement, identique au panier et à la confirmation — le
/// client ne découvre jamais à la confirmation une règle qu'on ne lui a pas
/// montrée au panier.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct DecisionPaiement {
    /// Le paiement en espèces est possible.
    pub cash_autorise: bool,
    /// Pourquoi il ne l'est pas (`None` s'il l'est).
    pub motif: Option<MotifPrepaiement>,
    /// Plafond APPLIQUÉ (celui qui a tranché), unités mineures.
    pub plafond_unites: i64,
}

impl DecisionPaiement {
    /// Clé i18n du motif, ou `None` si le cash est autorisé.
    pub fn message_cle(&self) -> Option<&'static str> {
        self.motif.map(MotifPrepaiement::message_cle)
    }
}

use uuid::Uuid;
use zones::ConfigurationZones;

use crate::depot::PgCommandes;

impl PgCommandes {
    /// Décide si le total peut être encaissé en espèces (FR-024/025).
    ///
    /// Trois refus possibles, dans cet ordre de priorité :
    /// 1. le compte porte `prepaiement_impose` — une sanction ne se contourne
    ///    pas en baissant son panier ;
    /// 2. la catégorie est la restauration ET le client est « sans historique »
    ///    (moins de `commande.historique_min_commandes_terminees` commandes
    ///    **terminées** — les annulées et les échouées ne comptent pas) : le
    ///    plafond RÉDUIT s'applique ;
    /// 3. le plafond ordinaire de la zone.
    ///
    /// Le plafond renvoyé est celui qui a effectivement tranché : c'est lui que
    /// l'écran affiche, pas une valeur théorique.
    pub async fn decision_paiement(
        &self,
        zone_id: Uuid,
        client_id: Uuid,
        categorie_slug: &str,
        total_unites: i64,
    ) -> Result<DecisionPaiement, ErreurCommandes> {
        let plafond_ordinaire = self.parametre_i64(zone_id, cles::PLAFOND_CASH).await?;

        // 1. Sanction de compte : rien ne la contourne.
        if self
            .restrictions
            .restrictions(client_id)
            .await?
            .prepaiement_impose
        {
            return Ok(DecisionPaiement {
                cash_autorise: false,
                motif: Some(MotifPrepaiement::PrepaiementImpose),
                plafond_unites: 0,
            });
        }

        // 2. Plafond réduit de la restauration sans historique.
        let plafond = if categorie_slug == "restauration"
            && self.client_sans_historique(zone_id, client_id).await?
        {
            let reduit = self
                .parametre_i64(zone_id, cles::PLAFOND_CASH_RESTAURATION_SANS_HISTORIQUE)
                .await?;
            if total_unites > reduit {
                return Ok(DecisionPaiement {
                    cash_autorise: false,
                    motif: Some(MotifPrepaiement::RestaurationSansHistorique),
                    plafond_unites: reduit,
                });
            }
            reduit
        } else {
            plafond_ordinaire
        };

        // 3. Plafond ordinaire.
        if total_unites > plafond_ordinaire {
            return Ok(DecisionPaiement {
                cash_autorise: false,
                motif: Some(MotifPrepaiement::Plafond),
                plafond_unites: plafond_ordinaire,
            });
        }

        Ok(DecisionPaiement {
            cash_autorise: true,
            motif: None,
            plafond_unites: plafond,
        })
    }

    /// Vrai si le client compte MOINS de commandes terminées que le seuil de
    /// zone (FR-024). Les commandes annulées ou échouées ne comptent pas : on
    /// mesure une relation qui a abouti, pas un nombre de tentatives.
    pub(crate) async fn client_sans_historique(
        &self,
        zone_id: Uuid,
        client_id: Uuid,
    ) -> Result<bool, ErreurCommandes> {
        let seuil = self.parametre_i64(zone_id, cles::HISTORIQUE_MIN).await?;
        let terminees = sqlx::query_scalar!(
            r#"SELECT count(*) AS "n!" FROM commandes.commande
               WHERE client_id = $1 AND etat = 'terminee'"#,
            client_id,
        )
        .fetch_one(&self.pool)
        .await?;
        Ok(terminees < seuil)
    }

    /// Paramètre de zone entier, résolu par héritage. Une clé absente est une
    /// erreur de CONFIGURATION, pas un défaut silencieux : un plafond cash qui
    /// vaudrait 0 par accident bloquerait toutes les commandes en espèces.
    pub(crate) async fn parametre_i64(
        &self,
        zone_id: Uuid,
        cle: &str,
    ) -> Result<i64, ErreurCommandes> {
        self.zones
            .parametre(zone_id, cle)
            .await?
            .and_then(|v| v.as_i64())
            .ok_or_else(|| {
                ErreurCommandes::Dependance(format!(
                    "paramètre de zone « {cle} » absent ou non entier"
                ))
            })
    }

    /// Paramètre de zone booléen, résolu par héritage. `false` si absent —
    /// pour `perissable`, l'absence signifie « non périssable », qui est le
    /// défaut sûr : on renvoie la marchandise au vendeur plutôt que de la jeter.
    pub(crate) async fn parametre_bool(
        &self,
        zone_id: Uuid,
        cle: &str,
    ) -> Result<bool, ErreurCommandes> {
        Ok(self
            .zones
            .parametre(zone_id, cle)
            .await?
            .and_then(|v| v.as_bool())
            .unwrap_or(false))
    }

    /// **US2 (CMD-02)** — valide l'adresse de livraison et rend le lieu de
    /// prestation à DÉNORMALISER sur le tronc.
    ///
    /// Deux exigences, et une seule suffit à faire trouver le client :
    /// - un repère ÉCRIT d'au moins `commande.repere_texte_min_caracteres`
    ///   caractères (« près du marché » ne trouve personne) ;
    /// - **OU** une note vocale présente (sa durée est déjà bornée par le
    ///   paramètre de zone du cycle 003).
    ///
    /// Un repère vocal PURGÉ (rétention écoulée) sans repère écrit fait donc
    /// échouer la validation : le repère est REDEMANDÉ avant confirmation
    /// plutôt que découvert manquant par le coursier devant la porte.
    ///
    /// Le téléphone est vérifié **par construction** (FR-019) : aucun compte
    /// n'existe sans OTP validé au cycle 003 — un compte introuvable est donc
    /// le seul cas de refus, et il est traité comme tel.
    pub async fn valider_adresse(
        &self,
        zone_id: Uuid,
        client_id: Uuid,
        adresse_id: Option<Uuid>,
        lieu: Option<(f64, f64)>,
        repere_texte: Option<&str>,
        repere_vocal_cle: Option<&str>,
    ) -> Result<LieuValide, ErreurCommandes> {
        // FR-019 — le compte doit exister ; son numéro est vérifié par
        // construction (cycle 003 : pas de compte sans OTP validé).
        let existe = sqlx::query_scalar!(
            "SELECT EXISTS(SELECT 1 FROM comptes.compte WHERE id = $1)",
            client_id,
        )
        .fetch_one(&self.pool)
        .await?;
        if existe != Some(true) {
            return Err(ErreurCommandes::TelephoneNonVerifie);
        }

        let min = self
            .parametre_i64(zone_id, "commande.repere_texte_min_caracteres")
            .await?;

        // Adresse du carnet : ses repères font foi, et ils sont COPIÉS sur le
        // tronc (immuabilité — le carnet peut ensuite être modifié ou purgé).
        let (lat, lon, texte, vocal) = match adresse_id {
            Some(id) => {
                let a = self.comptes_adresse(id, client_id).await?;
                (
                    a.lat,
                    a.lng,
                    a.repere_texte.clone(),
                    a.repere_vocal_cle_objet.clone(),
                )
            }
            None => {
                let (lat, lon) = lieu.ok_or_else(|| {
                    ErreurCommandes::PanierInvalide("lieu de prestation absent".to_owned())
                })?;
                (
                    lat,
                    lon,
                    repere_texte.map(str::to_owned),
                    repere_vocal_cle.map(str::to_owned),
                )
            }
        };

        let texte_suffisant = texte
            .as_deref()
            .map(|t| t.trim().chars().count() as i64 >= min)
            .unwrap_or(false);
        if !texte_suffisant && vocal.is_none() {
            return Err(ErreurCommandes::RepereManquant);
        }

        Ok(LieuValide {
            adresse_id,
            lat,
            lon,
            // Seul le repère RETENU est dénormalisé : un texte trop court n'a
            // pas passé la garde, il n'a rien à faire sur la commande.
            repere_texte: texte.filter(|_| texte_suffisant),
            repere_vocal_cle: vocal,
        })
    }

    /// Adresse du carnet, contrôlée en propriété par le domaine `comptes`.
    async fn comptes_adresse(
        &self,
        adresse_id: Uuid,
        client_id: Uuid,
    ) -> Result<comptes::Adresse, ErreurCommandes> {
        let ligne = sqlx::query!(
            "SELECT lat, lng, repere_texte, repere_vocal_cle_objet
             FROM comptes.adresse
             WHERE id = $1 AND compte_id = $2 AND supprimee_le IS NULL",
            adresse_id,
            client_id,
        )
        .fetch_optional(&self.pool)
        .await?
        .ok_or(ErreurCommandes::NonProprietaire)?;
        Ok(comptes::Adresse {
            id: adresse_id,
            compte_id: client_id,
            libelle: String::new(),
            lat: ligne.lat,
            lng: ligne.lng,
            repere_texte: ligne.repere_texte,
            repere_vocal_cle_objet: ligne.repere_vocal_cle_objet,
            repere_vocal_duree_s: None,
            zone_id: Uuid::nil(),
            livraison_origine: None,
            cree_le: chrono::Utc::now(),
            derniere_utilisation_le: chrono::Utc::now(),
            supprimee_le: None,
        })
    }
}

/// Lieu de prestation validé, prêt à être DÉNORMALISÉ sur le tronc (R3).
///
/// La dénormalisation n'est pas une optimisation : c'est ce qui rend une
/// commande passée insensible à la modification, à la purge ou à la
/// suppression de l'adresse du carnet.
#[derive(Debug, Clone, PartialEq)]
pub struct LieuValide {
    /// Adresse du carnet d'où le lieu vient (`None` si pin fourni en clair).
    pub adresse_id: Option<Uuid>,
    /// Latitude du lieu de prestation.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
    /// Repère écrit RETENU (assez long), copié sur le tronc.
    pub repere_texte: Option<String>,
    /// Clé S3 du repère vocal, copiée sur le tronc.
    pub repere_vocal_cle: Option<String>,
}

// ── Pipeline de création (data-model §4) ───────────────────────────────────

use crate::etats::{Acteur, Niveau};
use crate::modele::{EtatCommande, ModePaiement};
use crate::panier::{LignePanier, PanierValide};

/// Ce que le client soumet à `POST /commandes`.
#[derive(Debug, Clone)]
pub struct DemandeCreation {
    /// `Idempotency-Key` — DEVIENT l'identifiant de la commande (R7).
    pub id: Uuid,
    /// Client propriétaire.
    pub client_id: Uuid,
    /// Zone.
    pub zone_id: Uuid,
    /// Catégorie de service.
    pub categorie_slug: String,
    /// Véhicule demandé.
    pub transport_slug: String,
    /// Adresse du carnet, ou pin fourni en clair.
    pub adresse_id: Option<Uuid>,
    /// Pin fourni en clair (si pas d'adresse du carnet).
    pub lieu: Option<(f64, f64)>,
    /// Repère écrit soumis.
    pub repere_texte: Option<String>,
    /// Clé S3 du repère vocal soumis.
    pub repere_vocal_cle: Option<String>,
    /// Lignes du panier.
    pub lignes: Vec<LignePanier>,
    /// Mode de paiement demandé.
    pub mode_paiement: ModePaiement,
}

/// Secrets de confirmation d'exécution remis au CLIENT à la création (R6).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct SecretsRemise {
    /// Code à 4 chiffres, lisible par le client seul.
    pub code_livraison: String,
    /// Jeton encodé dans le QR de réception.
    pub jeton_reception: String,
}

/// La livraison d'une commande — **composant optionnel du tronc** (0..n).
///
/// Les trois valeurs sont groupées parce qu'elles vivent ou meurent ENSEMBLE :
/// une commande sans livraison n'a ni identifiant de livraison, ni arrêts, ni
/// devis figé. Trois champs plats laissaient le type dire des choses fausses —
/// un identifiant nul avec deux arrêts, un devis à zéro sans livraison — et
/// c'est exactement ce que le rejeu produisait (`unwrap_or_default`).
#[derive(Debug, Clone)]
pub struct LivraisonCreee {
    /// Identifiant de la livraison.
    pub id: Uuid,
    /// Nombre d'arrêts (collectes + remise).
    pub nb_arrets: i64,
    /// Devis figé copié sur la livraison.
    pub devis: tarification::Devis,
}

/// Commande créée, telle que l'API la rend au client propriétaire.
#[derive(Debug, Clone)]
pub struct CommandeCreee {
    /// Identifiant (= clé d'idempotence).
    pub id: Uuid,
    /// État initial (`nouvelle` ou `en_attente_paiement`).
    pub etat: EtatCommande,
    /// Montant des articles (unités mineures).
    pub montant_articles_unites: i64,
    /// Total à payer.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Mode de paiement retenu.
    pub mode_paiement: ModePaiement,
    /// Secrets de remise — servis au CLIENT PROPRIÉTAIRE seul.
    pub secrets: SecretsRemise,
    /// Livraison créée, s'il y en a une.
    ///
    /// `None` est atteignable : `creer_relivraison` (`echec.rs`) crée une
    /// commande SANS livraison, et le schéma n'en exige aucune (test T037).
    /// Tous les verticaux du MVP en créent exactement une — le `None` décrit
    /// le tronc, il ne décrit pas le vertical.
    pub livraison: Option<LivraisonCreee>,
    /// Vrai si la commande existait déjà (rejeu idempotent — `200`, pas `201`).
    pub rejeu: bool,
}

impl PgCommandes {
    /// Crée une commande — **pipeline complet** de data-model §4.
    ///
    /// Étapes 1 à 6 HORS transaction (dont l'appel réseau OSRM, R11), 7 à 18
    /// dans UNE transaction. Idempotent par `demande.id` : un rejeu de la même
    /// clé rend la commande existante sans rien réécrire ni ré-émettre.
    pub async fn creer_commande(
        &self,
        demande: DemandeCreation,
    ) -> Result<CommandeCreee, ErreurCommandes> {
        // Rejeu ? La contrainte de clé primaire rend l'idempotence STRUCTURELLE
        // (vraie même sous concurrence) ; cette lecture ne fait qu'éviter le
        // travail inutile du chemin nominal.
        // Cette lecture refuse aussi l'USURPATION : un identifiant qui existe
        // chez un autre client rend `CommandeInconnue`, donc un 404, avant
        // toute validation et tout appel de routage.
        if let Some(existante) = self
            .relire_commande_creee(demande.id, demande.client_id)
            .await?
        {
            return Ok(existante);
        }

        // ── 1. Compte bloqué : refus AVANT tout (FR-026) ───────────────────
        if self
            .restrictions
            .restrictions(demande.client_id)
            .await?
            .bloque
        {
            return Err(ErreurCommandes::CompteBloque);
        }

        // ── 2/3. Configuration de zone + panier résolu et regroupé ─────────
        let panier = self
            .resoudre_panier(demande.zone_id, &demande.categorie_slug, &demande.lignes)
            .await?;

        // Garde du VERTICAL (mono-vendeur pour la restauration) — toute
        // spécificité métier passe par là (constitution II).
        let delai_preparation = self.delai_preparation_de(&panier).await?;
        let workflow = crate::workflow::pour_categorie(&demande.categorie_slug, delai_preparation);
        workflow.valider_creation(&panier)?;

        // ── 4. Adresse : repère obligatoire, téléphone vérifié ─────────────
        let lieu = self
            .valider_adresse(
                demande.zone_id,
                demande.client_id,
                demande.adresse_id,
                demande.lieu,
                demande.repere_texte.as_deref(),
                demande.repere_vocal_cle.as_deref(),
            )
            .await?;

        // ── 5. Commandabilité de CHAQUE vendeur, AVANT tout verrouillage ───
        // `resoudre_panier` a déjà refusé un vendeur non commandable ; ce
        // second passage ferme la fenêtre entre le devis et la confirmation.
        for groupe in &panier.groupes {
            let c = self
                .prestataires
                .commandabilite(groupe.prestataire_id)
                .await?;
            if !c.commandable() {
                return Err(ErreurCommandes::VendeurIndisponible(groupe.prestataire_id));
            }
        }

        // ── 6. Devis, HORS transaction (appel réseau OSRM — R11) ───────────
        let devis = self
            .evaluer_panier(
                &panier,
                (lieu.lat, lieu.lon),
                &demande.transport_slug,
                chrono::Utc::now(),
            )
            .await?;

        let montant_articles = panier.montant_articles_unites();
        let total = montant_articles + devis.prix_client;

        // ── 16 (décidé avant d'ouvrir la transaction) : cash ou prépaiement ─
        let paiement = self
            .decision_paiement(
                demande.zone_id,
                demande.client_id,
                &demande.categorie_slug,
                total,
            )
            .await?;
        if demande.mode_paiement == ModePaiement::Cash && !paiement.cash_autorise {
            return Err(ErreurCommandes::CashIndisponible);
        }
        let etat_initial = if demande.mode_paiement == ModePaiement::Cash {
            EtatCommande::Nouvelle
        } else {
            EtatCommande::EnAttentePaiement
        };
        // La garde de la machine à états vaut aussi pour la CRÉATION : un état
        // initial hors table serait refusé ici, pas découvert en base.
        crate::etats::verifier_transition(
            Niveau::Commande,
            None,
            etat_initial.comme_str(),
            Acteur::Client,
        )?;

        // ── 15. Secrets de remise — aléatoire CRYPTOGRAPHIQUE (R6) ─────────
        let secrets = SecretsRemise {
            code_livraison: code_a_4_chiffres(),
            jeton_reception: jeton_aleatoire(),
        };

        // ══ 7. BEGIN ══════════════════════════════════════════════════════
        let mut tx = self.pool.begin().await?;

        // 8. Tronc — `id` = clé d'idempotence.
        let insere = sqlx::query!(
            "INSERT INTO commandes.commande
                 (id, client_id, zone_id, categorie_id, lieu_lat, lieu_lon,
                  repere_texte, repere_vocal_cle, adresse_id,
                  montant_articles_unites, total_unites, devise,
                  mode_paiement, etat_paiement, etat,
                  code_livraison, code_livraison_hash,
                  jeton_reception, jeton_reception_hash)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12,
                     $13::text::commandes.mode_paiement,
                     $14::text::commandes.etat_paiement,
                     $15::text::commandes.etat_commande,
                     $16, $17, $18, $19)
             ON CONFLICT (id) DO NOTHING",
            demande.id,
            demande.client_id,
            demande.zone_id,
            panier.categorie_id,
            lieu.lat,
            lieu.lon,
            lieu.repere_texte,
            lieu.repere_vocal_cle,
            lieu.adresse_id,
            montant_articles,
            total,
            panier.devise,
            demande.mode_paiement.comme_str(),
            if demande.mode_paiement == ModePaiement::Cash {
                "du"
            } else {
                "en_attente"
            },
            etat_initial.comme_str(),
            secrets.code_livraison,
            socle::empreinte_code(demande.id, &secrets.code_livraison),
            secrets.jeton_reception,
            socle::empreinte_jeton(&secrets.jeton_reception),
        )
        .execute(&mut *tx)
        .await?;
        if insere.rows_affected() == 0 {
            // Course perdue contre un rejeu concurrent : la contrainte a tenu.
            tx.rollback().await?;
            return self
                .relire_commande_creee(demande.id, demande.client_id)
                .await?
                .ok_or(ErreurCommandes::CommandeInconnue(demande.id));
        }

        // 9/10. Prix FIGÉS puis lignes — le verrou est pris dans CETTE
        // transaction : le prix affiché au panier ne peut plus bouger (III).
        let mut lignes_par_vendeur: Vec<(Uuid, Vec<Uuid>)> = Vec::new();
        for groupe in &panier.groupes {
            let mut ids = Vec::new();
            for ligne in &groupe.lignes {
                let fige = self
                    .prestataires
                    .figer_prix(&mut tx, groupe.prestataire_id, ligne.ligne.article_id)
                    .await?;
                let ligne_id = Uuid::now_v7();
                sqlx::query!(
                    "INSERT INTO commandes.ligne_commande
                         (id, commande_id, prestataire_id, article_id, prix_fige_id,
                          quantite, preference)
                     VALUES ($1, $2, $3, $4, $5, $6,
                             $7::text::commandes.preference_substitution)",
                    ligne_id,
                    demande.id,
                    groupe.prestataire_id,
                    ligne.ligne.article_id,
                    fige.id,
                    ligne.ligne.quantite,
                    ligne.ligne.preference.comme_str(),
                )
                .execute(&mut *tx)
                .await?;
                ids.push(ligne_id);
            }
            lignes_par_vendeur.push((groupe.prestataire_id, ids));
        }

        // 11. Détails du vertical (`resto_details`), s'il en a.
        if let Some(details) = workflow.details(&panier) {
            sqlx::query!(
                "INSERT INTO commandes.resto_details (commande_id, delai_preparation_min)
                 VALUES ($1, $2)",
                demande.id,
                details.delai_preparation_min,
            )
            .execute(&mut *tx)
            .await?;
        }

        // 12. Livraison + COPIE du devis figé (jamais recalculé — R11).
        let livraison_id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO commandes.livraison
                 (id, commande_id, etat, devis_prix_client, devis_part_coursier,
                  devis_marge, devis_devise, devis_distance_m, devis_eta_s,
                  devis_degraded, devis_composantes, proposer_scission)
             VALUES ($1, $2, 'assignee', $3, $4, $5, $6, $7, $8, $9, $10, $11)",
            livraison_id,
            demande.id,
            devis.prix_client,
            devis.part_coursier,
            devis.marge,
            devis.devise,
            devis.distance_m,
            devis.eta_s,
            devis.degraded,
            composantes_json(&devis.composantes),
            devis.proposer_scission,
        )
        .execute(&mut *tx)
        .await?;

        // CAPACITÉ REQUISE — sur la LIVRAISON, jamais sur le tronc (constitution
        // II : le tronc ne porte aucun champ logistique ; quel véhicule il faut
        // EST logistique). Table `(famille, valeur)` et non colonne : l'ajout
        // d'une famille (qualification d'artisan, phase N) ne doit coûter ni
        // migration ni réécriture du filtre de dispatch (specs/009 R9, FR-018).
        //
        // Effet INTERNE : le corps de `POST /commandes` ne change pas.
        sqlx::query!(
            "INSERT INTO commandes.capacite_requise (livraison_id, famille, valeur)
             VALUES ($1, 'transport', $2)
             ON CONFLICT DO NOTHING",
            livraison_id,
            demande.transport_slug,
        )
        .execute(&mut *tx)
        .await?;

        // 13/14. Segment, puis arrêts : collectes dans l'ORDRE OPTIMISÉ, puis
        // la REMISE en dernier ; chaque ligne est rattachée à son arrêt.
        let segment_id = Uuid::now_v7();
        sqlx::query!(
            "INSERT INTO commandes.segment (id, livraison_id, ordre) VALUES ($1, $2, 0)",
            segment_id,
            livraison_id,
        )
        .execute(&mut *tx)
        .await?;

        // `devis.ordre` indexe les groupes du panier. Un ordre vide (double de
        // test minimal) retombe sur l'ordre de composition.
        let ordre: Vec<usize> = if devis.ordre.len() == panier.groupes.len() {
            devis.ordre.clone()
        } else {
            (0..panier.groupes.len()).collect()
        };
        let mut montant_a_avancer = 0_i64;
        for (rang, &index) in ordre.iter().enumerate() {
            let groupe = &panier.groupes[index];
            let arret_id = Uuid::now_v7();
            let avance = groupe.sous_total_unites();
            montant_a_avancer += avance;
            // `montant_articles_unites = avance` et retenue nulle À LA
            // CRÉATION (cycle PAY 011, migration 0021) : aucune retenue n'est
            // connue à cet instant — elle est LUE au scan depuis le devis figé,
            // et seulement si la livraison n'a qu'un arrêt de collecte (R9).
            //
            // Ces deux colonnes ne sont pas décoratives : la contrainte
            // `arret_avance_coherente` tient l'invariant « net = articles −
            // retenue, écrêté à zéro » dans la BASE. Les laisser à leur défaut
            // ferait échouer l'insertion — et c'est exactement ce qu'on veut
            // d'un invariant d'argent : qu'il refuse une ligne incohérente
            // plutôt que de la laisser passer pour être découverte au reçu.
            sqlx::query!(
                "INSERT INTO commandes.arret
                     (id, segment_id, prestataire_id, ordre, type_arret,
                      site_lat, site_lon, montant_avance, devise,
                      montant_articles_unites, retenue_appliquee_unites)
                 VALUES ($1, $2, $3, $4, 'collecte', $5, $6, $7, $8, $7, 0)",
                arret_id,
                segment_id,
                groupe.prestataire_id,
                rang as i16,
                groupe.site_lat,
                groupe.site_lon,
                avance,
                panier.devise,
            )
            .execute(&mut *tx)
            .await?;

            let (_, lignes_ids) = &lignes_par_vendeur[index];
            sqlx::query!(
                "UPDATE commandes.ligne_commande SET arret_id = $1 WHERE id = ANY($2)",
                arret_id,
                lignes_ids,
            )
            .execute(&mut *tx)
            .await?;
        }

        // L'arrêt de REMISE : ni prestataire, ni montant avancé. Sa position
        // ATTENDUE est le lieu de prestation (sémantique élargie de site_lat).
        sqlx::query!(
            "INSERT INTO commandes.arret
                 (id, segment_id, ordre, type_arret, site_lat, site_lon,
                  montant_avance, devise)
             VALUES ($1, $2, $3, 'remise', $4, $5, 0, $6)",
            Uuid::now_v7(),
            segment_id,
            ordre.len() as i16,
            lieu.lat,
            lieu.lon,
            panier.devise,
        )
        .execute(&mut *tx)
        .await?;

        // 17. La rétention du carnet repart de cette utilisation (FR-022).
        if let Some(adresse_id) = lieu.adresse_id {
            self.comptes_marquer_adresse(&mut tx, adresse_id).await?;
        }

        // 18. Événements — dans la MÊME transaction (constitution VI).
        let maintenant = chrono::Utc::now();
        let nb_arrets = ordre.len() as i64 + 1;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "commande.creee",
                entite_type: "commande",
                entite_id: demande.id,
                payload: serde_json::json!({
                    "zone": demande.zone_id,
                    "categorie": demande.categorie_slug,
                    "nb_vendeurs": panier.nb_vendeurs(),
                    "nb_articles": panier.nb_articles(),
                    "montant_articles": montant_articles,
                    "total": total,
                    "devise": panier.devise,
                    "mode_paiement": demande.mode_paiement.comme_str(),
                    "mono_vendeur": panier.mono_vendeur(),
                    "acteur": demande.client_id,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;
        socle::ecrire_evenement(
            &mut tx,
            socle::NouvelEvenement {
                type_evenement: "livraison.creee",
                entite_type: "livraison",
                entite_id: livraison_id,
                payload: serde_json::json!({
                    "commande": demande.id,
                    "nb_arrets": nb_arrets,
                    "devis_prix_client": devis.prix_client,
                    "devis_part_coursier": devis.part_coursier,
                    "devise": devis.devise,
                    "degraded": devis.degraded,
                }),
                survenu_le: maintenant,
            },
        )
        .await?;

        if etat_initial == EtatCommande::Nouvelle {
            // Contrat SANS consommateur ce cycle : DSP s'y branchera.
            socle::ecrire_evenement(
                &mut tx,
                socle::NouvelEvenement {
                    type_evenement: "commande.prete_a_dispatcher",
                    entite_type: "commande",
                    entite_id: demande.id,
                    payload: serde_json::json!({
                        "zone": demande.zone_id,
                        "nb_arrets": nb_arrets,
                        "montant_a_avancer": montant_a_avancer,
                        "devise": panier.devise,
                        "transport_requis": demande.transport_slug,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        } else {
            socle::ecrire_evenement(
                &mut tx,
                socle::NouvelEvenement {
                    type_evenement: "commande.paiement_requis",
                    entite_type: "commande",
                    entite_id: demande.id,
                    payload: serde_json::json!({
                        "motif": paiement
                            .motif
                            .map(MotifPrepaiement::comme_str)
                            .unwrap_or("mode_demande"),
                        "total": total,
                        "devise": panier.devise,
                        "plafond": paiement.plafond_unites,
                    }),
                    survenu_le: maintenant,
                },
            )
            .await?;
        }

        // ══ 19. COMMIT ════════════════════════════════════════════════════
        tx.commit().await?;

        Ok(CommandeCreee {
            id: demande.id,
            etat: etat_initial,
            montant_articles_unites: montant_articles,
            total_unites: total,
            devise: panier.devise,
            mode_paiement: demande.mode_paiement,
            secrets,
            livraison: Some(LivraisonCreee {
                id: livraison_id,
                nb_arrets,
                devis,
            }),
            rejeu: false,
        })
    }

    /// Délai de préparation du vendeur, pour le vertical restauration.
    /// `None` en multi-vendeurs : aucun délai unique n'aurait de sens.
    async fn delai_preparation_de(
        &self,
        panier: &PanierValide,
    ) -> Result<Option<i16>, ErreurCommandes> {
        let Some(groupe) = panier.groupes.first().filter(|_| panier.mono_vendeur()) else {
            return Ok(None);
        };
        Ok(sqlx::query_scalar!(
            "SELECT delai_preparation_min FROM prestataires.prestataire WHERE id = $1",
            groupe.prestataire_id,
        )
        .fetch_optional(&self.pool)
        .await?
        // La colonne est un `integer` côté prestataires ; `resto_details` la
        // range en `smallint` — la conversion est bornée par le domaine
        // (un délai de préparation ne dépasse pas quelques heures).
        .map(|d| d as i16))
    }

    /// Avance la date de dernière utilisation de l'adresse (crate `comptes`).
    async fn comptes_marquer_adresse(
        &self,
        tx: &mut sqlx::PgTransaction<'_>,
        adresse_id: Uuid,
    ) -> Result<(), ErreurCommandes> {
        sqlx::query!(
            "UPDATE comptes.adresse SET derniere_utilisation_le = now()
             WHERE id = $1 AND supprimee_le IS NULL",
            adresse_id,
        )
        .execute(&mut **tx)
        .await?;
        Ok(())
    }

    /// Relit une commande déjà créée, pour le REJEU idempotent (R7) — **et
    /// seulement si elle appartient au demandeur**.
    ///
    /// **Le rejeu sert des SECRETS.** Le corps porte `code_livraison` et
    /// `jeton_reception`, que R6 réserve au client propriétaire : ce sont eux
    /// qui font remettre la marchandise. Sans ce contrôle, un compte `Client`
    /// qui connaît l'identifiant d'une commande d'autrui — l'`Idempotency-Key`
    /// EST cet identifiant — se les faisait servir en `200`.
    ///
    /// **`404`, jamais `403`.** Répondre « ce n'est pas la vôtre » confirmerait
    /// l'existence de la commande visée, ce qui est déjà une fuite : une
    /// commande qu'on ne possède pas est une commande qui n'existe pas. Même
    /// règle que `GET /commandes/{id}`.
    ///
    /// **Deux lectures, pas une jointure.** Un `LEFT JOIN` rend toutes les
    /// colonnes de la livraison nullables pour sqlx, alors qu'elles sont
    /// `NOT NULL` en base (migration 0009) : leur seule nullité venait de la
    /// jointure. Il fallait donc dix valeurs par défaut pour recomposer un
    /// devis — dont un `Uuid::nil()` qui a l'air d'un identifiant et ne désigne
    /// rien. Lire la livraison à part rend l'absence là où elle est vraie, dans
    /// le `fetch_optional`, et le type porte alors exactement ce que la base
    /// contient. Le coût est un aller-retour SQL sur le seul chemin de rejeu.
    async fn relire_commande_creee(
        &self,
        id: Uuid,
        client_id: Uuid,
    ) -> Result<Option<CommandeCreee>, ErreurCommandes> {
        // `client_id` est LU, pas filtré dans le `WHERE` : la même lecture sert
        // de sonde d'existence, et l'usurpation est refusée AVANT les
        // validations et l'appel de routage — au lieu de les payer pour rien.
        let Some(c) = sqlx::query!(
            r#"SELECT c.client_id, c.etat::text AS "etat!", c.montant_articles_unites,
                      c.total_unites, c.devise, c.mode_paiement::text AS "mode_paiement!",
                      c.code_livraison, c.jeton_reception
               FROM commandes.commande c
               WHERE c.id = $1"#,
            id,
        )
        .fetch_optional(&self.pool)
        .await?
        else {
            return Ok(None);
        };

        if c.client_id != client_id {
            return Err(ErreurCommandes::CommandeInconnue(id));
        }

        // `ORDER BY` explicite : la table ne porte aucune unicité sur
        // `commande_id`, et le tronc admet 0..n livraisons. Avec 0 ou 1 ligne —
        // tout ce que le MVP produit — le résultat est identique à celui de la
        // jointure d'avant ; le jour où il y en aura deux, le rejeu rendra la
        // PREMIÈRE, pas une au hasard.
        let livraison = sqlx::query!(
            r#"SELECT l.id, l.devis_prix_client, l.devis_part_coursier, l.devis_marge,
                      l.devis_devise, l.devis_distance_m, l.devis_eta_s, l.devis_degraded,
                      l.devis_composantes, l.proposer_scission,
                      (SELECT count(*) FROM commandes.arret a
                         JOIN commandes.segment s ON s.id = a.segment_id
                         WHERE s.livraison_id = l.id) AS "nb_arrets!"
               FROM commandes.livraison l
               WHERE l.commande_id = $1
               ORDER BY l.cree_le, l.id
               LIMIT 1"#,
            id,
        )
        .fetch_optional(&self.pool)
        .await?
        .map(|l| LivraisonCreee {
            id: l.id,
            nb_arrets: l.nb_arrets,
            devis: tarification::Devis {
                prix_client: l.devis_prix_client,
                part_coursier: l.devis_part_coursier,
                marge: l.devis_marge,
                devise: l.devis_devise,
                distance_m: l.devis_distance_m,
                eta_s: l.devis_eta_s,
                degraded: l.devis_degraded,
                proposer_scission: l.proposer_scission,
                // L'ordre optimisé n'est PAS rejoué, et le contrat le dit
                // (description du `200` sur `POST /commandes`) : il est figé
                // sur les ARRÊTS, pas sur la livraison, et le relire coûterait
                // une jointure de plus sur le chemin qui doit rester le plus
                // léger — pour une valeur déjà servie au `201`.
                ordre: Vec::new(),
                composantes: composantes_depuis_json(l.devis_composantes),
            },
        });

        Ok(Some(CommandeCreee {
            id,
            etat: c.etat.parse()?,
            montant_articles_unites: c.montant_articles_unites,
            total_unites: c.total_unites,
            devise: c.devise,
            mode_paiement: c.mode_paiement.parse()?,
            secrets: SecretsRemise {
                code_livraison: c.code_livraison,
                jeton_reception: c.jeton_reception,
            },
            livraison,
            rejeu: true,
        }))
    }
}

/// Code à 4 chiffres, aléatoire CRYPTOGRAPHIQUE (R6).
///
/// Pas de générateur pseudo-aléatoire de confort : ce code protège une remise
/// de marchandise. L'entropie vient d'un UUIDv4, dont la source est celle du
/// système — aucune dépendance nouvelle (constitution X).
pub(crate) fn code_a_4_chiffres() -> String {
    let octets = *Uuid::now_v7().as_bytes();
    // Les 4 DERNIERS octets d'un UUIDv7 sont aléatoires ; les premiers portent
    // l'horodatage et seraient devinables.
    let brut = u32::from_be_bytes([octets[12], octets[13], octets[14], octets[15]]);
    format!("{:04}", brut % 10_000)
}

/// Jeton de réception encodé dans le QR client — aléatoire long.
pub(crate) fn jeton_aleatoire() -> String {
    format!("{}{}", Uuid::now_v7().simple(), Uuid::now_v7().simple())
}

/// Sérialise les composantes d'effort pour l'AFFICHAGE (jamais relues par une
/// règle : le devis figé fait foi par ses trois montants, pas par son détail).
fn composantes_json(c: &tarification::Composantes) -> serde_json::Value {
    serde_json::json!({
        "base": c.base,
        "km": c.km,
        "supplements": c.supplements,
        "effort_paliers": c.effort_paliers,
        "effort_attente": c.effort_attente,
        "effort_arrets": c.effort_arrets,
        "arrondi": c.arrondi,
        "retenue_vendeur": c.retenue_vendeur,
    })
}

/// Relit les composantes écrites par [`composantes_json`]. Une clé absente vaut
/// 0 : un détail d'affichage incomplet ne doit jamais faire échouer une lecture
/// de commande.
fn composantes_depuis_json(v: serde_json::Value) -> tarification::Composantes {
    let lire = |cle: &str| v.get(cle).and_then(serde_json::Value::as_i64).unwrap_or(0);
    tarification::Composantes {
        base: lire("base"),
        km: lire("km"),
        supplements: lire("supplements"),
        effort_paliers: lire("effort_paliers"),
        effort_attente: lire("effort_attente"),
        effort_arrets: lire("effort_arrets"),
        arrondi: lire("arrondi"),
        retenue_vendeur: lire("retenue_vendeur"),
    }
}
