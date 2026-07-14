# Feature Specification: Arbre de zones et configuration héritée

**Feature Branch**: `002-zones-config-heritee`

**Created**: 2026-07-13

**Status**: Draft

**Input**: User description: "Module ZON — Zones & configuration (docs/user-stories-v2.md) + cadrage v5 §4, §9.4, §11.1. Fonctionnalité : arbre de zones et configuration héritée. Périmètre : ZON-01, ZON-02, ZON-03, ZON-04 — critères d'acceptation tels quels, seeds Tiassalé inclus (catégories avec seuils d'activation et drapeau mixable — courses : oui, restauration : non ; types de transport à pied/vélo/moto actifs ; devise XOF ; drapeaux de zone : livraison offerte Mefali = ON, gratuité commissions = ON, pluie = OFF). Hors périmètre : ZON-05 (i18n en, P1) ; niveaux village/quartier = provision de modèle uniquement (le type de zone existe, aucun écran). Personas : Admin. Points d'attention : la résolution de configuration (héritage parent → enfant avec surcharge) est utilisée par TOUS les modules suivants — expose-la comme un trait propre du crate zones, testé exhaustivement, y compris les cas de surcharge partielle."

## Clarifications

### Session 2026-07-13

- Q: Le point de configuration produit distante (`/config?zone=`, ZON-04) est-il public ou authentifié (tension avec la constitution, principe VIII « chaque endpoint est protégé par rôle ») ? → A: Public en lecture seule, limité au sous-ensemble destiné aux applications (drapeaux, textes, paramètres client) — aucune donnée sensible ; exception documentée au principe VIII, rate-limitée comme le reste.
- Q: Quelle surface d'écriture d'administration construire dès ce cycle, les écrans ADM-05/06 n'arrivant qu'en T3 ? → A: Minimal ZON — la seule écriture exposée en API est le forçage de catégorie par ville (exigé par ZON-02), protégée par le rôle admin et journalisée (qui, quand, avant/après — exigence ADM-05) ; zones, paramètres et drapeaux restent posés par les seeds jusqu'au cycle ADM (T3).

## User Scenarios & Testing *(mandatory)*

Persona unique de ce cycle : **Admin (toi)** — fondateur et développeur solo. Les « bénéficiaires » indirects sont tous les modules suivants de la tranche T1 (comptes, vendeurs, tarification, commandes, dispatch…), qui consommeront la résolution de configuration, et les applications mobiles, qui consommeront la configuration produit distante.

Priorités produit : les quatre stories ZON-01 → ZON-04 sont toutes **P0** dans `docs/user-stories-v2.md` (tranche T1). Les priorités P1→P4 ci-dessous sont l'ordre de livraison interne au cycle (dépendances), pas une hiérarchie produit. ZON-05 (P1 produit) est hors périmètre.

Aucune interface utilisateur n'est construite dans ce cycle : les écrans d'administration des zones arrivent au cycle ADM (tranche T3). Les capacités Admin ci-dessous s'exercent via les seeds, à une exception près : le forçage de catégorie par ville (ZON-02) est exposé en API, protégé par le rôle admin et journalisé.

### User Story 1 - Arbre de zones et résolution de configuration héritée (ZON-01, Priority: P1 — produit : P0)

L'Admin dispose d'un référentiel de zones organisé en arbre à profondeur variable : chaque zone a au plus un parent et un type parmi {pays, région, ville, commune, village, quartier}. Chaque zone peut porter une configuration locale **partielle** (devise, drapeaux, paramètres, activations) ; la configuration **effective** d'une zone se calcule par héritage de la racine vers la feuille, chaque paramètre prenant la valeur de l'ancêtre le plus proche qui le définit, la zone elle-même en tête. Cette résolution est exposée comme une interface interne réutilisable — c'est elle que TOUS les modules suivants utiliseront pour lire leurs paramètres de zone ; elle est testée exhaustivement, y compris les surcharges partielles. Le seed crée Côte d'Ivoire (pays) > Tiassalé (ville) avec la devise XOF (0 décimale, montants entiers en unités mineures).

