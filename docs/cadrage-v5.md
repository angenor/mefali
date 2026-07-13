# Mefali — Document de cadrage MVP

*Livraison restauration & courses auprès de vendeurs agréés — Ville de lancement : Tiassalé, Côte d'Ivoire*
*Version 5.0 — Document de référence produit & technique*

---

## 1. Résumé exécutif

Mefali lance à **Tiassalé** un service de **livraison de repas et de courses auprès d'un réseau fermé de vendeurs agréés**, identifiés par un **QR code scanné par le coursier à chaque récupération** (traçabilité, anti-fraude, données d'exploitation).

**Positionnement** : la livraison est le **premier vertical** d'une plateforme de services de proximité appelée à en accueillir d'autres (prestations à domicile — plomberie, électricité… —, e-entrepôt/fulfillment). L'architecture est conçue en conséquence (§11) : le cœur de commande ne présuppose jamais une livraison, l'entité centrale est le **prestataire** (le vendeur en est la spécialisation MVP), et le dispatch raisonne en **capacités** (les types de véhicule n'en sont que le premier cas).

Piliers du modèle :

- **Promotion de lancement — livraison gratuite** (1 à 2 mois) : le client ne paie que le prix des articles, et Mefali s'engage à payer les coursiers au fixe (jour ou mois) pendant la promo — un engagement opérationnel et marketing, **pas une fonctionnalité produit**. Ensuite, frais de livraison de 100–500 FCFA intégralement reversés au coursier, puis à partir du mois 4 : marge Mefali de 25–100 FCFA par livraison + **commission vendeur dégressive** par tranches de chiffre d'affaires. Le client ne paie jamais de frais de service.
- **Freemium B2B** : app vendeur minimale gratuite et facultative dès le MVP ; modules avancés payants plus tard.
- **Dispatch automatique dès le jour 1** (contrainte de personnel et de budget assumée).
- **Infrastructure conçue pour la suite sans la construire** : évolution en **plateforme de prestation de services** (artisans, e-entrepôt…) via un cœur de commande sans logistique intrinsèque et une entité prestataire générale ; multi-villes/pays jusqu'au niveau village, multi-devises, livraisons interville multi-segments, multi-véhicules, multi-sites, flotte de livreurs propre au vendeur, et **divergence des workflows par vertical** — provisions de modèle de données uniquement au MVP.
- **Pilotage par les données** : module de métriques (produit + opérations) dès le MVP.

**Objectif : viabilité et indispensabilité d'abord.** La rentabilité est visée au-delà de 12 mois ; le pilotage se fait sur l'usage, la rétention et le revenu coursier, avec un burn maîtrisé financé par la levée amis & famille.

---

## 2. Marché et ville de lancement

Hypothèses de travail à confirmer sur le terrain pendant la préparation :

| Hypothèse | Valeur estimée | Validation |
|-----------|---------------|------------|
| Population urbaine Tiassalé | ~40 000–60 000 hab. | RGPH 2021, mairie |
| Panier moyen maquis / restaurant | 1 000–3 000 FCFA | Relevé terrain sur 20 vendeurs |
| Frais de livraison acceptables (après période gratuite) | 100–500 FCFA (à pied → moto) | Bêta fermée + fin de période gratuite |
| Cible initiale | Fonctionnaires, employés de banques/agences, commerçants du centre, jeunes actifs connectés | Interviews + bêta |
| Moment de pointe | Déjeuner 11h30–14h en semaine | Bêta fermée |

**Atouts** : zéro concurrence organisée, ville compacte (tout le centre à moins de 10 min en moto → rayon de dispatch 3–4 km), bouche-à-oreille puissant, coûts d'exploitation faibles.

**Risques assumés** : habitude de commande à créer, volume absolu limité, sensibilité prix — d'où la **livraison gratuite au lancement**, la gratuité vendeur prolongée, et un service irréprochable sur le créneau déjeuner. La transition vers la livraison payante est annoncée dès le premier jour (« offre de lancement jusqu'au JJ/MM ») pour ne pas créer un droit acquis.

Réplication : Divo au mois 6+ avec le playbook validé et des seuils relevés (densité supérieure).

---

## 3. Périmètre du MVP

### 3.1 Dans le MVP

