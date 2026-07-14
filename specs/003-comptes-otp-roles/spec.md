# Feature Specification: Comptes, authentification OTP et rôles

**Feature Branch**: `003-comptes-otp-roles`

**Created**: 2026-07-14

**Status**: Draft

**Input**: User description: "Module CPT — Comptes & identité (docs/user-stories-v2.md) + cadrage v5 §7.1 et §8.2. Fonctionnalité : comptes, authentification OTP et rôles. Périmètre : CPT-01, CPT-02, CPT-03, CPT-04, CPT-05 — critères tels quels. Numéros E.164 (+225 par défaut selon zone) ; OTP 6 chiffres, 5 min, 3 essais, 3 SMS/h/numéro (compteur Redis) ; JWT court + refresh révocable, multi-appareils ; rôles cumulables {client, coursier, vendeur, admin} sur un compte, coursier et vendeur validés par l'admin, Mefali Pro bascule d'interface selon rôle ; dossier coursier (pièce → stockage objet, véhicules déclarés depuis le référentiel ZON-03, référent local) ; adresses enregistrées après livraison réussie, note vocale de repère incluse. Hors périmètre : CPT-06 (drapeaux prépaiement_imposé/bloqué, P1) — colonnes prévues, pas de logique. Personas : Awa, Yao, Kofi, Admin. Points d'attention : consentement ARTCI coché à l'inscription ; les messages d'erreur OTP ne révèlent jamais si un numéro existe."

## Clarifications

### Session 2026-07-14

- Q: Le dossier coursier (CPT-04) est-il soumis par le coursier dans Mefali Pro ou saisi par l'Admin au recrutement terrain (le cadrage §7.1 ne précise pas le canal) ? → A: Soumission in-app — Yao photographie sa pièce et déclare ses véhicules dans Mefali Pro ; l'Admin valide ensuite. (Le rôle vendeur, lui, n'a pas de demande in-app : le cadrage §5.1 décrit un agrément entièrement piloté par l'Admin — décision sourcée docs, pas une question.)
- Q: Rétention de la note vocale de repère d'une adresse enregistrée (constitution, principe VIII : « rétention limitée », sans valeur documentée) ? → A: Liée à l'usage — conservée tant que l'adresse sert, purge automatique après 12 mois sans utilisation de l'adresse (paramètre de zone, éditable).
- Q: Durée de vie de la session (droit de renouvellement) avant de redemander un OTP ? → A: Illimitée — la session ne s'éteint que par révocation (déconnexion locale ou à distance) ; la sécurité repose sur l'accès court et la déconnexion à distance ; le principe VIII (« refresh révocable ») reste satisfait, aucune durée n'y est imposée.
- Q: Contenu du « profil minimal » à l'inscription (CPT-01) ? → A: Numéro seul — aucune donnée de profil, jamais au MVP : le compte se réduit au numéro vérifié + consentement ARTCI ; les autres rôles ne voient qu'un numéro masqué, l'identification à la remise passant par le QR/code de livraison (cadrage §7.4).

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Awa (cliente)** — employée d'agence à Tiassalé, Android milieu de gamme, commande au déjeuner ; **Yao (coursier)** — moto personnelle, réseau intermittent ; **Kofi (vendeur équipé)** — boutique, smartphone, installera Mefali Pro ; **Admin (toi)** — fondateur, seul au lancement.

Priorités produit : les cinq stories CPT-01 → CPT-05 sont toutes **P0** dans `docs/user-stories-v2.md` (CPT-01→04 en tranche T1). Les priorités P1→P5 ci-dessous sont l'ordre de livraison interne au cycle (dépendances), pas une hiérarchie produit. CPT-06 (P1 produit) est hors périmètre — seules ses colonnes existent (provision).

Surface utilisateur de ce cycle : les parcours d'inscription/connexion vivent dans les applications mobiles (Mefali côté client, Mefali Pro côté coursier/vendeur). Côté Admin, comme au cycle 002, aucun écran n'est construit avant le cycle ADM (tranche T3) : les actions d'administration (valider/refuser/suspendre un rôle ou un dossier coursier) sont exposées en API, protégées par le rôle admin et journalisées (qui, quand, avant/après).

### User Story 1 - Inscription et connexion par téléphone + OTP (CPT-01, Priority: P1 — produit : P0)

