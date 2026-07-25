//! Surface HTTP **CLIENT** du cycle CMD (crate `commandes`) : devis de panier,
//! création, suivi, annulation, décisions de substitution, intention d'appel.
//!
//! Contrat auto-collecté par utoipa-actix-web (patron `qr_http`). Toute route
//! sous `bearerAuth`, rôle `Client`, et **propriété** vérifiée dans le `WHERE`
//! du domaine — jamais par un contrôle après coup.
//!
//! Erreurs rendues `{ code, message_cle }` par [`crate::erreurs_commandes`] :
//! un même refus rend le même statut et la même clé sur les trois surfaces.

use actix_web::{post, web, HttpResponse};
use commandes::{ErreurCommandes, LignePanier, PgCommandes, PreferenceSubstitution};
use comptes::Role;
use serde::{Deserialize, Serialize};
use utoipa::ToSchema;
use uuid::Uuid;

use crate::auth_http::{Auth, ErreurApiDto};
use crate::erreurs_commandes::ErreurCommandesHttp;

// ── DTO d'entrée ───────────────────────────────────────────────────────────

/// Une ligne de panier soumise.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = LignePanier)]
pub struct LignePanierDto {
    /// Vendeur chez qui l'article est pris.
    pub prestataire_id: Uuid,
    /// Article demandé.
    pub article_id: Uuid,
    /// Quantité (> 0).
    pub quantite: i16,
    /// Que faire si l'article manque : `remplacer` | `appeler` | `retirer`.
    /// Absent = `appeler`, le défaut produit (CMD-01).
    pub preference: Option<String>,
}

impl LignePanierDto {
    fn vers_domaine(&self) -> Result<LignePanier, ErreurCommandes> {
        let preference = match self.preference.as_deref() {
            None => PreferenceSubstitution::default(),
            Some(p) => p.parse()?,
        };
        Ok(LignePanier {
            prestataire_id: self.prestataire_id,
            article_id: self.article_id,
            quantite: self.quantite,
            preference,
        })
    }
}

/// Position d'un lieu (pin GPS).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = Lieu)]
pub struct LieuDto {
    /// Latitude.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
}

/// Demande de devis de panier — **aucun effet de bord** (P4).
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeDevisPanier)]
pub struct DemandeDevisPanierDto {
    /// Zone de la commande (résout mixage, plafonds, devise).
    pub zone_id: Uuid,
    /// Catégorie de service (`marche`, `restauration`…).
    pub categorie_slug: String,
    /// Véhicule demandé (`moto`, `velo`…).
    pub transport_slug: String,
    /// Lieu de prestation — destination de la course.
    pub lieu: LieuDto,
    /// Lignes du panier, dans l'ordre de composition.
    pub lignes: Vec<LignePanierDto>,
}

// ── DTO de sortie ──────────────────────────────────────────────────────────

/// Une ligne résolue contre le catalogue.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LigneDevis)]
pub struct LigneDevisDto {
    /// Article.
    pub article_id: Uuid,
    /// Nom de l'article.
    pub nom: String,
    /// Quantité.
    pub quantite: i16,
    /// Prix unitaire courant (unités mineures).
    pub prix_unites: i64,
    /// Sous-total de la ligne (unités mineures).
    pub sous_total_unites: i64,
    /// Préférence de substitution retenue.
    pub preference: String,
}

/// Les lignes d'un vendeur, regroupées (maquette C3-3a).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = GroupeVendeur)]
pub struct GroupeVendeurDto {
    /// Vendeur.
    pub prestataire_id: Uuid,
    /// Nom affiché sur la carte vendeur.
    pub nom: String,
    /// Nombre d'articles du groupe.
    pub nb_articles: i32,
    /// Sous-total du vendeur (unités mineures).
    pub sous_total_unites: i64,
    /// Lignes du vendeur.
    pub lignes: Vec<LigneDevisDto>,
}