| Composant | Description |
|-----------|-------------|
| **Livraison restauration** | Commande depuis le catalogue des restaurants/maquis agréés, récupération et livraison par coursier. |
| **Courses chez vendeurs agréés** | Multi-catégories (boutique, marché, pharmacie hors ordonnance, gaz, quincaillerie…) en mode coursier-acheteur, uniquement auprès des vendeurs agréés. **Panier multi-vendeurs natif** (indispensable au marché : une vendeuse a rarement tout le panier) ; la restauration reste mono-vendeur par commande. |
| **App Mefali (client)** | Flutter, Android d'abord. |
| **App Mefali Pro (coursier + vendeur)** | Flutter, une seule app, interface selon le rôle ; rôles cumulables sur un compte. |
| **App vendeur minimale (facultative)** | Ouvert/fermé, stock/rupture, accepter/refuser. Intégrée à Mefali Pro. |
| **Console d'administration + web public** | Nuxt 4 : admin (dispatch, CRUD, tarification, modération, métriques) + fiches vendeurs publiques (cible du scan QR). |
| **Dispatch automatique** | Assignation sans intervention humaine, escalade vers un écran d'alerte admin. |
| **Réseau agréé + QR** | Agrément, charte, plaque QR, scan obligatoire à la récupération. |
| **Moteur de tarification** | Éditable dans l'admin (zone, distance **par itinéraire routier**, temps, véhicule, point relais) ; marge Mefali éditable ; livraison offerte par le vendeur ; **grille d'effort** (articles, attente — multi-arrêts prêt). |
| **Merchandising catalogue** | Prix barrés (promotions), badge « livraison gratuite (à partir de X) », alerte « me prévenir au retour ». |
| **Paiement** | Cash à la livraison (défaut, avance coursier plafonnée, **jamais de paiement partiel**) + **mobile money via agrégateur** (Wave, Orange Money, MTN MoMo, Moov… selon l'agrégateur retenu). |
| **Notifications** | Push FCM prioritaire ; SMS strictement limités. |
| **Métriques** | Taxonomie d'événements produit + opérations, ingestion tolérante au hors-ligne, agrégats quotidiens, exploration Metabase. |

### 3.2 Hors MVP (infrastructure prête le cas échéant, voir §11)

**Tout ce qui concerne l'hôtellerie** (annuaire compris — vertical à workflow non-livraison, module séparé en phase 2+) ; wallet interne ; IA ; colis libre A→B ; livraison interville (modèle prêt) ; multi-sites vendeur (modèle prêt) ; **flotte de livreurs propre au vendeur** (modèle prêt — le vendeur ne paiera alors que les frais Mefali de 25–100 FCFA/livraison, phase 2+) ; abonnements ; marketplace de livreurs ; desktop.

**Règle de gouvernance** : toute fonctionnalité qui n'augmente pas directement (a) les commandes/jour ou (b) la fiabilité des livraisons est reportée. Sans exception pendant les 6 premiers mois.

---

## 4. Catégories de services — activation par configuration

Chaque catégorie est une **configuration** : champs de fiche, politique photo à la récupération (obligatoire / facultative / désactivée — éditable aussi par vendeur et par seuil de montant), workflow vendeur, véhicule minimal, **seuil d'activation par ville** (éditable).

| Catégorie | Particularités | Disponibilité |
|-----------|----------------|---------------|
| Restauration / maquis | Acceptation vendeur si app installée, sinon coursier commande sur place ; délais de préparation. | MVP |
| Boutique / supérette | Coursier-acheteur, substitutions fréquentes, listes parfois longues (→ grille d'effort, §9.3). | MVP |
| Marché | Fiches par étal agréé, articles à prix variable (fourchette + confirmation sur place) ; **panier multi-étals natif** (suppléments d'arrêt réduits entre étals voisins, §9.3). | MVP |
| Pharmacie | Hors ordonnance uniquement ; photo de récupération recommandée. | MVP |
| Dépôt de gaz | Le client remet la bouteille vide (champ « contenant à récupérer ») ; véhicule ≥ moto/tricycle. | MVP |
| Quincaillerie | Poids/volume → véhicule adapté calculé par la commande. | MVP |
| Pressing | Nécessite la **commande aller-retour** (2 segments planifiés). | Dès la livraison du multi-segment (cible M2–M3 post-lancement) |

---

## 5. Réseau de vendeurs agréés et système QR

### 5.1 Processus d'agrément

1. **Identification terrain** : visite, grille simple (propreté, régularité, réputation, capacité à tenir un délai).
2. **Charte qualité signée** : hygiène, prix identiques sur place et sur Mefali, délais, joignabilité — et acceptation de la **retenue à la source** si le vendeur choisit d'offrir la livraison (§9.2).
3. **Fiche vendeur** : photos, catalogue avec prix, horaires, position GPS, contact, délai de préparation moyen.
4. **Remise de la plaque QR** plastifiée « Vendeur agréé Mefali ».
5. **Réévaluation continue** : notes clients + signalements coursiers + taux de rupture constatée. Trois incidents graves ou note < 3,5/5 sur 20 commandes → suspension et re-visite.

**Paiement du vendeur : immédiat.** Le coursier paie à la récupération (cash de son avance, ou mobile money). Si le vendeur offre la livraison, le coursier paie **montant articles − frais de livraison** : la retenue à la source évite toute dette à suivre.

### 5.2 Ce que garantit le QR — et ce qu'il ne garantit pas

| Le scan garantit | Il ne garantit pas |
|------------------|--------------------|
| Présence physique du coursier chez un vendeur **agréé** (horodatage serveur + géolocalisation croisée) | La qualité intrinsèque du produit (→ agrément + notes) |
| Traçabilité complète commande/coursier/vendeur/instant | La conformité de l'article pris (→ photo de récupération quand activée) |
| Anti-fraude : impossible de marquer « récupéré » à distance | La fraîcheur à la livraison |
| Données réelles : temps de préparation, fiabilité, volumes par vendeur | |

### 5.3 Spécification du QR

- **Contenu** : URL courte `mefali.ci/v/{vendor_id}` avec jeton signé (HMAC), révocable côté serveur (vendeur suspendu → QR inactif sans changer la plaque).
- **Scan en course** : correspondance vendeur/commande, position GPS < ~100 m (paramétrable), horodatage serveur.
- **Scan hors contexte** : fiche publique du vendeur (Nuxt SSR) avec catalogue et lien « ouvrir dans l'app » — la plaque est un canal d'acquisition.
- **Dégradé (QR illisible)** : saisie du **code de secours à 4 chiffres** imprimé sur la plaque. Ce code n'est **pas** un identifiant global (aucun problème d'échelle, même avec des millions de vendeurs) : c'est une **confirmation locale** comparée au code du vendeur de la commande active du coursier. Protections : géolocalisation < 100 m toujours exigée + 3 essais maximum. Incident « plaque à remplacer » créé automatiquement.

### 5.4 Multi-sites (provision, hors MVP)

Modèle `vendeur → sites (1..n) → stock et horaires par site`. Le MVP crée un site unique ; l'activation viendra sans migration.

---

## 6. Catalogue, app vendeur minimale et gestion des ruptures

### 6.1 Merchandising catalogue (MVP)

- **Prix barré** : un article peut porter un prix promotionnel avec l'ancien prix barré affiché (contrôle : prix barré > prix actuel). Les promotions sont mesurées (module métriques).
- **Livraison offerte par le vendeur** : configuration par vendeur — {jamais, toujours, à partir de X FCFA d'achat}. Affichage client : badge « Livraison gratuite » ou « Livraison gratuite dès X FCFA ». Financement : retenue à la source (§5.1, §9.2) ; la part du coursier est inchangée.
- **« Me prévenir au retour »** (MVP, décision fondateur) : sur un article en rupture, le client s'abonne en 1 tap ; au retour en stock (bascule vendeur, admin, ou levée du signalement coursier), les abonnés reçoivent un push avec lien direct — la rupture devient un réengagement.

### 6.2 App vendeur minimale (facultative)

- **Statut boutique** : ouvert / fermé / pause (+ horaires par défaut).
- **Disponibilité article** : bascule en stock / rupture, un tap.
- **Commandes entrantes** : sonnerie prolongée, accepter avec délai estimé ou refuser avec motif.

### 6.3 Fallbacks si le vendeur n'a pas l'app ou ne répond pas

| Catégorie | Comportement |
|-----------|--------------|
| Courses (boutique, gaz, marché…) | Aucune réponse vendeur requise : dispatch immédiat, le coursier achète sur place. |
| Restauration, vendeur avec app | Acceptation demandée ; timeout X min (paramétrable) → bascule « coursier commande sur place » ou annulation selon la config de catégorie. |
| Restauration, vendeur sans app | Dispatch direct, le coursier commande sur place. |

### 6.4 Ruptures de stock

- **Trois sources de mise à jour** : le vendeur (app), le **coursier sur place** (masquage automatique après X signalements, paramétrable), l'admin.
- Article en rupture : grisé ou masqué (configurable) + bouton « me prévenir au retour ».
- **Préférences de substitution au panier**, par article : *remplacer par un équivalent* (validation client par push avec photo + prix), *m'appeler*, *retirer l'article*.
- **Score de fiabilité vendeur** : le taux de rupture constatée fait descendre le vendeur dans le catalogue.

### 6.5 Évolutivité

Socle prêt pour le freemium B2B (comptes, sites, catalogues, plans) — voir §11 et §12.

---

## 7. Module coursier

### 7.1 Recrutement, statut, flotte

- **Profil** : conducteur avec véhicule propre, smartphone Android, pièce d'identité, **caution morale locale**.
- **Promotion de lancement (1 à 2 mois — hors produit)** : pendant la « livraison gratuite », Mefali s'engage à payer les coursiers **au fixe** (journalier, ex. 2 500–3 500 FCFA/jour travaillé sur les créneaux définis, ou mensuel équivalent — montant et durée : décision opérationnelle, annexe B). Rien n'est développé pour cela : la présence se vérifie avec les heartbeats existants du dispatch, la paie est manuelle. Ensuite : **paiement à la course** (100 % des frais jusqu'au mois 4, puis frais − marge Mefali) + **grille d'effort** (§9.3).
- **Équipement** : sac isotherme + gilet/casquette Mefali contre caution.
- **Flotte au lancement : 2 à 4 coursiers.** En dessous, pas de fiabilité ; au-dessus, personne ne gagne sa vie après la période au fixe.
- **Véhicules** : chaque coursier déclare ses types de transport ; le dispatch n'offre que les commandes compatibles.

### 7.2 Cycle de vie d'une commande

```
NOUVELLE → ASSIGNÉE → EN_COLLECTE
  [pour chaque arrêt, dans l'ordre optimisé :
     EN_ROUTE_ARRÊT → ARRIVÉ → COLLECTÉ (scan QR + photo si exigée)]
  → EN_LIVRAISON (toutes les collectes terminées)
  → LIVRÉE (QR client / code / dégradé)
Branches : ANNULÉE, ÉCHEC_LIVRAISON (§7.5), EN_ATTENTE_COURSIER (file)
```

Modèle : une livraison = **segments ordonnés** (niveaux transporteur — MVP : 1 segment coursier) ; un segment = **arrêts de collecte (1..n vendeurs) + une remise client**. Chaque arrêt porte son scan QR, sa photo éventuelle, son montant avancé et son statut : le panier multi-vendeurs (courses au marché) est natif, et l'interville de phase 2 réutilisera les segments sans changement.

### 7.3 Dispatch automatique

Pipeline déclenché à la création de la commande ; **tous les paramètres éditables dans l'admin, par zone**.

**Étape 0 — Données temps réel (Redis)** : positions coursiers (`GEOADD`, TTL — un coursier muet sort du pool), état coursier (statut, véhicules, note, **plafond d'avance du jour**, commande active), verrous d'offre (`SET NX EX`). PostgreSQL reste la source de vérité.

**Étape 1 — Éligibilité** : en ligne et disponible ; véhicule compatible ; rayon max (Tiassalé : 4 km) ; **capacité d'avance** pour le cash : **montant total des articles (tous arrêts confondus)** ≤ min(plafond par grille de note, plafond personnel déclaré) — sinon la commande exige un prépaiement mobile money ; paires bloquées exclues.

**Étape 2 — Scoring** (poids éditables) : proximité (ETA par itinéraire si disponible), temps d'inactivité (équité), note, taux d'acceptation.

**Étape 3 — Offre en cascade** : push + sonnerie au meilleur, 30–45 s. Refus/timeout → suivant (premiers timeouts du jour non pénalisés).

**Étape 4 — Broadcast** : après 3 candidats ou 2 min → tous les éligibles, premier accepteur (verrou).

**Étape 5 — Escalade** : non assignée après 5 min → écran d'alerte admin + notification client avec annulation sans frais.

**Étape 6 — Réassignation automatique** : pas de mouvement vers le vendeur en X min ou pas de scan en Y min → relance, retrait, retour au pipeline, incident tracé.

**File d'attente** : aucun coursier éligible → FIFO priorisée, client informé.

### 7.4 Confirmation de livraison — y compris sans internet

1. **Scan du QR client** (jeton signé affiché dans l'app client) ou **code à 4 chiffres**.
2. **Le client n'a pas besoin d'internet au moment de la livraison** : code et QR lui sont remis **dès la création de la commande** (in-app, + SMS selon la règle de fallback critique).
3. **Le coursier hors ligne valide quand même** : à l'assignation, son app pré-télécharge l'**empreinte (hash) du code et du jeton** → vérification locale sans réseau ; l'événement rejoint la file d'actions hors-ligne et se synchronise au retour.
4. **Ultime recours** (les deux hors ligne + code indisponible) : appel au numéro Mefali Tiassalé → **confirmation manuelle par l'admin** depuis l'écran opérations, tracée avec motif.
5. Mode dépôt autorisé par le client : photo au point de livraison + géolocalisation.

### 7.5 Avance coursier et cas limites — « le coursier ne perd jamais »

**Mécanisme** : le coursier avance le paiement au vendeur sur ses fonds lorsque le montant est sous un **seuil back-office fonction de sa note**, croisé avec son **plafond personnel déclaré du jour**. Au-delà → prépaiement mobile money obligatoire. **Aucun paiement partiel, jamais** : soit le coursier encaisse la totalité en cash, soit le client règle la **totalité** par mobile money.

| Cas | Règle |
|-----|-------|
| **Client refuse ou injoignable** (non périssable) | Retour au vendeur → remboursement (charte). Vendeur refuse la reprise → **Mefali indemnise le coursier** et traite le litige vendeur. |
| **Denrée périssable / plat préparé** | Non retournable : **Mefali indemnise le coursier** ; sanction client : 1er refus → prépaiement imposé ; 2e → compte bloqué. Prévention : plafond cash réduit pour la restauration d'un client sans historique. |
| **Client conteste le montant** | Prix verrouillés à la commande, reçu détaillé des deux côtés. Le coursier ne négocie jamais : refus du montant exact = refus. |
| **Client n'a pas l'appoint** | Mention « préparez l'appoint » à la commande ; à défaut : **paiement mobile money de la totalité** sur place, sinon refus. Pas de paiement partiel. |
| **Faux billet** | Formation à la détection, plafonds bas, mobile money encouragé sur les gros montants ; faux billet malgré diligence → fonds d'incidents. |
| **Article non conforme à la livraison** | Faute vendeur : reprise et remboursement obligatoires (charte), sinon suspension. La photo de récupération départage. |
| **Casse en transport** | La photo à la récupération fait foi ; franchise coursier plafonnée, complément par le fonds d'incidents. |
| **Annulation client après achat coursier** | Mêmes règles que le refus. |
| **Client injoignable, vendeur fermé** (soir) | Consigne au local Mefali, re-livraison le lendemain facturée ; périssable → indemnisation + sanction. |
| **Suspicion de faux refus coursier** | Indemnisation conditionnée aux preuves in-app : ≥ 2 appels via l'app, 10 min d'attente géolocalisée, photo sur place. |

**Exposition maîtrisée** : exposition max = flotte × plafond (ex. 4 × 5 000 = 20 000 FCFA) ; fonds d'incidents provisionné (50 000–100 000 FCFA au départ), plafonds bas puis relevés avec les notes.

### 7.6 App coursier — écrans

1. Disponibilité + plafond d'avance du jour + gains du jour (la paie fixe de la promo est gérée hors produit).
2. Offre de course : les **arrêts** (vendeurs dans l'ordre optimisé, distances), destination, **gain total** (déplacement + grille d'effort), **montant total à avancer**, timer.
3. Course active : itinéraire multi-arrêts, **checklist des collectes** (articles regroupés par vendeur), appels via l'app, scan QR **à chaque arrêt**, photo si exigée, transitions.
4. Historique & caisse : avances, remboursements, indemnisations.
5. Signaler / bloquer un client ou un vendeur (motifs prédéfinis → modération ; la paire sort du dispatch).

Position GPS toutes les 15–30 s ; **file d'actions hors-ligne** (scans, photos, états, confirmations) synchronisée au retour du réseau.

---

## 8. Parcours client (B2C)

### 8.1 Écrans

1. **Accueil** : « Manger » et « Faire des courses », catégories activées, recherche.
2. **Fiche vendeur** : photos, catalogue (prix, prix barrés, disponibilité, bouton « me prévenir au retour »), badge livraison offerte le cas échéant, délai estimé, note.
3. **Panier** : articles **regroupés par vendeur** (détail des arrêts et de leurs suppléments visible), préférences de substitution par article, adresse, paiement (cash — montant exact + « préparez l'appoint » — ou mobile money). Mixage restauration + courses → l'app propose de scinder en 2 commandes.
4. **Suivi** : états, position du coursier (itinéraire), appel via l'app, **QR de réception + code disponibles dès la commande**.
5. **Notation** (facultative) : étoiles vendeur + coursier, commentaires prédéfinis + champ libre.

### 8.2 Adressage

- **Pin GPS** avec bouton « Utiliser ma position actuelle »,
- **repère obligatoire : texte OU note vocale** (≤ 30 s, jouable par le coursier) — pour les personnes peu technophiles ou peu lettrées,
- **téléphone obligatoire vérifié par OTP SMS**,
- **adresses enregistrées** dès la première commande.

---

## 9. Moteur de tarification et devises

### 9.1 Moteur de règles — éditable dans l'admin

| Conditions | Sorties |
|------------|---------|
| Zone (arbre : pays > … > ville > commune > village) | Prix client (base + FCFA/km au-delà d'un seuil) |
| Catégorie (optionnel) | Part coursier |
| Type de véhicule | **Marge Mefali** (bornée 25–100, bornes éditables par zone) |
| Tranche de distance **par itinéraire routier** | Devise |
| Plage horaire / jour | |
| Point relais (dimension prête, inutilisée au MVP) | |
| Suppléments activables : pluie, longue distance | |

- **Distance et ETA par itinéraire routier**, jamais à vol d'oiseau : Directions API du fournisseur retenu ou **OSRM auto-hébergé** (extrait OSM Côte d'Ivoire sur le VPS — gratuit). Résultats mis en cache par paire de points arrondis. Dégradé si le service d'itinéraire est indisponible : vol d'oiseau × 1,4, journalisé, pour ne jamais bloquer une commande.
- Priorité entre règles, dates d'effet, simulateur admin obligatoire avant publication, arrondi configurable (25 FCFA).
- **Drapeau de zone « livraison offerte par Mefali »** (période de lancement) : prix client forcé à 0, coursiers au fixe hors moteur.

### 9.2 Livraison offerte par le vendeur

- Configuration vendeur : {jamais, toujours, à partir de X FCFA}. Si active : prix client = 0 (ou 0 au-delà du seuil), part coursier inchangée, financement par **retenue à la source** au moment du paiement vendeur (montant articles − frais). Compatible avec le prépaiement mobile money (la retenue s'opère de la même façon à la récupération).
- **S'applique aux commandes mono-vendeur uniquement** : dans un panier multi-vendeurs, les frais s'appliquent normalement (répartir une gratuité entre plusieurs vendeurs créerait des litiges de retenue — règle simple, inscrite dans la charte).

### 9.3 Grille d'effort (validée — TRF-06, activation à la fin de la promo de lancement)

Compensation des courses lourdes, **100 % reversée au coursier** (la marge Mefali reste fixe), éditable par zone, détaillée au client avant confirmation et sur l'écran d'offre coursier :

- **Paliers d'articles** (actif au MVP, mono-vendeur inclus — grosses listes au marché) : 1–5 : 0 ; 6–10 : +50 ; 11–20 : +100 ; 21+ : +150 FCFA (seeds éditables).
- **Prime d'attente mesurée** (actif au MVP) : écart entre l'arrivée géolocalisée et le scan QR > 15 min → +100 FCFA — calculée sur des événements déjà tracés, donc objective et infalsifiable.
- **Supplément par arrêt supplémentaire, indexé sur la distance au précédent arrêt** (actif au MVP — le panier multi-vendeurs est natif) : arrêt à **moins de 100 m** du précédent (étals voisins au marché) → **+25** ; de 100 m à 1 km → +50 ; au-delà de 1 km → +100 FCFA (seeds éditables). Le premier arrêt est compris dans le prix de base ; plafond optionnel du total des suppléments par commande (paramétrable).

**Cas des arrêts éloignés** (ex. un article au nord de la ville, un autre au sud, client à l'est) : le supplément par arrêt ne couvre que le coût fixe de l'arrêt (se garer, trouver le vendeur, payer, scanner) ; la distance, elle, est prise en charge par la **composante kilométrique calculée sur l'itinéraire complet avec points de passage** (coursier → arrêt 1 → arrêt 2 → client), jamais sur des tronçons isolés. Un panier étalé sur toute la ville est donc facturé — et le coursier rémunéré — sur les kilomètres réels, ce qui rend l'offre acceptable. Compléments : l'**ordre des arrêts est optimisé** automatiquement (permutations, trivial jusqu'à 4 arrêts) ; un **plafond d'éclatement** paramétrable propose au client de scinder sa commande quand le détour total dépasse un seuil ; le prix total affiché avant confirmation autorégule les paniers trop dispersés. **Cas du marché (arrêts quasi collés)** : trois étals voisins n'ajoutent presque aucun kilomètre (l'itinéraire réel entre eux est quasi nul) et seulement +25 par arrêt supplémentaire — l'effort de shopping, lui, est rémunéré par les paliers d'articles et la prime d'attente. Exemple : 12 articles chez 3 étals du marché = frais de déplacement (km réels) + 2 × 25 (arrêts voisins) + 100 (palier 11–20 articles) — proportionné à la réalité du terrain, ni punitif pour le client, ni perdant pour le coursier.

Pendant le drapeau « livraison offerte Mefali » (promo de lancement), la grille est **calculée et journalisée mais non facturée** : les données réelles serviront à calibrer les montants avant la bascule au payant.

### 9.4 Devises

Montants en **unités mineures entières + code ISO 4217** porté par la zone (XOF sans décimales) ; affichage localisé ; grilles tarifaires porteuses de leur devise ; prêt pour une expansion hors zone CFA.

---

## 10. Stack technique

**Règle générale : dernières versions stables.** À l'initialisation du projet, vérifier et figer (lockfiles) les dernières versions stables de chaque brique — Flutter, Shorebird, Actix Web, utoipa, Nuxt 4, PostgreSQL, Redis, Garage — puis les tenir à jour à cadence mensuelle.

### 10.1 Applications mobiles — Flutter + Shorebird

- **Deux apps** : Mefali (client) et Mefali Pro (coursier + vendeur, rôles cumulables).
- **OTA Shorebird** : patchs fréquents du code Dart sans passage store. Limite : les changements natifs passent par le store → stabiliser tôt les plugins (cartes, caméra/scan, notifications, géoloc, audio pour les repères vocaux).
- **Config produit distante** : textes, feature flags, grilles et paramètres servis par l'API — beaucoup de changements sans même un patch.

### 10.2 Backend — Actix Web (Rust)

- Monolithe modulaire : **un crate par domaine**, interfaces (traits) nettes, **schéma PostgreSQL par module**.
- **Cœur de commande générique + extensions par vertical** (§11, provision 11) : le crate `commandes` ne connaît que le tronc commun ; chaque vertical fournit sa table de détails et son implémentation du trait `ServiceWorkflow`.
- **utoipa + utoipa-swagger-ui** : schémas dérivés, `#[utoipa::path]`, Swagger UI protégée hors production, spec sur `/api-docs/openapi.json`.
- **Contrat OpenAPI = source de vérité** : génération des clients Dart (Flutter) et TypeScript (Nuxt) — un contrat, trois consommateurs.

### 10.3 Redis — rôles précis

Positions coursiers (GEO + TTL), verrous d'offres, pub/sub temps réel, cache (catalogue, itinéraires), rate-limiting OTP. Éphémère uniquement.

### 10.4 Garage (stockage objet, API S3)

Photos de course, images catalogue, **notes vocales de repère**, plaques QR (PDF). API S3 → migration transparente. Rétention alignée ARTCI. Mono-nœud au MVP : `replication_mode = 1`, layout assigné au provisioning, buckets créés par le provisioning, une clé d'accès dédiée par usage (backend / job de sauvegarde). Périmètre S3 requis (vérifié au POC) : put/get, multipart, URLs présignées — Garage ne couvre pas 100 % de l'API S3, nos besoins si. *Remplace MinIO, dépôt archivé et sans patchs de sécurité depuis avril 2026 (décision du 2026-07-13, cycle 001-socle-monorepo).*

### 10.5 Console admin & web public — Nuxt 4

- **Un projet Nuxt 4 hybride** : pages publiques en SSR (fiches vendeurs du scan QR, aperçus WhatsApp propres, rapidité sur connexions limitées) ; `/admin/**` en rendu client pur (`ssr: false`).
- Écosystème : Nuxt UI ou PrimeVue, Pinia, TypeScript, client API généré.
- Bascule possible plus tard vers un admin isolé (Vue + Vite) sans réécriture des composants.

### 10.6 Cartographie & itinéraires — critères de l'étude comparative

| Critère | À vérifier |
|---------|-----------|
| Couverture réelle de Tiassalé | Audit terrain rues/quartiers/POI (la couverture OSM des villes ouest-africaines est souvent bonne — à confirmer localement) |
| **Itinéraires (Directions)** | Qualité et coût des itinéraires routiers ; **option OSRM auto-hébergé** (extrait OSM CI sur le VPS, gratuit, ~zéro latence) |
| Geocoding / reverse | Qualité sur adresses non structurées |
| SDK Flutter | `google_maps_flutter` / `mapbox_maps_flutter` / `flutter_map` + tuiles OSM |
| Tuiles hors-ligne | Support et CGU |
| Coûts | Par 1 000 requêtes (cartes **et** itinéraires), plafonds gratuits, projection ×10 |

### 10.7 Paiements — agrégateur au MVP, direct en phase 2+ (décision prise)

- **MVP : un agrégateur** (CinetPay, PayDunya, Bizao, HUB2… — choix restant à faire) pour intégrer **d'un coup tous les moyens de paiement disponibles** : Wave, Orange Money, MTN MoMo, Moov Money, carte selon l'agrégateur. Critères de sélection : frais par transaction, **délais de reversement**, exigences KYB, qualité API/webhooks, couverture des moyens de paiement, fiabilité.
- **Phase 2+ : intégrations directes opérateurs** (Wave d'abord) pour réduire les coûts — nouvelles implémentations derrière le même trait `PaymentProvider`, bascule **par moyen de paiement** via configuration, sans toucher au métier ; l'agrégateur reste en secours.
- Cas d'usage MVP : prépaiement au-dessus des plafonds cash, paiement sur place du montant total, remboursements.

### 10.8 Notifications

Push FCM prioritaire (canal haute importance coursier/vendeur) ; SMS limités : OTP + fallback conditionnel des événements critiques (dont **le code de livraison**, garantissant le scénario client hors-ligne du §7.4) si le push n'est pas accusé en 60 s.

### 10.9 Métriques & données

- **Taxonomie d'événements** produit (ouvertures, vues fiche, ajouts panier, checkout, abandons) et opérations (toutes les transitions, déjà émises par l'outbox), avec propriétés standard (zone, catégorie, rôle, version d'app).
- **Ingestion batchée et idempotente**, tolérante au hors-ligne (file locale dans les apps).
- **Agrégats quotidiens** alimentant les KPIs (§16) et le funnel vue → panier → commande → livraison.
- **Exploration : Metabase auto-hébergé** branché sur PostgreSQL (open source, léger sur VPS) — tableaux de bord sans développement.

### 10.10 Infra & conformité

1 VPS (backend + Postgres + Redis + Garage + OSRM + Metabase) + sauvegardes externalisées testées + monitoring (uptime, Sentry). Immatriculation (CEPICI), déclaration **ARTCI**, CGU/CGV (Mefali intermédiaire, responsabilité sanitaire au vendeur), assurance RC, casque obligatoire.

---

## 11. Prêt pour la suite — sans le construire

« Prêt » = choix de modèle de données et d'interfaces quasi gratuits aujourd'hui, évitant une migration douloureuse demain. **Rien de tout cela n'est développé au MVP.**

1. **Zones en arbre à profondeur variable** (`parent_id` + type ∈ {pays, région, ville, commune, **village**, quartier}) ; configuration par zone → ouvrir un village en phase 2+ = de la configuration, pas du code.
2. **Devises dynamiques** (§9.4).
3. **Livraison = segments ordonnés, chaque segment = arrêts (collectes + remise)** ; le multi-arrêts est actif dès le MVP (panier multi-vendeurs) ; l'interville multi-prestataires (moto → gare routière → car → gare → moto) réutilise les segments, phase 2+.
4. **Points relais génériques** (gare, consigne, boutique partenaire).
5. **Référentiel de types de transport** extensible, activable par zone (à pied → camion).
6. **Multi-sites vendeur** (§5.4).
7. **Plans freemium** (`plan` + `features`, tous « Gratuit » au MVP).
8. **Catégories par configuration** + seuils d'activation.
9. **i18n** fr/en câblé.
10. **Journal d'événements métier (outbox)** → métriques, webhooks futurs, extraction en services.
11. **Divergence des verticales — cœur générique + extensions par service.** Constat : les workflows divergeront fortement (livraison aujourd'hui ; plomberie, e-entrepôt demain). Réponse structurelle : la table `commande` ne porte que le tronc commun **sans aucun champ logistique** (identité, prestataire(s), lieu de prestation, montants, paiement, états de très haut niveau : créée / en cours / terminée / annulée / litige) ; la **`livraison` est un composant optionnel (0..n) rattaché à la commande** — les verticaux de livraison en créent une, une intervention d'artisan n'en crée aucune (et pourra un jour en attacher une pour ses pièces) ; **chaque vertical possède sa table de détails** (`resto_details` aujourd'hui ; `pressing_details` demain ; `intervention_details` en phase N) et son implémentation du **trait `ServiceWorkflow`** (états intermédiaires, validations, hooks de tarification). Un vertical à workflow radicalement différent (hôtellerie, e-entrepôt) sera un **module entièrement séparé** partageant uniquement comptes, zones, prestataires, paiements et notifications. Aucune évolution ne déforme le cœur.
13. **Prestataire = entité générale, vendeur = spécialisation MVP.** L'agrément, la charte, le QR, les sites, les notes, le score de fiabilité et le plan freemium sont portés par le **prestataire** (crate `prestataires`) ; le catalogue d'articles et le stock vivent dans l'extension `vendeur`. Un plombier de phase N est un prestataire d'un autre type qui **réutilise tel quel** l'agrément, la plaque QR, les notes et le dispatch — sans migration.
14. **Dispatch par capacités.** L'éligibilité filtre sur un ensemble de **capacités requises** par la commande, couvertes par le prestataire mobilisé ; au MVP les capacités sont les types de véhicule, demain ce seront aussi des qualifications (plomberie, électricité, froid…). Le filtre est générique dès le premier jour.
12. **Transporteur de segment typé** : {coursier Mefali, **livreur du vendeur** (phase 2+ : le vendeur ne paie alors que les frais Mefali de 25–100 FCFA/livraison), transporteur tiers (compagnie de car)}.

---

## 12. Modèle économique

### 12.1 Phases de monétisation

| Période | Client | Vendeur | Coursier | Mefali |
|---------|--------|---------|----------|--------|
| **Lancement (M0 → M1/M2)** | **Livraison gratuite** (financée par Mefali), zéro frais | 0 % de commission | **Rémunération fixe** (jour ou mois) — promo opérée hors produit | 0 revenu ; burn de lancement assumé |
| **M2/M3 → M3** | Frais de livraison 100–500 FCFA, zéro frais de service | 0 % de commission | **100 %** des frais + grille d'effort | 0 revenu |
| **M4+** | Inchangé | **Commission dégressive par tranches marginales** de CA mensuel via Mefali (taux et seuils éditables par zone) — *indicatif à trancher* : franchise 0 % ≤ 50 000 ; 10 % de 50 001 à 250 000 ; 5 % de 250 001 à 1 000 000 ; 1 % au-delà. Barème marginal (type impôt) : pas d'effet de seuil ; plus le CA est élevé, plus le taux moyen baisse — fidélise les gros vendeurs. | Frais − marge Mefali | **25–100 FCFA / livraison** (éditable) + commissions |

- **Recouvrement de la commission** : retenue prioritaire sur les flux mobile money transitant par Mefali + facture mensuelle du solde (lien de paiement) ; le détail opérationnel est une story de phase 2.
- **Freemium B2B** : app vendeur gratuite ; modules avancés payants en phase 3.
- **Freemium B2C éventuel** : à trancher selon la levée (annexe B).

### 12.2 Lecture honnête

La monétisation MVP couvre les coûts variables. Les coûts fixes — **la promo coursiers du lancement** (ex. 3 coursiers × 75 000 ≈ 225 000 FCFA/mois pendant 1–2 mois), marketing terrain, fonds d'incidents, infra — sont financés par la levée amis & famille jusqu'à ce que volume, multi-villes et B2B premium prennent le relais. Cohérent avec l'objectif : **viabilité d'abord, rentabilité au-delà de 12 mois.** Pilotage : burn mensuel contre plan, runway cible ≥ 12 mois.

---

## 13. Go-to-market — playbook Tiassalé

**Semaines −4 à −1** : agréer **20–30 vendeurs** multi-catégories (12–15 restauration + 8–10 courses), poser les plaques, recruter et former 2–4 coursiers (circuits, scan, cash, faux billets). Arguments vendeurs : 0 commission prolongée, plaque « agréé », option « livraison offerte » comme outil promotionnel, plaque = page publique scannable.

**Semaines −2 à 0 — bêta fermée** : 30–50 testeurs, vraies commandes subventionnées → roder dispatch, scan, cash, cas limites avant l'ouverture.

**Lancement (M1–M2)** : argument massue **« livraison gratuite »** (offre de lancement à durée annoncée) ; ciblage clientèle solvable (administrations, banques, agences) ; créneau déjeuner optimisé en priorité ; radio locale + leaders de quartier ; **parrainage : mécanique à définir** (annexe B).

**Extension (M6+)** : Divo avec le playbook, si seuils verts (§16).

---

## 14. Roadmap

### Phase 1 — Construction (S1–S16, marge de +2 semaines : le panier multi-vendeurs alourdit les tranches T1–T2)

Développement avec Claude Code + Spec-Kit ; contrat OpenAPI comme source de vérité.

| Jalons | Contenu |
|--------|---------|
| S1–S2 | Architecture (crates, trait ServiceWorkflow, schémas), OpenAPI v1, CI/CD, squelettes apps + Nuxt 4, POC dispatch Redis + POC OSRM |
| S3–S6 | Cœur : comptes/OTP, catalogue (prix barrés), **commandes multi-vendeurs (arrêts de collecte)**, dispatch, suivi, itinéraires multi-arrêts |
| S7–S9 | QR + fiche publique, chaîne cash & cas limites, tarification (routage, livraison offerte) + simulateur, admin |
| S10–S12 | App vendeur minimale, ruptures & « me prévenir au retour », substitutions, notation, métriques + Metabase, Shorebird, durcissement hors-ligne |
| S13–S14 | **Bêta fermée** |
| S15–S16 | Correctifs, formation, **lancement Tiassalé** |

### Phase 2 — M2–M6 post-lancement

Fin de la promo (bascule au paiement à la course, **grille d'effort active**) ; activation de la monétisation (M4, commission dégressive + marge) ; **commande aller-retour** → pressing ; **intégrations directes opérateurs de paiement** (Wave d'abord, réduction des frais) ; réaffectation d'un article indisponible vers un autre vendeur agréé du même marché (ajout d'arrêt en cours de course) ; notifications vendeur WhatsApp ; stacking 2 commandes.

### Phase 3 — M6–M12

Divo ; pilote interville (segments, gares, points relais) ; premiers modules B2B payants ; **flotte de livreurs du vendeur** (frais Mefali seuls) ; premiers villages en étude.

### Phase 4+ — Vision (annexe A)

---

## 15. Risques et mitigations

| Risque | Prob. | Impact | Mitigation |
|--------|-------|--------|------------|
| Demande plus lente que prévu | Élevée | Fatal | Livraison gratuite au lancement ; bêta fermée ; ciblage solvable ; revue hebdo des KPI et plan d'ajustement |
| Transition « gratuit → payant » mal vécue | Moyenne | Élevé | Durée de l'offre annoncée dès le jour 1 ; bascule progressive (frais bas au début : 100–200) ; vendeurs « livraison offerte » amortissent |
| Économie coursier non viable après la promo de lancement | Moyenne | Fatal | Concentration déjeuner ; flotte petite ; 100 % des frais au coursier jusqu'à M4 ; grille d'effort |
| Fraude cash (coursier ou client) | Moyenne | Élevé | Preuves in-app, plafonds progressifs, QR/code de livraison, blacklist + prépaiement imposé, fonds d'incidents |
| Vendeurs en rupture chronique | Moyenne | Moyen | Score de fiabilité → déclassement ; « me prévenir au retour » convertit la rupture ; suspension |
| Dépendance Shorebird | Faible | Moyen | Canal store toujours disponible ; config distante |
| Vélocité solo sur Rust | Moyenne | Moyen | Périmètre discipliné, Claude Code, codegen OpenAPI, tranches verticales |
| Service d'itinéraires indisponible | Faible | Moyen | OSRM auto-hébergé + dégradé ×1,4 journalisé |
| Saison des pluies | Certaine | Moyen | Supplément pluie, équipement, délais élargis |
| Concurrent national | Faible (CT) | Élevé | Densité du réseau agréé local ; une ville à fond |
| Sur-périmètre | Élevée | Élevé | Règle §3.2 ; « prêt » ≠ « construit » (§11) |

---

## 16. KPIs, métriques et pilotage

**Instrumentation dès le jour 1** : tous les indicateurs ci-dessous sont calculés automatiquement depuis le module métriques (événements produit + outbox opérations, agrégats quotidiens, exploration Metabase) — aucun KPI ne dépend d'un pointage manuel. Le funnel produit (vue fiche → panier → commande → livraison) est suivi au même titre que l'opérationnel.

Seuils **calibrés Tiassalé** (M4–M5) — ils déclenchent des ajustements, pas un jugement de rentabilité :

| Métrique | Vert | Rouge (plan d'action) |
|----------|------|-----------------------|
| Commandes / jour | > 18 en croissance | < 8 stagnant |
| Croissance mensuelle des commandes | > 20 % | < 5 % |
| Taux de re-commande à 30 jours | > 35 % | < 15 % |
| Conversion vue fiche → commande | > 8 % | < 3 % |
| Délai moyen de livraison | < 40 min | > 60 min |
| Litiges / 100 commandes | < 5 | > 15 |
| Revenu net coursier / jour (après période fixe) | > 3 000 FCFA | < 2 000 FCFA |
| Vendeurs actifs / semaine | > 70 % du réseau | < 40 % |
| Taux de rupture constatée | < 8 % | > 20 % |
| Abonnés « me prévenir » convertis | > 25 % | < 10 % |
| Burn mensuel | ≤ plan | > 120 % du plan |

---

## 17. Prochaines étapes (4 semaines)

1. Études comparatives : cartographie **+ itinéraires** (audit couverture OSM Tiassalé, POC OSRM sur le VPS) et **choix de l'agrégateur de paiement** (critères §10.7).
2. Trancher les **valeurs des tranches de commission** (annexe B) ; ajuster si besoin les seeds de la grille d'effort (§9.3).
3. Grille d'agrément testée sur 20 vendeurs ; relevé paniers et délais.
4. Architecture de référence (trait ServiceWorkflow inclus) + OpenAPI v1 + POC dispatch Redis ; **vérification des dernières versions stables** de toute la stack.
5. Maquettes : 5 écrans client, 5 coursier, 3 vendeur, 4 admin.
6. Administratif : immatriculation, compte de réception des reversements (banque / Wave Business) + inscription auprès de l'agrégateur retenu, ARTCI, CGU/CGV.
7. Recrutement 2 coursiers pilotes ; fixer montant et durée de la promo coursiers (décision opérationnelle) ; démarrer les agréments.

---

## Annexe A — Vision long terme (hors périmètre d'exécution)

Écosystème modulaire : commerce, livraison, restauration, **hôtellerie** (module séparé à workflow réservation), **prestations de services** (plomberie, électricité, dépannage à domicile — prestataires agréés QR, dispatch par capacités), **e-entrepôt / fulfillment** (adossé aux points relais et au modèle de segments) ; ERP B2B par modules ; automatisations inter-modules ; agents IA ; wallet ; marketplace de livreurs ; couverture jusqu'aux **villages** ; expansion régionale multi-devises. Séquence : le B2C construit densité, marque et relation quotidienne ; le B2B se déploie en freemium auprès de prestataires déjà utilisateurs. Les provisions du §11 (cœur de commande sans logistique intrinsèque, prestataire général, dispatch par capacités, extensions par vertical) garantissent que ces évolutions divergentes ne casseront pas l'existant.

## Annexe B — Questions ouvertes et propositions en attente

1. **Tranches de commission dégressive** : valeurs définitives (franchise basse incluse ou non).
2. **Promotion de lancement** (décision opérationnelle, hors produit) : paie coursier journalière ou mensuelle, montant, durée (1 ou 2 mois).
3. **Choix de l'agrégateur de paiement** (CinetPay, PayDunya, Bizao, HUB2… — critères §10.7).
4. **Mécanique de parrainage** : à définir (l'ancienne proposition est retirée).
5. Google Maps, Mapbox ou OSM/flutter_map + OSRM (étude §10.6).
6. Freemium B2C : selon la levée.
7. Colis libre A→B : demande spontanée ? (phase 2)
8. Flotte de livreurs du vendeur (phase 2+) : critères d'éligibilité, contrôle qualité des livreurs non-Mefali.
9. Part dîner vs déjeuner (observée en bêta) → horaires coursiers.
10. Seeds de la **grille d'effort** (§9.3) : à confirmer avec les données journalisées pendant la promo, avant la bascule au payant.
