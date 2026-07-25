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

// ── POST /commandes ────────────────────────────────────────────────────────

/// Demande de création de commande.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeCreationCommande)]
pub struct DemandeCreationDto {
    /// Zone de la commande.
    pub zone_id: Uuid,
    /// Catégorie de service.
    pub categorie_slug: String,
    /// Véhicule demandé.
    pub transport_slug: String,
    /// Adresse du carnet (CPT-05) — ou `lieu` + repère fournis en clair.
    pub adresse_id: Option<Uuid>,
    /// Pin GPS, si aucune adresse du carnet n'est utilisée.
    pub lieu: Option<LieuDto>,
    /// Repère écrit.
    pub repere_texte: Option<String>,
    /// Clé S3 du repère vocal.
    pub repere_vocal_cle: Option<String>,
    /// Lignes du panier.
    pub lignes: Vec<LignePanierDto>,
    /// `cash` | `mobile_money`.
    pub mode_paiement: String,
}

/// Secrets de remise — servis au CLIENT PROPRIÉTAIRE seul (research R6).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SecretsRemise)]
pub struct SecretsRemiseDto {
    /// Code à 4 chiffres.
    pub code_livraison: String,
    /// Jeton encodé dans le QR de réception.
    pub jeton_reception: String,
}

/// État du paiement d'une commande créée.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PaiementCommande)]
pub struct PaiementCommandeDto {
    /// Mode retenu.
    pub mode: String,
    /// `du` | `en_attente` | `regle` | `rembourse`.
    pub etat: String,
    /// Appoint exact à préparer (cash) — le total, en une fois. Aucun chemin
    /// de règlement fractionné n'existe (constitution III).
    pub appoint_exact_unites: i64,
}

/// La livraison créée avec la commande.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = LivraisonCommande)]
pub struct LivraisonCommandeDto {
    /// Identifiant.
    pub id: Uuid,
    /// État logistique initial.
    pub etat: String,
    /// Nombre d'arrêts (collectes + remise).
    pub nb_arrets: i64,
    /// Devis FIGÉ copié à la création — jamais recalculé (R11).
    pub devis: DevisLivraisonDto,
}

/// Commande créée.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = Commande)]
pub struct CommandeDto {
    /// Identifiant (= `Idempotency-Key`).
    pub id: Uuid,
    /// État de très haut niveau.
    pub etat: String,
    /// Montant des articles.
    pub montant_articles_unites: i64,
    /// Total à payer.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Paiement.
    pub paiement: PaiementCommandeDto,
    /// Code et jeton de remise.
    pub remise: SecretsRemiseDto,
    /// Livraison.
    pub livraison: LivraisonCommandeDto,
}

/// Lit l'en-tête `Idempotency-Key` — **obligatoire** (R7). Il DEVIENT
/// l'identifiant de la commande : l'idempotence est structurelle (contrainte de
/// clé primaire), donc vraie même sous concurrence.
fn idempotency_key(requete: &actix_web::HttpRequest) -> Result<Uuid, ErreurCommandesHttp> {
    requete
        .headers()
        .get("idempotency-key")
        .and_then(|v| v.to_str().ok())
        .and_then(|v| v.parse::<Uuid>().ok())
        .ok_or_else(|| {
            ErreurCommandesHttp::Domaine(ErreurCommandes::PanierInvalide(
                "en-tête Idempotency-Key absent ou mal formé".to_owned(),
            ))
        })
}

/// Crée une commande : prix verrouillés, devis figé, code et QR remis
/// immédiatement (CMD-03).
///
/// Un rejeu de la même `Idempotency-Key` rend la commande EXISTANTE avec un
/// corps identique et un `200` — jamais un doublon.
#[utoipa::path(
    post,
    path = "/commandes",
    tag = "commandes",
    params(
        ("Idempotency-Key" = Uuid, Header,
         description = "UUIDv7 client — DEVIENT l'identifiant de la commande (R7)."),
    ),
    request_body = DemandeCreationDto,
    responses(
        (status = 201, description = "Commande créée : tronc, livraison, segment, arrêts \
         (collectes ordonnées + remise), prix verrouillés, devis figé, code et QR.",
         body = CommandeDto),
        (status = 200, description = "Rejeu de la même clé — la commande EXISTANTE, corps identique.",
         body = CommandeDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Compte bloqué, téléphone non vérifié, ou rôle client absent.",
         body = ErreurApiDto),
        (status = 409, description = "Catégorie non mixable, vendeur fermé, article indisponible, \
         ou espèces indisponibles.", body = ErreurApiDto),
        (status = 422, description = "Repère manquant, panier invalide, clé d'idempotence absente.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/commandes")]
pub async fn creer_commande(
    auth: Auth,
    requete: actix_web::HttpRequest,
    corps: web::Json<DemandeCreationDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let id = idempotency_key(&requete)?;
    let corps = corps.into_inner();

    let lignes = corps
        .lignes
        .iter()
        .map(LignePanierDto::vers_domaine)
        .collect::<Result<Vec<_>, _>>()?;
    let mode_paiement: commandes::ModePaiement = corps.mode_paiement.parse()?;

    let creee = depot
        .creer_commande(commandes::creation::DemandeCreation {
            id,
            client_id: auth.compte_id,
            zone_id: corps.zone_id,
            categorie_slug: corps.categorie_slug,
            transport_slug: corps.transport_slug,
            adresse_id: corps.adresse_id,
            lieu: corps.lieu.map(|l| (l.lat, l.lon)),
            repere_texte: corps.repere_texte,
            repere_vocal_cle: corps.repere_vocal_cle,
            lignes,
            mode_paiement,
        })
        .await?;

    let dto = CommandeDto {
        id: creee.id,
        etat: creee.etat.comme_str().to_owned(),
        montant_articles_unites: creee.montant_articles_unites,
        total_unites: creee.total_unites,
        devise: creee.devise.clone(),
        paiement: PaiementCommandeDto {
            mode: creee.mode_paiement.comme_str().to_owned(),
            etat: if creee.mode_paiement == commandes::ModePaiement::Cash {
                "du".to_owned()
            } else {
                "en_attente".to_owned()
            },
            // Le SEUL montant encaissable est le total : il n'existe aucune
            // surface qui accepte une fraction (SC-005).
            appoint_exact_unites: creee.total_unites,
        },
        remise: SecretsRemiseDto {
            code_livraison: creee.secrets.code_livraison.clone(),
            jeton_reception: creee.secrets.jeton_reception.clone(),
        },
        livraison: LivraisonCommandeDto {
            id: creee.livraison_id,
            etat: "assignee".to_owned(),
            nb_arrets: creee.nb_arrets,
            devis: devis_dto(&creee.devis),
        },
    };

    // 200 au rejeu, 201 à la création : le client distingue « c'était déjà
    // fait » de « je viens de le faire », sans corps différent.
    Ok(if creee.rejeu {
        HttpResponse::Ok().json(dto)
    } else {
        HttpResponse::Created().json(dto)
    })
}
