//! Surface HTTP **CLIENT** du cycle CMD (crate `commandes`) : devis de panier,
//! création, suivi, annulation, décisions de substitution, intention d'appel.
//!
//! Contrat auto-collecté par utoipa-actix-web (patron `qr_http`). Toute route
//! sous `bearerAuth`, rôle `Client`, et **propriété** vérifiée dans le `WHERE`
//! du domaine — jamais par un contrôle après coup.
//!
//! Erreurs rendues `{ code, message_cle }` par [`crate::erreurs_commandes`] :
//! un même refus rend le même statut et la même clé sur les trois surfaces.

use actix_web::{get, post, web, HttpResponse};
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

// ── Suivi (US6 / CMD-05) ───────────────────────────────────────────────────

/// Position du coursier, **toujours accompagnée de son âge**.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = PositionSuivi)]
pub struct PositionSuiviDto {
    /// Latitude.
    pub lat: f64,
    /// Longitude.
    pub lon: f64,
    /// Ancienneté du relevé, en secondes. L'app affiche « il y a 12 s » et
    /// n'invente JAMAIS une position (FR-040, maquette C4-4d).
    pub age_s: i64,
}

/// L'arrêt où en est le coursier.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ArretCourantSuivi)]
pub struct ArretCourantDto {
    /// Arrêt.
    pub arret_id: Uuid,
    /// Nom du vendeur (`null` sur l'arrêt de remise).
    pub prestataire_nom: Option<String>,
    /// Rang dans l'itinéraire.
    pub ordre: i16,
    /// Statut de l'arrêt.
    pub statut: String,
}

/// Progression de la course, en ARRÊTS DE COLLECTE.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ProgressionSuivi)]
pub struct ProgressionSuiviDto {
    /// Collectes résolues (collectées ou indisponibles).
    pub collectes_faites: i64,
    /// Nombre total de collectes — **la remise n'en est pas une** (P1).
    pub collectes_total: i64,
    /// Arrêt courant.
    pub arret_courant: Option<ArretCourantDto>,
}

/// Le coursier affecté, tel que l'écran de suivi le montre.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CoursierSuivi)]
pub struct CoursierSuiviDto {
    /// Identifiant du coursier.
    pub id: Uuid,
    /// Prénom — **toujours `null` ce cycle** : `comptes.compte` ne porte aucun
    /// nom (cycle CPT), et rien ne sera inventé pour remplir un champ.
    pub prenom: Option<String>,
    /// Note moyenne — **toujours `null` ce cycle** : les avis appartiennent au
    /// cycle AVI, qui n'existe pas encore.
    pub note: Option<f64>,
    /// Vrai si l'app peut proposer d'appeler.
    pub appel_possible: bool,
}

/// Proposition de remplacement en attente de décision (maquette C4-4c).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SubstitutionSuivi)]
pub struct SubstitutionSuiviDto {
    /// Proposition.
    pub id: Uuid,
    /// Ligne concernée.
    pub ligne_id: Uuid,
    /// Nom de l'article proposé.
    pub article_nom: String,
    /// Prix proposé (unités mineures).
    pub prix_unites: i64,
    /// Prix de la ligne d'origine (unités mineures).
    pub ancien_prix_unites: i64,
    /// Clé de la photo déposée par le coursier.
    pub photo_cle: String,
    /// Secondes restantes pour décider.
    pub reste_s: i64,
}

/// Vue de suivi complète (contrat §1.3).
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = SuiviCommande)]
pub struct SuiviCommandeDto {
    /// Commande.
    pub id: Uuid,
    /// État de très haut niveau.
    pub etat: String,
    /// **Clé i18n** de l'état affiché — jamais une phrase (constitution VII).
    pub etat_cle: String,
    /// Instant du dernier changement d'état.
    pub etat_le: chrono::DateTime<chrono::Utc>,
    /// Montant des articles (révisé si des articles ont sauté).
    pub montant_articles_unites: i64,
    /// Total à payer.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Livraison, si la commande en a une (composant 0..n).
    pub livraison_id: Option<Uuid>,
    /// État logistique.
    pub livraison_etat: Option<String>,
    /// Progression par arrêt.
    pub progression: ProgressionSuiviDto,
    /// Coursier affecté.
    pub coursier: Option<CoursierSuiviDto>,
    /// Dernière position connue — `null` si aucune (research R13).
    pub position: Option<PositionSuiviDto>,
    /// Code et QR de remise — **propriétaire seul** (R6).
    pub remise: SecretsRemiseDto,
    /// Proposition de remplacement ouverte.
    pub substitution_en_attente: Option<SubstitutionSuiviDto>,
}