**Why this priority**: C'est la colonne vertébrale du module et de tout le produit : « tout paramètre métier paramétrable vit dans la configuration de zone » (constitution, principe I). Rien d'autre dans ce cycle — catégories, transports, configuration distante — ne fonctionne sans la résolution.

**Independent Test**: Exécuter les seeds, construire un arbre de test à au moins 3 niveaux avec surcharges partielles à chaque niveau, résoudre la configuration effective de chaque zone et vérifier paramètre par paramètre la valeur attendue.

**Acceptance Scenarios**:

1. **Given** les seeds exécutés, **When** l'Admin consulte l'arbre des zones, **Then** Côte d'Ivoire (type pays, sans parent) existe avec Tiassalé (type ville) pour enfant, et la configuration effective de Tiassalé porte la devise XOF à 0 décimale, héritée du pays.
2. **Given** un paramètre défini au niveau pays et surchargé au niveau ville, **When** la configuration effective de la ville est résolue, **Then** la valeur de la ville l'emporte pour ce paramètre et tous les paramètres non surchargés conservent la valeur du pays.
3. **Given** une chaîne d'au moins 3 niveaux (ex. pays > ville > quartier) avec des surcharges partielles différentes à chaque niveau, **When** la configuration effective de la feuille est résolue, **Then** chaque paramètre vaut la valeur de l'ancêtre le plus proche qui le définit — y compris quand un niveau intermédiaire ne définit rien.
4. **Given** un paramètre défini nulle part dans la chaîne, **When** la configuration effective est résolue, **Then** le paramètre est restitué comme explicitement absent — jamais une valeur inventée silencieusement.
5. **Given** l'arbre seedé, **When** l'Admin crée une zone de type village sous une commune (ou directement sous Tiassalé) par une simple opération de données, **Then** la zone apparaît dans l'arbre, sa configuration effective se résout immédiatement, et aucune modification structurelle n'a été nécessaire — et aucun écran dédié n'existe (provision).
6. **Given** une zone existante, **When** on tente de la rattacher à l'une de ses propres descendantes (cycle), **Then** l'opération est refusée avec une erreur explicite.
7. **Given** une entité métier quelconque d'un module ultérieur, **When** elle doit être rattachée géographiquement, **Then** elle peut référencer une zone par un identifiant stable (capacité vérifiée dans ce cycle par les rattachements internes du module : catégories, types de transport).

---

### User Story 2 - Catégories de services activables par configuration (ZON-02, Priority: P2 — produit : P0)

L'Admin gère les catégories de services comme des enregistrements de configuration, pas comme du code : chaque catégorie porte ses champs de fiche, sa politique photo à la récupération (obligatoire / facultative / désactivée), son workflow vendeur, son véhicule minimal, son **seuil d'activation par ville** et son **drapeau « mixable au panier »**. Quand le nombre de vendeurs agréés d'une catégorie dans une ville atteint le seuil, la catégorie s'active automatiquement dans cette ville ; un forçage manuel de l'Admin (forcé actif / forcé inactif / automatique) est toujours prioritaire sur la règle. Le seed Tiassalé crée : restauration (seuil 8, mixable non), boutique/supérette (3), marché (3), pharmacie (1), gaz (2), quincaillerie (2) — les cinq catégories « courses » mixables oui. Pas d'hôtellerie (vertical hors MVP, module séparé en phase 2+).