Awa installe l'application et saisit son numéro de mobile. Le numéro est normalisé au format international E.164 — l'indicatif par défaut (+225) vient de la configuration de zone. Elle reçoit par SMS un code à usage unique de 6 chiffres, valable 5 minutes, avec 3 essais de saisie ; au plus 3 SMS par heure peuvent être envoyés au même numéro. À la première vérification réussie d'un numéro inconnu, le compte est créé — réduit au numéro vérifié, sans aucune donnée de profil à saisir — après consentement ARTCI obligatoire, horodaté. Si le numéro est déjà inscrit, la même vérification ouvre simplement une session : le flux inscription/connexion est unique et aucune réponse du parcours — succès, erreur, expiration — ne révèle si un numéro possède déjà un compte.

**Why this priority**: C'est la porte d'entrée de tout le produit — le numéro de téléphone vérifié est l'identité Mefali (cadrage §8.2 : « téléphone obligatoire vérifié par OTP SMS »). Rien d'autre dans ce cycle ni dans les suivants ne fonctionne sans compte.

**Independent Test**: Sur un environnement vierge, dérouler l'inscription complète d'un numéro inconnu (demande de code → SMS → saisie → consentement → accueil connecté), puis une connexion sur ce même numéro, et vérifier chaque garde-fou (expiration, essais, plafond SMS, neutralité des messages) sans aucun autre module.

**Acceptance Scenarios**:

1. **Given** un numéro ivoirien saisi sans indicatif dans la zone Tiassalé, **When** Awa demande un code, **Then** le numéro est normalisé en E.164 avec l'indicatif par défaut de la zone (+225) et un code à 6 chiffres lui est envoyé par SMS.
2. **Given** un code envoyé il y a moins de 5 minutes, **When** Awa saisit le bon code pour un numéro inconnu, **Then** son compte est créé après le seul consentement ARTCI coché — aucune autre saisie — et sans consentement, l'inscription ne peut pas aboutir.
3. **Given** un numéro déjà inscrit, **When** son propriétaire refait le même parcours (numéro → code → saisie correcte), **Then** une session s'ouvre sur le compte existant — aucun doublon, et rien dans le parcours n'a indiqué que le numéro était déjà connu.
4. **Given** un code envoyé il y a plus de 5 minutes, **When** il est saisi, **Then** il est refusé avec un message d'expiration neutre (aucune indication sur l'existence d'un compte) et une nouvelle demande de code est possible.
5. **Given** un code dont la saisie a échoué 3 fois, **When** une 4ᵉ saisie est tentée, **Then** le code est invalidé et il faut redemander un code.
6. **Given** 3 SMS déjà envoyés au même numéro dans l'heure, **When** une 4ᵉ demande arrive, **Then** aucun SMS n'est envoyé et la réponse est, dans son contenu et sa forme, indistinguable des autres réponses du parcours.
7. **Given** une nouvelle demande de code pour un numéro, **When** le SMS part, **Then** tout code précédent encore valable pour ce numéro est invalidé.

---

### User Story 2 - Sessions multi-appareils et déconnexion à distance (CPT-02, Priority: P2 — produit : P0)

Une fois vérifiée, Awa obtient une session propre à son appareil : un accès de courte durée, renouvelé silencieusement tant que la session n'est pas révoquée. La session ne s'éteint que par révocation — déconnexion locale ou à distance : aucune expiration d'inactivité ne force un nouvel OTP. Elle peut être connectée sur plusieurs appareils à la fois, consulter la liste de ses appareils connectés et en déconnecter un à distance — utile en cas de perte ou de vol du téléphone. Toute fonction protégée du produit exige une session valide ET le rôle requis : ce contrôle d'accès est le socle que tous les modules suivants réutilisent.

**Why this priority**: Sans session durable, l'OTP servirait à chaque ouverture de l'app ; sans révocation, un téléphone volé garde l'accès au compte (constitution, principe VIII). Dépend de la story 1 (il faut un compte).

**Independent Test**: Connecter le même compte sur deux appareils, vérifier l'indépendance des sessions, révoquer l'une depuis l'autre et constater la perte d'accès ; vérifier qu'une fonction protégée refuse une session expirée, révoquée ou dépourvue du rôle requis.