/// Détail des composantes du devis (affichage du récapitulatif).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ComposantesDevis)]
pub struct ComposantesDevisDto {
    /// Prix client de base.
    pub base: i64,
    /// Composante kilométrique.
    pub km: i64,
    /// Suppléments (pluie, plage horaire…).
    pub supplements: i64,
    /// Effort — paliers d'articles.
    pub effort_paliers: i64,
    /// Effort — prime d'attente.
    pub effort_attente: i64,
    /// Effort — suppléments d'arrêt.
    pub effort_arrets: i64,
    /// Reliquat d'arrondi (abonde la part coursier).
    pub arrondi: i64,
    /// Retenue vendeur (VND-08).
    pub retenue_vendeur: i64,
}

/// Devis de livraison figé (cycle 007).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DevisLivraison)]
pub struct DevisLivraisonDto {
    /// Prix payé par le client (unités mineures).
    pub prix_client_unites: i64,
    /// Part reversée au coursier.
    pub part_coursier_unites: i64,
    /// Marge Mefali.
    pub marge_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Distance routière totale (m).
    pub distance_m: i64,
    /// Durée estimée (s).
    pub eta_s: i64,
    /// Vrai si la distance vient du repli vol d'oiseau (constitution IV).
    pub degraded: bool,
    /// Détail des composantes.
    pub composantes: ComposantesDevisDto,
    /// Ordre de passage retenu pour les retraits.
    pub ordre_arrets: Vec<usize>,
}

/// Décision d'encaissement (maquette C3-3b).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PaiementPanier)]
pub struct PaiementPanierDto {
    /// Le paiement en espèces est possible.
    pub cash_autorise: bool,
    /// Clé i18n de la RAISON du refus (`null` si autorisé) — le client voit
    /// pourquoi le cash est grisé, jamais un bouton mort.
    pub motif_cle: Option<String>,
    /// Plafond appliqué (unités mineures).
    pub plafond_unites: i64,
}

/// Une commande telle qu'elle sortirait de la scission.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CommandeProposee)]
pub struct CommandeProposeeDto {
    /// Clé i18n du libellé.
    pub libelle_cle: String,
    /// Total des ARTICLES de cette commande (unités mineures).
    pub total_articles_unites: i64,
    /// Articles qui la composeraient.
    pub articles: Vec<Uuid>,
}

/// Proposition de scission — une seule surface pour ses deux causes (R9).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ScissionProposee)]
pub struct ScissionProposeeDto {
    /// `categorie_non_mixable` | `plafond_eclatement`.
    pub cause: String,
    /// Clé i18n du message affiché.
    pub message_cle: String,
    /// Prévisualisation CHIFFRÉE des commandes résultantes.
    pub commandes_proposees: Vec<CommandeProposeeDto>,
}

/// Réponse du devis de panier.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = DevisPanier)]
pub struct DevisPanierDto {
    /// Regroupement par vendeur.
    pub groupes: Vec<GroupeVendeurDto>,
    /// Montant des ARTICLES seuls (unités mineures).
    pub montant_articles_unites: i64,
    /// Devis de livraison.
    pub devis: DevisLivraisonDto,
    /// Total à payer = articles + prix client du devis.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Décision d'encaissement.
    pub paiement: PaiementPanierDto,
    /// Proposition de scission, ou `null`.
    pub scission: Option<ScissionProposeeDto>,
}

// ── Endpoint ───────────────────────────────────────────────────────────────