**Why this priority**: L'activation par configuration est ce qui permet d'ouvrir une catégorie dans une ville sans écrire de code (cadrage §4) ; le drapeau mixable est consommé dès CMD-01 (panier). Dépend de la story 1 (les catégories s'activent **par ville**, donc par zone).

**Independent Test**: Exécuter les seeds, vérifier les 6 catégories et leurs attributs ; simuler l'agrément de vendeurs jusqu'au seuil et constater l'activation automatique ; forcer manuellement dans les deux sens et constater la priorité du forçage.

**Acceptance Scenarios**:

1. **Given** les seeds exécutés, **When** l'Admin consulte les catégories de Tiassalé, **Then** les six catégories existent avec leurs seuils (restauration 8, boutique/supérette 3, marché 3, pharmacie 1, gaz 2, quincaillerie 2), leur drapeau mixable (restauration : non ; boutique/supérette, marché, pharmacie, gaz, quincaillerie : oui), leur politique photo, leur workflow vendeur et leur véhicule minimal.
2. **Given** une catégorie comptant seuil − 1 vendeurs agréés dans une ville, **When** un vendeur supplémentaire de cette catégorie y est agréé, **Then** la catégorie s'active automatiquement dans cette ville sans action manuelle, et ce changement d'état est journalisé comme événement métier.
3. **Given** une catégorie active dans une ville, **When** l'Admin la force à « inactif », **Then** elle est inactive même si le seuil est atteint — et réciproquement, un forçage « actif » l'active même sous le seuil.
4. **Given** une catégorie forcée manuellement, **When** l'Admin repasse le forçage à « automatique », **Then** l'état effectif redevient celui dicté par le seuil.
5. **Given** une catégorie activée automatiquement, **When** le nombre de vendeurs agréés repasse sous le seuil (suspension d'un vendeur), **Then** la catégorie reste active — aucune désactivation automatique ; seul l'Admin décide d'une fermeture.

---

### User Story 3 - Référentiel des types de transport (ZON-03, Priority: P3 — produit : P0)

L'Admin dispose d'un référentiel extensible des types de transport — à pied, vélo, moto, tricycle taxi, tricycle cargo, voiture, camionnette, camion — dont l'activation se décide zone par zone via la configuration héritée. Le seed active à pied, vélo et moto à Tiassalé.

**Why this priority**: Le référentiel est consommé par le dossier coursier (CPT-04, véhicules déclarés), le véhicule minimal des catégories (story 2) et le dispatch par capacités (constitution, principe II). Dépend de la story 1 (activation par zone = configuration héritée).

**Independent Test**: Exécuter les seeds, vérifier les 8 types au référentiel et les 3 types actifs résolus pour Tiassalé ; activer un type sur une zone parente et vérifier l'héritage sur ses descendantes.

**Acceptance Scenarios**:

1. **Given** les seeds exécutés, **When** l'Admin consulte le référentiel des types de transport, **Then** les huit types (à pied, vélo, moto, tricycle taxi, tricycle cargo, voiture, camionnette, camion) existent.
2. **Given** les seeds exécutés, **When** la configuration effective de Tiassalé est résolue, **Then** les types actifs sont exactement à pied, vélo et moto.
3. **Given** un type de transport activé sur une zone, **When** la configuration effective d'une zone descendante est résolue sans surcharge locale, **Then** l'activation est héritée ; une surcharge locale de la descendante l'emporte.
4. **Given** le référentiel en place, **When** un nouveau type de transport doit être ajouté (ex. tricycle cargo activé dans une autre ville en phase 2+), **Then** c'est une opération de données uniquement — aucune modification structurelle.

---

### User Story 4 - Configuration produit distante (ZON-04, Priority: P4 — produit : P0)

Les applications (client, pro, web) récupèrent la configuration produit d'une zone via un point d'accès unique (`/config?zone=`) : feature flags — dont « livraison offerte Mefali » du lancement, « gratuité commissions » et « pluie » —, textes et paramètres, le tout résolu par héritage et **versionné**. Les applications rafraîchissent cette configuration au démarrage puis au moins toutes les heures, et conservent un cache local pour fonctionner avec la dernière configuration connue en absence de réseau. Le seed pose les drapeaux de Tiassalé : livraison offerte Mefali = ON, gratuité commissions = ON, pluie = OFF.

**Why this priority**: C'est la matérialisation « produit » des stories 1 à 3 : sans elle, les apps ne voient ni drapeaux ni paramètres. Elle dépend de toute la mécanique de résolution.

**Independent Test**: Backend démarré avec les seeds : demander la configuration de Tiassalé et vérifier drapeaux, paramètres et version ; modifier un paramètre sur une zone parente et vérifier que la version change et que la nouvelle valeur est servie ; couper le réseau d'une app et vérifier qu'elle démarre sur son cache.

**Acceptance Scenarios**:

1. **Given** le backend démarré avec les seeds, **When** une application demande la configuration de Tiassalé, **Then** elle reçoit la configuration effective — drapeaux livraison offerte Mefali = ON, gratuité commissions = ON, pluie = OFF, devise XOF, paramètres et textes — accompagnée d'une version.
2. **Given** une configuration déjà récupérée, **When** un paramètre change sur Tiassalé **ou sur un de ses ancêtres**, **Then** la prochaine demande restitue la nouvelle configuration effective avec une version différente.
3. **Given** une application démarrée, **When** elle s'exécute, **Then** elle récupère la configuration au démarrage puis la rafraîchit au moins toutes les heures.
4. **Given** une application sans réseau au démarrage, **When** elle s'ouvre, **Then** elle fonctionne avec la dernière configuration mise en cache localement et se resynchronise au retour du réseau.
5. **Given** une demande de configuration pour une zone inexistante, **When** elle est traitée, **Then** une erreur explicite est retournée — jamais une configuration vide silencieuse.

---

### Edge Cases

- **Paramètre défini nulle part** (ni sur la zone ni sur aucun ancêtre) : la résolution distingue « explicitement absent » de « défini à une valeur vide » ; les consommateurs reçoivent une absence explicite, jamais un défaut inventé.
- **Surcharge partielle imbriquée** : un niveau intermédiaire qui ne définit rien est transparent ; un niveau qui ne définit qu'une partie des paramètres ne masque pas les autres.
- **Re-parentage d'une zone** : déplacer une zone sous un autre parent recalcule la configuration effective de toute sa descendance à la consultation suivante et change les versions concernées.
- **Cycle** : rattacher une zone à elle-même ou à une descendante est refusé.
- **Suppression d'une zone** : refusée si la zone a des enfants ou est référencée par une entité (catégorie activée, type de transport surchargé, entité métier d'un module ultérieur).
- **Devise irrésolvable** : toute zone doit résoudre une devise via l'héritage ; une chaîne sans devise est une erreur de configuration détectée, le seed garantit XOF à la racine.
- **Repli sous le seuil d'activation** : la perte d'un vendeur agréé ne désactive jamais automatiquement une catégorie active.
- **Forçage vs automatique** : le forçage manuel (actif/inactif) l'emporte toujours ; le retour à « automatique » réapplique la règle du seuil à l'état courant.
- **Application hors ligne prolongée** (> 1 h) : elle continue sur son cache local et se resynchronise à la première occasion.
- **Zone village/quartier** : créable et résolvable au niveau données (provision) ; aucun écran, aucune logique dédiée.

## Requirements *(mandatory)*

### Functional Requirements

#### Arbre de zones (ZON-01)

- **FR-001**: Le système DOIT représenter les zones en arbre : chaque zone a au plus un parent, un nom et un type parmi {pays, région, ville, commune, village, quartier} ; la profondeur n'est PAS figée — un village peut être ajouté sous une commune en phase 2+ par simple création de données, sans modification structurelle.
- **FR-002**: Le système DOIT refuser tout rattachement créant un cycle (une zone ne peut être sa propre ancêtre).
- **FR-003**: Toute entité métier DOIT pouvoir référencer une zone par un identifiant stable ; dans ce cycle, les catégories et les types de transport exercent cette capacité.
- **FR-004**: Les types village et quartier sont une PROVISION : présents dans le modèle et résolvables, sans aucun écran ni logique dédiée (constitution, principe IX).

#### Configuration héritée (ZON-01)

- **FR-005**: Chaque zone PEUT porter une configuration locale partielle : devise, drapeaux, paramètres, activations de catégories et de types de transport — tout paramètre métier « paramétrable » du produit vit dans cette configuration, jamais en dur.
- **FR-006**: Le système DOIT résoudre la configuration effective d'une zone par héritage : pour chaque paramètre, la valeur retenue est celle de l'ancêtre le plus proche qui le définit, la zone elle-même en tête ; les niveaux ne définissant pas un paramètre sont transparents pour ce paramètre.
- **FR-007**: La résolution DOIT être exposée comme une interface interne réutilisable, unique pour tout le produit : les modules ultérieurs (tarification, dispatch, commandes…) la consomment telle quelle, sans dupliquer la logique d'héritage.
- **FR-008**: La résolution DOIT être couverte par des tests exhaustifs : sans surcharge, surcharge totale, surcharge partielle à un ou plusieurs niveaux, niveaux intermédiaires vides, paramètre absent de toute la chaîne, arbre à 3 niveaux et plus.
- **FR-009**: La résolution DOIT distinguer « paramètre explicitement absent » de « paramètre défini » (y compris défini à une valeur vide ou fausse) et restituer l'absence explicitement.
- **FR-010**: La devise est portée par la configuration de zone : code ISO 4217 + nombre de décimales des unités mineures ; tous les montants sont des entiers en unités mineures (XOF : 0 décimale) ; toute zone DOIT résoudre une devise via l'héritage.
- **FR-011**: Le mécanisme de configuration DOIT accueillir sans modification structurelle les paramètres du « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md` — leurs valeurs seront posées par les cycles propriétaires respectifs.

#### Catégories de services (ZON-02)

- **FR-012**: Une catégorie de services DOIT être un enregistrement de configuration portant : champs de fiche, politique photo à la récupération (obligatoire / facultative / désactivée), workflow vendeur, véhicule minimal (référence au référentiel des types de transport), seuil d'activation par ville et drapeau « mixable au panier ».
- **FR-013**: Quand le nombre de vendeurs agréés d'une catégorie dans une ville atteint son seuil d'activation, la catégorie DOIT s'activer automatiquement dans cette ville.
- **FR-014**: L'Admin DOIT pouvoir forcer l'état d'une catégorie par ville — forcé actif / forcé inactif / automatique — et le forçage manuel l'emporte toujours sur la règle du seuil. C'est la SEULE écriture d'administration exposée en API dans ce cycle : protégée par le rôle admin et journalisée (qui, quand, avant/après — exigence ADM-05) ; les autres écritures (zones, paramètres, drapeaux) passent par les seeds jusqu'au cycle ADM (T3).
- **FR-015**: Le repli du nombre de vendeurs agréés sous le seuil NE DOIT PAS désactiver automatiquement une catégorie active.
- **FR-016**: Tout changement d'état d'activation d'une catégorie (automatique ou manuel) DOIT être journalisé comme événement métier dans la même transaction que le changement (constitution, principe VI).

#### Types de transport (ZON-03)

- **FR-017**: Le système DOIT fournir un référentiel extensible des types de transport — à pied, vélo, moto, tricycle taxi, tricycle cargo, voiture, camionnette, camion — dont l'activation par zone participe à la configuration héritée (activation sur un ancêtre héritée, surcharge locale possible).

#### Configuration produit distante (ZON-04)

- **FR-018**: Le système DOIT exposer aux applications la configuration effective d'une zone via un point d'accès unique (`/config?zone=`) : feature flags (dont « livraison offerte Mefali », « gratuité commissions », « pluie »), textes (clés i18n fr) et paramètres, accompagnés d'une version. Ce point d'accès est PUBLIC en lecture seule — nécessaire avant toute connexion — et ne sert que le sous-ensemble destiné aux applications (drapeaux, textes, paramètres client), jamais de donnée sensible ; il est rate-limité. Exception documentée au principe VIII de la constitution (« chaque endpoint est protégé par rôle »).
- **FR-019**: La version DOIT changer dès que la configuration effective de la zone change — y compris quand le changement provient d'un ancêtre.
- **FR-020**: Les applications DOIVENT récupérer la configuration au démarrage, la rafraîchir au moins toutes les heures, et conserver un cache local leur permettant de fonctionner hors ligne avec la dernière configuration connue.
- **FR-021**: Une demande de configuration pour une zone inconnue DOIT produire une erreur explicite.

#### Seeds Tiassalé (rejouables — constitution, principe I)

- **FR-022**: Le seed DOIT créer Côte d'Ivoire (pays) > Tiassalé (ville) avec la devise XOF (0 décimale) définie de sorte que Tiassalé la résolve par héritage.
- **FR-023**: Le seed DOIT créer les six catégories avec leurs seuils d'activation et drapeaux mixables : restauration (8, non), boutique/supérette (3, oui), marché (3, oui), pharmacie (1, oui), gaz (2, oui), quincaillerie (2, oui). Pas d'hôtellerie (vertical hors MVP). L'état d'activation initial découle de la règle automatique appliquée aux vendeurs présents en base.
- **FR-024**: Le seed DOIT créer les huit types de transport au référentiel et activer à pied, vélo et moto pour Tiassalé.
- **FR-025**: Le seed DOIT poser les drapeaux de zone de Tiassalé : livraison offerte Mefali = ON, gratuité commissions = ON, pluie = OFF.
- **FR-026**: Les seeds DOIVENT être rejouables (une ré-exécution ne duplique rien et converge vers le même état).

### Key Entities

- **Zone** : nœud de l'arbre géographique — parent (0..1), type (pays, région, ville, commune, village, quartier), nom, identifiant stable référencé par toute entité métier.
- **Configuration de zone (locale)** : ensemble PARTIEL de valeurs portées par une zone — devise, drapeaux, paramètres, activations ; seule la partie surchargée localement est stockée.
- **Configuration effective** : résultat calculé de l'héritage racine → zone ; c'est elle que consomment les modules et les applications ; porte une version.
- **Devise** : code ISO 4217 + nombre de décimales des unités mineures (XOF : 0) ; portée par la configuration, résolue par héritage.
- **Catégorie de services** : enregistrement de configuration — champs de fiche, politique photo, workflow vendeur, véhicule minimal, seuil d'activation par ville, drapeau mixable.
- **Activation de catégorie par ville** : état effectif (active/inactive) + origine (automatique / forcé actif / forcé inactif) pour un couple catégorie × ville ; chaque transition émet un événement métier.
- **Type de transport** : entrée du référentiel extensible (8 au seed) ; son activation par zone fait partie de la configuration héritée.
- **Drapeau de zone (feature flag)** : booléen de configuration (livraison offerte Mefali, gratuité commissions, pluie…) résolu par héritage et servi aux applications.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Sur un arbre de test d'au moins 3 niveaux couvrant tous les cas de surcharge (aucune, partielle, totale, niveau intermédiaire vide, paramètre absent partout), 100 % des paramètres résolus valent la valeur de l'ancêtre le plus proche qui les définit — ou une absence explicite.
- **SC-002**: L'ajout d'un village sous une commune (ou sous Tiassalé) s'effectue par simple création de données : la zone se résout immédiatement, aucune modification structurelle ni écran n'a été nécessaire.
- **SC-003**: Après exécution des seeds, une seule consultation de la configuration de Tiassalé restitue exactement : devise XOF (0 décimale), six catégories avec seuils 8/3/3/1/2/2 et mixable (non/oui/oui/oui/oui/oui), trois types de transport actifs (à pied, vélo, moto), drapeaux livraison offerte Mefali = ON, gratuité commissions = ON, pluie = OFF.
- **SC-004**: Un changement de paramètre sur une zone parente est visible dans la configuration effective de 100 % de ses descendantes dès la consultation suivante, avec une version différente ; les applications le voient au plus tard 1 heure après ou à leur prochain démarrage.
- **SC-005**: Le franchissement du seuil d'activation active la catégorie sans aucune action manuelle, et le forçage manuel l'emporte sur la règle automatique dans 100 % des cas testés (forcé actif sous le seuil, forcé inactif au-dessus, retour à automatique).
- **SC-006**: Un paramètre de zone entièrement nouveau (ex. « rayon de dispatch », posé par un cycle ultérieur) peut être défini sur une zone et résolu par héritage sans aucune modification du mécanisme — vérifié de bout en bout avec un paramètre de test.
- **SC-007**: Une application sans réseau au démarrage fonctionne avec sa dernière configuration connue, sans erreur visible, et se resynchronise au retour du réseau.
- **SC-008**: Les seeds ré-exécutés deux fois de suite produisent un état strictement identique (aucun doublon).

## Assumptions

- **Aucune UI dans ce cycle** : les écrans d'administration des zones et paramètres (ADM-05) arrivent en tranche T3 ; ici, la seule écriture Admin exposée en API est le forçage de catégorie par ville — les autres capacités (créer une zone, poser un drapeau ou un paramètre) s'exercent via les seeds. La partie « applications » de ZON-04 se limite à la mécanique récupération / cache / rafraîchissement, sans écran nouveau.
- **Pas de désactivation automatique** : le seuil ne joue qu'à la hausse ; une catégorie active le reste si le nombre de vendeurs replie sous le seuil — désactiver automatiquement une catégorie portant des vendeurs actifs serait destructeur. Seul le forçage Admin ferme une catégorie.
- **Forçage à trois états** : automatique / forcé actif / forcé inactif — l'Admin peut toujours revenir au mode automatique.
- **Profondeur variable = pas d'ordre de types imposé** : l'arbre n'impose pas la séquence pays > région > ville > … ; des niveaux peuvent être sautés (Côte d'Ivoire > Tiassalé sans région). Seule l'absence de cycle est garantie ; la plausibilité géographique relève de l'Admin.
- **« Courses » désigne** boutique/supérette, marché, pharmacie, gaz et quincaillerie (mixables au panier : oui) ; la restauration n'est pas mixable (référence CMD-01, « Récapitulatif des paramètres de zone »).
- **Le comptage des vendeurs agréés** par catégorie et par ville est alimenté par les modules comptes/prestataires (CPT/VND, même tranche T1) : ce cycle définit la règle d'activation et le point d'entrée qui la déclenche ; dans ce cycle elle est exercée par les tests et les seeds.
- **Interface de résolution** : conformément à la constitution (principe II — un crate par domaine, interfaces par traits), la résolution est exposée comme un trait propre du crate zones ; la signature exacte relève du plan, pas de la spec.
- **Version de configuration** : identifiant monotone par zone permettant aux applications de détecter un changement ; son mécanisme précis (compteur, horodatage, empreinte) relève du plan.
- **Textes servis par la configuration distante** : exclusivement des clés i18n fr (constitution, principe VII) ; la langue anglaise (ZON-05) est hors périmètre, la structure des clés reste prête pour elle.
- **Les critères produit sont repris tels quels** : les libellés opérationnels de ZON-01 → ZON-04 (dont le point d'accès `/config?zone=`) sont cités verbatim depuis `docs/user-stories-v2.md` à la demande du cadrage — la forme exacte de l'API relève du plan et du contrat OpenAPI (TRX-01).