**Acceptance Scenarios**:

1. **Given** une vérification OTP réussie, **When** la session s'ouvre, **Then** l'appareil reçoit un accès de courte durée et un droit de renouvellement révocable propres à cet appareil.
2. **Given** un accès court expiré et une session non révoquée, **When** l'application renouvelle, **Then** un nouvel accès est délivré sans redemander d'OTP — quelle que soit l'ancienneté de la session (aucune expiration d'inactivité).
3. **Given** deux appareils connectés au même compte, **When** l'utilisateur consulte ses sessions et révoque l'un des deux, **Then** l'appareil révoqué perd l'accès à son prochain renouvellement, et au plus tard à l'expiration de son accès court ; l'autre appareil n'est pas affecté.
4. **Given** une session révoquée ou expirée, **When** l'appareil appelle une fonction protégée, **Then** l'accès est refusé et l'utilisateur repasse par la vérification OTP.
5. **Given** un compte dépourvu d'un rôle, **When** il tente une action réservée à ce rôle, **Then** l'action est refusée — le contrôle est fait à chaque requête, côté serveur.

---

### User Story 3 - Rôles cumulables et bascule Mefali Pro (CPT-03, Priority: P3 — produit : P0)

Un même compte — un même numéro — porte 1 à n rôles parmi {client, coursier, vendeur, admin}. Kofi est client ET vendeur ; Yao est client ET coursier. Les rôles coursier et vendeur ne s'obtiennent qu'après validation de l'Admin, par deux canaux distincts : le rôle coursier se demande depuis Mefali Pro (dossier, story 4) et reste « en attente » sans aucun privilège jusqu'à la décision ; le rôle vendeur est attribué par l'Admin lors de l'agrément du prestataire (cadrage §5.1, VND-01) — l'agrément vaut validation, il n'y a pas de demande vendeur in-app au MVP. Mefali Pro n'accepte que les comptes ayant au moins un rôle professionnel validé et présente l'interface du rôle actif ; un compte cumulant coursier et vendeur bascule de l'une à l'autre sans se reconnecter. L'Admin peut suspendre ou retirer un rôle, avec prise d'effet immédiate côté serveur.

**Why this priority**: La spécialisation des accès conditionne tout le reste de la tranche T1 — le dossier coursier (story 4), l'agrément vendeur (VND-01), les endpoints protégés par rôle. Dépend des stories 1 et 2.

**Independent Test**: Créer un compte, y attacher plusieurs rôles, vérifier qu'une demande coursier/vendeur reste sans privilège jusqu'à la validation admin, que Mefali Pro refuse un compte sans rôle pro validé, et qu'un compte bi-rôle bascule d'interface sans reconnexion.

**Acceptance Scenarios**:

1. **Given** un compte existant, **When** on lui attribue plusieurs rôles parmi {client, coursier, vendeur, admin}, **Then** tous coexistent sur le même compte et le même numéro.
2. **Given** une demande de rôle coursier soumise depuis Mefali Pro, **When** elle est enregistrée, **Then** le rôle est « en attente » : aucun accès professionnel n'est ouvert tant que l'Admin n'a pas validé — et le rôle vendeur, lui, naît directement « validé » quand l'Admin l'attribue à l'agrément.
3. **Given** une demande en attente, **When** l'Admin valide ou refuse, **Then** l'état du rôle change, la décision est journalisée (qui, quand, motif) et un événement métier est émis dans la même transaction.
4. **Given** Kofi vendeur (validé lors de son agrément) et Yao coursier validé, **When** chacun ouvre Mefali Pro, **Then** chacun voit l'interface de son rôle ; un compte cumulant les deux rôles validés bascule de l'une à l'autre sans se reconnecter.
5. **Given** un compte sans rôle professionnel validé, **When** il ouvre Mefali Pro, **Then** l'accès aux fonctions pro est refusé et l'état de sa demande (aucune / en attente / refusée) lui est présenté.
6. **Given** un rôle validé, **When** l'Admin le suspend, **Then** toute action requérant ce rôle est refusée dès la requête suivante — sans attendre l'expiration de la session.
7. **Given** un compte non admin, **When** il tente d'attribuer ou de valider un rôle, **Then** l'opération est refusée — seul un admin existant attribue le rôle admin ou valide les rôles professionnels.