/// Devis d'un panier multi-vendeurs — **sans aucun effet de bord** (CMD-01).
///
/// Regroupe par vendeur, chiffre les frais via le moteur tarifaire, et renvoie
/// les deux déclencheurs de proposition de scission en UNE seule surface.
/// Aucune ligne n'est écrite, aucune commande n'est créée : rien n'est engagé
/// tant que le client n'a pas confirmé (FR-010, research R8).
#[utoipa::path(
    post,
    path = "/paniers/devis",
    tag = "commandes",
    request_body = DemandeDevisPanierDto,
    responses(
        (status = 200, description = "Panier chiffré : groupes, sous-totaux, devis détaillé, \
         drapeau de paiement et bloc de scission. AUCUNE écriture, aucune commande créée.",
         body = DevisPanierDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis.", body = ErreurApiDto),
        (status = 409, description = "Vendeur fermé ou article indisponible.", body = ErreurApiDto),
        (status = 422, description = "Panier vide, quantité nulle, catégorie inactive.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/paniers/devis")]
pub async fn devis_panier(
    auth: Auth,
    corps: web::Json<DemandeDevisPanierDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let corps = corps.into_inner();

    let lignes: Vec<LignePanier> = corps
        .lignes
        .iter()
        .map(LignePanierDto::vers_domaine)
        .collect::<Result<_, _>>()?;

    let panier = depot
        .resoudre_panier(corps.zone_id, &corps.categorie_slug, &lignes)
        .await?;
    let devis = depot
        .evaluer_panier(
            &panier,
            (corps.lieu.lat, corps.lieu.lon),
            &corps.transport_slug,
            chrono::Utc::now(),
        )
        .await?;

    let montant_articles_unites = panier.montant_articles_unites();
    let total_unites = montant_articles_unites + devis.prix_client;
    let paiement = depot
        .decision_paiement(
            corps.zone_id,
            auth.compte_id,
            &corps.categorie_slug,
            total_unites,
        )
        .await?;

    // Une SEULE proposition, quelles que soient les causes réunies (R9). Elle
    // est journalisée pour la métrique SC-006 — c'est la seule écriture que ce
    // chemin puisse produire, et seulement quand une proposition est réellement
    // formulée : le devis nominal reste strictement muet (P4).
    let scission = commandes::panier::proposer_scission(&panier, devis.proposer_scission);
    if let Some(proposition) = &scission {
        depot
            .journaliser_scission_proposee(
                auth.compte_id,
                &panier,
                proposition.cause,
                proposition.commandes_proposees.len(),
            )
            .await?;
    }

    Ok(HttpResponse::Ok().json(DevisPanierDto {
        groupes: panier
            .groupes
            .iter()
            .map(|g| GroupeVendeurDto {
                prestataire_id: g.prestataire_id,
                nom: g.nom.clone(),
                nb_articles: g.nb_articles(),
                sous_total_unites: g.sous_total_unites(),
                lignes: g
                    .lignes
                    .iter()
                    .map(|l| LigneDevisDto {
                        article_id: l.ligne.article_id,
                        nom: l.nom.clone(),
                        quantite: l.ligne.quantite,
                        prix_unites: l.prix_unites,
                        sous_total_unites: l.sous_total_unites(),
                        preference: l.ligne.preference.comme_str().to_owned(),
                    })
                    .collect(),
            })
            .collect(),
        montant_articles_unites,
        devis: devis_dto(&devis),
        total_unites,
        devise: panier.devise.clone(),
        paiement: PaiementPanierDto {
            cash_autorise: paiement.cash_autorise,
            motif_cle: paiement.message_cle().map(str::to_owned),
            plafond_unites: paiement.plafond_unites,
        },
        scission: scission.map(|s| ScissionProposeeDto {
            cause: s.cause.comme_str().to_owned(),
            message_cle: s.message_cle,
            commandes_proposees: s
                .commandes_proposees
                .into_iter()
                .map(|c| CommandeProposeeDto {
                    libelle_cle: c.libelle_cle,
                    total_articles_unites: c.total_articles_unites,
                    articles: c.lignes.iter().map(|l| l.article_id).collect(),
                })
                .collect(),
        }),
    }))
}

/// Projette un devis du domaine tarification vers le contrat.
pub(crate) fn devis_dto(d: &tarification::Devis) -> DevisLivraisonDto {
    DevisLivraisonDto {
        prix_client_unites: d.prix_client,
        part_coursier_unites: d.part_coursier,
        marge_unites: d.marge,
        devise: d.devise.clone(),
        distance_m: d.distance_m,
        eta_s: d.eta_s,
        degraded: d.degraded,
        composantes: ComposantesDevisDto {
            base: d.composantes.base,
            km: d.composantes.km,
            supplements: d.composantes.supplements,
            effort_paliers: d.composantes.effort_paliers,
            effort_attente: d.composantes.effort_attente,
            effort_arrets: d.composantes.effort_arrets,
            arrondi: d.composantes.arrondi,
            retenue_vendeur: d.composantes.retenue_vendeur,
        },
        ordre_arrets: d.ordre.clone(),
    }
}