impl From<commandes::suivi::VueSuivi> for SuiviCommandeDto {
    fn from(v: commandes::suivi::VueSuivi) -> Self {
        Self {
            id: v.commande_id,
            etat: v.etat.comme_str().to_owned(),
            etat_cle: v.etat_cle.to_owned(),
            etat_le: v.etat_le,
            montant_articles_unites: v.montant_articles_unites,
            total_unites: v.total_unites,
            devise: v.devise,
            livraison_id: v.livraison_id,
            livraison_etat: v.livraison_etat.map(|e| e.comme_str().to_owned()),
            progression: ProgressionSuiviDto {
                collectes_faites: v.collectes_faites,
                collectes_total: v.collectes_total,
                arret_courant: v.arret_courant.map(|a| ArretCourantDto {
                    arret_id: a.arret_id,
                    prestataire_nom: a.prestataire_nom,
                    ordre: a.ordre,
                    statut: a.statut,
                }),
            },
            coursier: v.coursier_id.map(|id| CoursierSuiviDto {
                id,
                prenom: None,
                note: None,
                appel_possible: true,
            }),
            position: v.position.map(|p| PositionSuiviDto {
                lat: p.lat,
                lon: p.lon,
                age_s: p.age_s,
            }),
            remise: SecretsRemiseDto {
                code_livraison: v.remise.code_livraison,
                jeton_reception: v.remise.jeton_reception,
            },
            substitution_en_attente: v.substitution_en_attente.map(|s| SubstitutionSuiviDto {
                id: s.substitution_id,
                ligne_id: s.ligne_id,
                article_nom: s.article_nom,
                prix_unites: s.prix_unites,
                ancien_prix_unites: s.ancien_prix_unites,
                photo_cle: s.photo_cle,
                reste_s: s.reste_s,
            }),
        }
    }
}

/// Une commande de la liste `GET /moi/commandes`.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = CommandeResumee)]
pub struct CommandeResumeeDto {
    /// Commande.
    pub id: Uuid,
    /// État de très haut niveau.
    pub etat: String,
    /// Clé i18n de l'état affiché.
    pub etat_cle: String,
    /// Création.
    pub cree_le: chrono::DateTime<chrono::Utc>,
    /// Total à payer.
    pub total_unites: i64,
    /// Devise ISO 4217.
    pub devise: String,
    /// Nombre de vendeurs.
    pub nb_vendeurs: i64,
}

/// La liste des commandes du compte.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = MesCommandes)]
pub struct MesCommandesDto {
    /// Commandes, les plus récentes d'abord.
    pub commandes: Vec<CommandeResumeeDto>,
}