---

### User Story 4 - Dossier coursier (CPT-04, Priority: P4 — produit : P0)

Pour devenir coursier, Yao constitue et soumet lui-même son dossier dans Mefali Pro, depuis son téléphone : sa pièce d'identité (document photographié, stocké de façon sécurisée à accès restreint), au moins un véhicule déclaré parmi les types de transport actifs de sa zone (référentiel ZON-03 — à Tiassalé : à pied, vélo, moto) et un référent local (nom + téléphone), la « caution morale locale » du cadrage §7.1. Le dossier a un statut : en attente, validé ou suspendu. L'Admin consulte le dossier complet et décide. Tant que le dossier n'est pas « validé », la mise en ligne est impossible — c'est la porte que le module coursier (CRS) franchira aux cycles suivants. Les véhicules déclarés définissent les capacités de transport que le dispatch utilisera pour ne proposer que des commandes compatibles (§7.1).

**Why this priority**: Sans dossier validé, pas de flotte — et la fiabilité des livraisons repose sur des coursiers identifiés et cautionnés localement (cadrage §7.1). Dépend de la story 3 (le dossier accompagne la demande du rôle coursier).

**Independent Test**: Soumettre un dossier complet (pièce + véhicule du référentiel de zone + référent), vérifier le refus de mise en ligne en statut « en attente », valider côté admin et constater que la porte s'ouvre, suspendre et constater qu'elle se referme.

**Acceptance Scenarios**:

1. **Given** Yao demande le rôle coursier, **When** il constitue son dossier dans Mefali Pro, **Then** une pièce d'identité, au moins un véhicule choisi parmi les types de transport actifs de sa zone et un référent local (nom + téléphone) sont exigés — dossier incomplet = non soumis.
2. **Given** un dossier soumis, **When** l'Admin le consulte, **Then** il voit toutes les pièces (document d'identité lisible, véhicules, référent) et le statut « en attente ».
3. **Given** un dossier en attente, **When** l'Admin valide, **Then** le statut passe à « validé », la décision est journalisée et un événement métier est émis dans la même transaction ; la mise en ligne devient possible.
4. **Given** un dossier « en attente » ou « suspendu », **When** Yao tente de se mettre en ligne, **Then** le refus est explicite et mentionne l'état du dossier.
5. **Given** un coursier validé, **When** l'Admin le suspend (avec motif), **Then** toute mise en ligne est refusée dès la requête suivante.
6. **Given** la déclaration d'un véhicule, **When** Yao choisit son type, **Then** seuls les types de transport actifs de sa zone (référentiel ZON-03 résolu par héritage) sont proposés.

---

### User Story 5 - Adresses enregistrées avec repère vocal (CPT-05, Priority: P5 — produit : P0)

Après une livraison réussie, l'application propose à Awa d'enregistrer l'adresse de remise sous un libellé — « Maison », « Bureau » ou libre. L'adresse conserve tout ce qui a permis au coursier de la trouver : la position GPS et le repère obligatoire, texte OU note vocale (≤ 30 s, cadrage §8.2 — pensé pour les personnes peu technophiles ou peu lettrées). À la commande suivante, Awa réutilise l'adresse en un geste, sans rien ressaisir — la note vocale de repère est reprise telle quelle et reste jouable par le coursier.

**Why this priority**: La friction d'adressage est le premier obstacle à la re-commande dans des villes sans adresses formelles ; l'adresse enregistrée transforme la deuxième commande en un geste. Dépend de la story 1 (le compte porte les adresses) ; le déclencheur « livraison réussie » vient des modules commandes/coursier (cycles ultérieurs) et est simulé dans les tests de ce cycle.

**Independent Test**: Simuler l'événement « livraison réussie » portant une adresse ponctuelle (GPS + note vocale), accepter la proposition d'enregistrement avec un libellé, puis vérifier la réutilisation en un geste — position et note vocale identiques — ainsi que la gestion (renommer, supprimer).

**Acceptance Scenarios**:

1. **Given** une livraison réussie à une adresse saisie ponctuellement, **When** la livraison se conclut, **Then** l'application propose d'enregistrer cette adresse avec un libellé « Maison », « Bureau » ou libre — la proposition est refusable sans friction.
2. **Given** une adresse enregistrée avec note vocale de repère, **When** Awa la choisit pour une nouvelle commande, **Then** position GPS et repère (texte et/ou note vocale) sont repris en un geste, sans ressaisie, et la note vocale reste jouable par le coursier.
3. **Given** plusieurs adresses enregistrées, **When** Awa passe commande, **Then** elle choisit dans sa liste ou saisit une adresse ponctuelle — l'enregistrement n'est jamais obligatoire.
4. **Given** une adresse enregistrée, **When** Awa la renomme ou la supprime, **Then** le changement ne vaut que pour l'avenir — les livraisons passées n'en sont pas affectées.
5. **Given** une adresse dont la note vocale a été purgée après 12 mois sans utilisation de l'adresse (paramètre de zone — minimisation ARTCI), **When** Awa la réutilise, **Then** l'adresse reste utilisable et un nouveau repère (texte ou vocal) est demandé si elle n'en a plus aucun.

---

### Edge Cases

- **« Inscription » d'un numéro déjà inscrit** : même flux, même apparence — la vérification aboutit à une connexion, et rien en amont de la vérification ne distingue les deux cas (anti-énumération de comptes).
- **Numéro invalide ou étranger** : la normalisation E.164 valide le format ; l'indicatif par défaut de la zone ne s'applique qu'aux saisies locales sans indicatif ; un numéro non normalisable est refusé avec une erreur de format neutre.
- **SMS jamais reçu** : l'utilisateur peut redemander un code dans la limite du plafond (3/h/numéro) ; chaque nouvelle demande invalide le code précédent ; au plafond, la réponse reste neutre et identique.
- **Révocation pendant que l'appareil est hors ligne** : la perte d'accès prend effet au retour du réseau, au premier renouvellement ou appel protégé.
- **Perte ou vol du téléphone** : l'utilisateur se connecte sur un autre appareil (même numéro, OTP) et révoque à distance l'appareil perdu.
- **Rôle suspendu pendant une session active** : le contrôle par rôle étant fait à chaque requête côté serveur, la suspension prend effet immédiatement, sans attendre l'expiration de la session.
- **Cumul coursier + vendeur** : un même compte peut cumuler une demande coursier in-app « en attente » et une attribution vendeur à l'agrément — les deux états sont gérés indépendamment.
- **Type de véhicule désactivé dans la zone après déclaration** : le véhicule déclaré est conservé mais signalé ; il n'est plus proposé aux nouvelles déclarations — l'usage par le dispatch relève de DSP (hors périmètre).
- **Compte porteur d'un drapeau `bloqué` ou `prépaiement_imposé`** : AUCUN comportement au MVP — les colonnes existent (provision CPT-06), aucune logique ne les lit.
- **Évolution du texte de consentement** : chaque consentement conserve la version acceptée et son horodatage ; la politique de re-consentement est hors périmètre MVP.
- **Premier admin** : créé à l'initialisation (seed), hors parcours applicatif — aucun chemin d'auto-attribution du rôle admin n'existe.

## Requirements *(mandatory)*

### Functional Requirements

#### Identité et vérification OTP (CPT-01)

- **FR-001**: Le compte DOIT être identifié par un numéro de mobile unique, stocké au format international E.164 ; la normalisation applique l'indicatif par défaut fourni par la configuration de zone (+225 pour la Côte d'Ivoire) aux saisies locales sans indicatif.
- **FR-002**: La vérification DOIT reposer sur un code à usage unique de 6 chiffres envoyé par SMS : validité 5 minutes, 3 essais de saisie au maximum, et toute nouvelle demande invalide le code précédent du même numéro.
- **FR-003**: Le système NE DOIT PAS envoyer plus de 3 SMS par heure et par numéro ; le compteur est éphémère, partagé entre toutes les instances, et sa perte ne compromet que la fenêtre en cours (constitution, principe II — l'éphémère est reconstructible).
- **FR-004**: AUCUNE réponse du parcours OTP — contenu, forme ou comportement observable — NE DOIT révéler si un numéro possède déjà un compte ; le message d'expiration est neutre ; l'inscription et la connexion partagent un flux unique.
- **FR-005**: La première vérification réussie d'un numéro inconnu DOIT créer le compte, réduit au numéro vérifié et à sa zone de rattachement — AUCUNE donnée de profil n'est demandée (ni nom, ni e-mail), et aucune donnée nominative n'est exposée aux autres rôles, l'identification à la remise reposant sur le QR/code de livraison (cadrage §7.4) ; une vérification réussie d'un numéro connu DOIT ouvrir une session sur le compte existant, sans doublon possible.
- **FR-006**: Le consentement ARTCI (traitement des données personnelles) DOIT être recueilli explicitement à l'inscription — case cochée par l'utilisateur, jamais pré-cochée —, horodaté et conservé avec la version du texte accepté ; sans consentement, aucun compte n'est créé.

#### Sessions (CPT-02)

- **FR-007**: Chaque session DOIT être propre à un appareil : un accès de courte durée renouvelable, et un droit de renouvellement révocable individuellement ; plusieurs appareils peuvent être connectés simultanément au même compte ; la session n'expire JAMAIS d'elle-même — elle ne s'éteint que par révocation (déconnexion locale ou à distance), seul l'accès court a une durée de vie.
- **FR-008**: L'utilisateur DOIT pouvoir consulter ses appareils/sessions actifs et en déconnecter un à distance ; la révocation prend effet au prochain renouvellement de l'appareil visé, et au plus tard à l'expiration de son accès court.
- **FR-009**: Toute fonction protégée DOIT exiger une session valide ET le rôle requis, contrôlés côté serveur à chaque requête ; ce mécanisme est le socle d'autorisation réutilisé par tous les modules (constitution, principe VIII).

#### Rôles multiples (CPT-03)

- **FR-010**: Un compte DOIT pouvoir porter 1 à n rôles cumulables parmi {client, coursier, vendeur, admin} — un seul compte par numéro, quel que soit le nombre de rôles.
- **FR-011**: Les rôles coursier et vendeur DOIVENT être validés par l'Admin, chacun par son canal : le rôle coursier est demandé in-app depuis Mefali Pro — « en attente » → validé ou refusé, suspension possible à tout moment ; le rôle vendeur est attribué par l'Admin lors de l'agrément du prestataire (cadrage §5.1, VND-01), l'agrément valant validation, suspension possible — pas de demande vendeur in-app au MVP. AUCUN privilège professionnel n'est ouvert avant validation.
- **FR-012**: Le rôle admin NE DOIT être attribuable que par un admin existant ; le premier admin est créé à l'initialisation (seed).
- **FR-013**: Mefali Pro DOIT réserver ses fonctions aux comptes ayant au moins un rôle professionnel validé, présenter l'interface du rôle actif et permettre la bascule entre rôles validés sans reconnexion ; un compte sans rôle pro validé y voit l'état de sa demande.
- **FR-014**: Toute transition de validation (rôle ou dossier : demande, validation, refus, suspension) DOIT être journalisée — qui, quand, motif — et émettre un événement métier dans la même transaction que la transition (constitution, principe VI).

#### Dossier coursier (CPT-04)

- **FR-015**: Le dossier coursier DOIT être constitué et soumis par le coursier lui-même dans Mefali Pro et comporter : une pièce d'identité (document image stocké dans le stockage objet, à accès restreint), au moins un véhicule déclaré parmi les types de transport ACTIFS de la zone du coursier (référentiel ZON-03, résolu par héritage), et un référent local (nom + téléphone).
- **FR-016**: Le dossier DOIT avoir un statut parmi {en attente, validé, suspendu} ; la mise en ligne du coursier DOIT exiger le statut « validé » — la porte est posée dans ce cycle, la mise en ligne elle-même relève du module coursier (CRS, cycles ultérieurs).
- **FR-017**: L'Admin DOIT pouvoir consulter le dossier complet (pièce lisible, véhicules, référent), le valider, le refuser ou le suspendre avec motif — via l'API d'administration journalisée de ce cycle, les écrans arrivant au cycle ADM (T3).
- **FR-018**: Les véhicules déclarés DOIVENT être exposés comme capacités de transport du coursier, consommables par le dispatch (DSP, hors périmètre) pour ne proposer que des commandes compatibles.

#### Adresses enregistrées (CPT-05)

- **FR-019**: Après une livraison réussie à une adresse ponctuelle, le système DOIT proposer d'enregistrer l'adresse de remise : libellé (« Maison », « Bureau » ou libre), position GPS et repère — texte et/ou note vocale (durée maximale paramètre de zone, ≤ 30 s) ; la proposition est refusable et l'enregistrement n'est jamais obligatoire.
- **FR-020**: La réutilisation d'une adresse enregistrée DOIT se faire en un geste, sans ressaisie : position et repère — note vocale incluse — repris tels quels, la note vocale restant jouable par le coursier.
- **FR-021**: L'utilisateur DOIT pouvoir lister, renommer et supprimer ses adresses enregistrées ; ces changements ne valent que pour l'avenir (aucun effet sur les livraisons passées).
- **FR-022**: La note vocale de repère d'une adresse enregistrée DOIT être conservée tant que l'adresse est utilisée et purgée automatiquement après 12 mois sans utilisation de l'adresse — durée en paramètre de zone, éditable (minimisation des données, conformité ARTCI — constitution, principe VIII) ; une adresse dont le repère a été purgé reste utilisable et redemande un repère à sa prochaine utilisation.

#### Provision — restrictions de compte (CPT-06, hors périmètre)

- **FR-023**: Le modèle de compte DOIT comporter les drapeaux `prepaiement_impose` (prépaiement imposé) et `bloque` (bloqué), inactifs par défaut — colonnes UNIQUEMENT : aucune UI, aucune logique ne les lit ni ne les écrit au MVP (constitution, principe IX).

#### Transverse

- **FR-024**: Toute chaîne visible par l'utilisateur DOIT être une clé i18n fr ; tout paramètre qualifié de paramétrable — indicatif téléphonique par défaut, durée maximale de la note vocale, durée de rétention du repère vocal d'adresse — DOIT vivre dans la configuration de zone (héritage ZON-01), jamais en dur.

### Key Entities

- **Compte** : identité Mefali — numéro E.164 unique (aucune donnée nominative au MVP), zone de rattachement, consentement ARTCI (horodatage + version du texte), drapeaux de restriction en provision (`prepaiement_impose`, `bloque`), dates de création/dernière connexion.
- **Défi OTP** : demande de vérification éphémère — numéro, empreinte du code (jamais le code en clair), expiration (5 min), essais restants (3) ; invalidé par toute nouvelle demande.
- **Compteur d'envoi SMS** : donnée éphémère par numéro sur fenêtre d'une heure (plafond 3) ; reconstructible, jamais une vérité durable.
- **Session / Appareil** : lien compte ↔ appareil — droit de renouvellement révocable individuellement, identification de l'appareil, dernière activité, état (active/révoquée) ; ne s'éteint que par révocation, jamais par expiration propre.
- **Attribution de rôle** : lien compte ↔ rôle {client, coursier, vendeur, admin} — état de validation pour coursier/vendeur (en attente, validé, refusé, suspendu), horodatages, décideur, motif ; chaque transition émet un événement métier.
- **Dossier coursier** : pièce d'identité (référence au document du stockage objet), référent local (nom, téléphone), statut {en attente, validé, suspendu}, historique des décisions.
- **Véhicule déclaré** : lien dossier coursier ↔ type de transport du référentiel ZON-03 — capacité exposée au dispatch.
- **Adresse enregistrée** : compte, libellé, position GPS, repère texte, note vocale (référence audio + durée), zone, livraison d'origine, date de dernière utilisation (pour la purge du repère vocal après 12 mois d'inutilisation).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Une personne sans compte finalise son inscription — du numéro saisi à l'accueil connecté, réception du SMS comprise — en moins de 2 minutes, sans assistance.
- **SC-002**: 100 % des codes expirés (> 5 min) ou sur-essayés (> 3 saisies) sont rejetés, et le 4ᵉ SMS demandé dans l'heure pour un même numéro n'est jamais envoyé — vérifié par les tests des trois garde-fous.
- **SC-003**: Les réponses du parcours OTP sont indistinguables entre un numéro inscrit et un numéro inconnu — revue exhaustive des réponses (contenu et forme) : zéro divergence exploitable pour énumérer les comptes.
- **SC-004**: Après une déconnexion à distance, l'appareil révoqué perd tout accès au compte immédiatement à son prochain renouvellement, et au plus tard 15 minutes après la révocation (durée de vie maximale de l'accès court) ; les autres appareils du compte ne sont pas affectés.
- **SC-005**: Zéro contournement dans les tests : aucun scénario ne permet à un coursier non validé ou suspendu de franchir la porte de mise en ligne, ni à un compte sans rôle professionnel validé d'exécuter une action réservée.
- **SC-006**: Un compte cumulant les rôles coursier et vendeur validés bascule d'une interface Mefali Pro à l'autre sans se reconnecter, en moins de 5 secondes.
- **SC-007**: La réutilisation d'une adresse enregistrée ne demande aucune ressaisie — un geste — et la note vocale de repère rejouée est identique à l'originale (octets) — vérifié côté client ce cycle ; la restitution côté coursier repose sur le même mécanisme de stockage et est validée au cycle CRS.
- **SC-008**: 100 % des comptes créés portent un consentement ARTCI horodaté avec version du texte, et 100 % des transitions de validation (rôles, dossiers) sont journalisées avec auteur, horodatage et motif.