/// CMD-05 — suivi complet d'une commande, pour son **propriétaire**.
///
/// Le code et le jeton de remise ne sont servis qu'ici, et qu'au propriétaire :
/// le coursier, lui, ne reçoit que des empreintes (research R6).
#[utoipa::path(
    get,
    path = "/commandes/{id}",
    tag = "commandes",
    params(("id" = Uuid, Path, description = "Commande du compte appelant.")),
    responses(
        (status = 200, description = "Suivi : état en clé i18n, progression par arrêt, position \
         AVEC son âge, code et QR de remise.", body = SuiviCommandeDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue — ou appartenant à un autre compte : \
         les deux sont indiscernables, et c'est voulu.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/commandes/{id}")]
pub async fn suivre_commande(
    auth: Auth,
    chemin: web::Path<Uuid>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let vue = depot
        .suivi(chemin.into_inner(), auth.compte_id, chrono::Utc::now())
        .await?;
    Ok(HttpResponse::Ok().json(SuiviCommandeDto::from(vue)))
}

/// CMD-05 — les commandes du compte, les plus récentes d'abord.
#[utoipa::path(
    get,
    path = "/moi/commandes",
    tag = "commandes",
    responses(
        (status = 200, description = "Commandes du compte, les plus récentes d'abord.",
         body = MesCommandesDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[get("/moi/commandes")]
pub async fn mes_commandes(
    auth: Auth,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let commandes = depot.mes_commandes(auth.compte_id).await?;
    Ok(HttpResponse::Ok().json(MesCommandesDto {
        commandes: commandes
            .into_iter()
            .map(|c| CommandeResumeeDto {
                id: c.commande_id,
                etat: c.etat.comme_str().to_owned(),
                etat_cle: c.etat_cle.to_owned(),
                cree_le: c.cree_le,
                total_unites: c.total_unites,
                devise: c.devise,
                nb_vendeurs: c.nb_vendeurs,
            })
            .collect(),
    }))
}

/// Motif d'une intention d'appel.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = IntentionAppel)]
pub struct IntentionAppelDto {
    /// `suivi` (défaut) | `substitution` | `expiration`.
    pub motif: Option<String>,
}

/// CMD-05 — journalise l'intention d'appeler le coursier (FR-041).
///
/// L'appel part du téléphone : le serveur n'en voit rien et **ne journalise
/// aucun numéro**. Ce qu'il enregistre, c'est qu'un client a eu BESOIN
/// d'appeler — une métrique de friction (minimisation ARTCI).
#[utoipa::path(
    post,
    path = "/commandes/{id}/appel",
    tag = "commandes",
    params(("id" = Uuid, Path, description = "Commande du compte appelant.")),
    request_body = IntentionAppelDto,
    responses(
        (status = 204, description = "Intention journalisée — aucun numéro n'est enregistré."),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue ou appartenant à un autre compte.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/commandes/{id}/appel")]
pub async fn intention_appel(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<IntentionAppelDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let motif = corps.into_inner().motif.unwrap_or_else(|| "suivi".to_owned());
    depot
        .journaliser_appel(
            chemin.into_inner(),
            auth.compte_id,
            &motif,
            chrono::Utc::now(),
        )
        .await?;
    Ok(HttpResponse::NoContent().finish())
}

// ── Décision de substitution (US7 / CMD-06) ────────────────────────────────

/// Décision du client sur une proposition de remplacement.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DecisionSubstitution)]
pub struct DecisionSubstitutionDto {
    /// `true` = accepter le remplacement, `false` = le refuser (l'article est
    /// alors retiré, et rien n'est payé pour lui).
    pub accepte: bool,
}

/// Résultat d'une décision de substitution.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResultatDecisionSubstitution)]
pub struct ResultatDecisionDto {
    /// `acceptee` | `refusee`.
    pub issue: String,
    /// Montant des articles après révision.
    pub montant_articles_unites: i64,
    /// Total à payer après révision.
    pub total_unites: i64,
    /// Prix client du devis de livraison — **inchangé** (FR-050). Servi pour
    /// que le client le VOIE ne pas bouger, pas seulement pour l'affichage.
    pub devis_prix_client_unites: i64,
}

/// CMD-06 — le client accepte ou refuse un remplacement, dans sa fenêtre.
///
/// Acceptée, la ligne est remplacée au prix proposé ; refusée, elle est retirée
/// et n'est pas facturée. Dans les deux cas le **devis de livraison ne bouge
/// pas** (FR-050) et le total reste payé **en une fois** (FR-049).
///
/// Passé l'échéance, la décision est refusée (`409`) : la fenêtre est une
/// promesse faite au coursier autant qu'au client — au-delà, il a déjà agi.
#[utoipa::path(
    post,
    path = "/commandes/{id}/substitutions/{sub}/decision",
    tag = "commandes",
    params(
        ("id" = Uuid, Path, description = "Commande du compte appelant."),
        ("sub" = Uuid, Path, description = "Proposition de remplacement ouverte."),
    ),
    request_body = DecisionSubstitutionDto,
    responses(
        (status = 200, description = "Décision appliquée ; montants révisés, devis inchangé.",
         body = ResultatDecisionDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis, ou proposition d'un autre compte.",
         body = ErreurApiDto),
        (status = 404, description = "Proposition inconnue.", body = ErreurApiDto),
        (status = 409, description = "Fenêtre de décision expirée, ou proposition déjà close.",
         body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/commandes/{id}/substitutions/{sub}/decision")]
pub async fn decider_substitution(
    auth: Auth,
    chemin: web::Path<(Uuid, Uuid)>,
    corps: web::Json<DecisionSubstitutionDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let (_commande_id, substitution_id) = chemin.into_inner();
    let (issue, montants) = depot
        .decider_substitution(
            substitution_id,
            auth.compte_id,
            corps.into_inner().accepte,
            chrono::Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(ResultatDecisionDto {
        issue: issue.comme_str().to_owned(),
        montant_articles_unites: montants.montant_articles_unites,
        total_unites: montants.total_unites,
        devis_prix_client_unites: montants.devis_prix_client,
    }))
}

// ── Annulation (US8 / CMD-07) ──────────────────────────────────────────────

/// Demande d'annulation.
#[derive(Debug, Deserialize, ToSchema)]
#[schema(as = DemandeAnnulation)]
pub struct DemandeAnnulationDto {
    /// Clé i18n du motif. **Obligatoire pour un admin** (FR-054), facultative
    /// pour le client — il n'a pas à se justifier.
    pub motif_cle: Option<String>,
}

/// Ce qu'une annulation a produit.
#[derive(Debug, Serialize, ToSchema)]
#[schema(as = ResultatAnnulation)]
pub struct ResultatAnnulationDto {
    /// Commande annulée.
    pub commande_id: Uuid,
    /// Vrai si rien n'avait encore été acheté : annulation SANS FRAIS.
    pub sans_frais: bool,
    /// Part due au coursier (unités mineures) — 0 si sans frais.
    pub part_coursier_due: i64,
    /// Montant déjà avancé chez les vendeurs.
    pub montant_avance: i64,
    /// Vrai si la commande était prépayée : un remboursement est dû.
    pub remboursement_du: bool,
    /// Devise ISO 4217.
    pub devise: String,
}

impl From<commandes::AnnulationFaite> for ResultatAnnulationDto {
    fn from(a: commandes::AnnulationFaite) -> Self {
        Self {
            commande_id: a.commande_id,
            sans_frais: a.sans_frais,
            part_coursier_due: a.part_coursier_due,
            montant_avance: a.montant_avance,
            remboursement_du: a.remboursement_du,
            devise: a.devise,
        }
    }
}

/// CMD-07 — le client annule sa commande.
///
/// **Sans frais tant qu'aucun arrêt n'a été collecté** (FR-052) : la frontière
/// est un fait, pas un délai — personne n'a avancé d'argent, il n'y a rien à
/// facturer. Dès le premier achat, la part du coursier est due.
#[utoipa::path(
    post,
    path = "/commandes/{id}/annuler",
    tag = "commandes",
    params(("id" = Uuid, Path, description = "Commande du compte appelant.")),
    request_body = DemandeAnnulationDto,
    responses(
        (status = 200, description = "Commande annulée ; `sans_frais` dit si quelque chose est dû.",
         body = ResultatAnnulationDto),
        (status = 401, description = "Session absente, invalide ou révoquée.", body = ErreurApiDto),
        (status = 403, description = "Rôle client requis.", body = ErreurApiDto),
        (status = 404, description = "Commande inconnue ou appartenant à un autre compte.",
         body = ErreurApiDto),
        (status = 409, description = "État terminal : une commande livrée, annulée ou échouée ne \
         s'annule pas.", body = ErreurApiDto),
    ),
    security(("bearerAuth" = [])),
)]
#[post("/commandes/{id}/annuler")]
pub async fn annuler_commande(
    auth: Auth,
    chemin: web::Path<Uuid>,
    corps: web::Json<DemandeAnnulationDto>,
    depot: web::Data<PgCommandes>,
) -> Result<HttpResponse, ErreurCommandesHttp> {
    auth.exiger_role(Role::Client)?;
    let faite = depot
        .annuler_commande(
            chemin.into_inner(),
            commandes::AuteurAnnulation::Client,
            auth.compte_id,
            corps.into_inner().motif_cle.as_deref(),
            chrono::Utc::now(),
        )
        .await?;
    Ok(HttpResponse::Ok().json(ResultatAnnulationDto::from(faite)))
}