## Assumptions

- **Flux unique inscription/connexion** : la création de compte a lieu à la première vérification réussie d'un numéro inconnu — c'est la condition structurelle du non-dévoilement de l'existence d'un compte (deux flux séparés trahiraient l'existence dès l'écran d'entrée).
- **Compte sans profil** (clarifié 2026-07-14) : le compte se réduit au numéro vérifié, à sa zone de rattachement et au consentement — aucune donnée nominative ; les professionnels ne voient qu'un numéro masqué et l'identification à la remise passe par le QR/code de livraison (cadrage §7.4). Tout profil éventuel relève de cycles ultérieurs.
- **Constantes OTP produit** : 6 chiffres, 5 minutes, 3 essais, 3 SMS/h/numéro sont des constantes MVP — elles ne figurent pas au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md`. L'indicatif par défaut et la durée maximale de note vocale (≤ 30 s, référence CMD-02) sont, eux, des paramètres de zone.
- **Surface d'administration minimale** (précédent du cycle 002) : validation/refus/suspension des rôles et dossiers exposés en API, protégés par le rôle admin et journalisés (qui, quand, avant/après) ; les écrans d'administration arrivent au cycle ADM (tranche T3).
- **Déclencheur de la story 5** : « livraison réussie » est un événement des modules commandes/coursier (CMD/CRS, cycles ultérieurs) ; ce cycle livre la capacité complète (proposer, enregistrer, lister, réutiliser, gérer) exercée par un déclencheur simulé dans les tests. La note vocale de repère est captée au parcours de commande (CMD-02) ; ce cycle en conserve la référence et la restitution.
- **Stockage de la pièce d'identité** : le stockage objet du projet — le descriptif initial du module citait MinIO, remplacé par Garage depuis la constitution 1.0.1 (MinIO community archivé) ; la spec reste agnostique : « stockage objet sécurisé à accès restreint ».
- **Rôle vendeur attribué à l'agrément** (cadrage §5.1) : pas de demande vendeur in-app au MVP — l'Admin attribue le rôle lors de l'agrément du prestataire, l'agrément valant validation ; la fiche d'agrément complète (charte signée, photos, GPS…) relève de VND-01 (même tranche, cycle distinct) — ce cycle fournit l'état du rôle et son API.
- **Durée de l'accès court** : cible ≤ 15 minutes (défaut raisonnable, principe VIII « JWT de courte durée ») ; la valeur exacte relève du plan. La session (droit de renouvellement), elle, est illimitée tant que non révoquée (clarifié 2026-07-14) — la sécurité d'un appareil perdu repose sur la déconnexion à distance.
- **Rétention des données sensibles** : la note vocale d'adresse est clarifiée (purge après 12 mois sans utilisation de l'adresse, paramètre de zone) ; la rétention de la pièce d'identité — conservée tant que le dossier coursier est actif, sa finalité — est fixée au plan, conforme ARTCI.
- **Premier admin** : créé par seed à l'initialisation de l'environnement — aucun parcours applicatif d'auto-promotion.
- **SMS transactionnels** : l'envoi effectif des SMS passe par un fournisseur dont le choix et l'intégration relèvent du plan ; les tests utilisent un envoi simulé. Les autres notifications (push, fallback SMS) relèvent du module NTF, hors périmètre.
