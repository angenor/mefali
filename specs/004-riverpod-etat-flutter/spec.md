# Feature Specification: Gestion d'état des apps Flutter — migration vers Riverpod codegen

**Feature Branch**: `004-riverpod-etat-flutter`

**Created**: 2026-07-17

**Status**: Draft

**Input**: User description: "Migration du state management Flutter vers Riverpod (codegen @riverpod), app-wide — mefali_core + mefali_pro + mefali_client. REFACTOR PUR : aucun changement visible par l'utilisateur, mêmes écrans, mêmes flux, même fil réseau, même contrat ; le backend n'est pas touché. Les bénéficiaires sont les développeurs/mainteneurs. Le contrat de comportement, ce sont les tests widget/unitaires existants : ils doivent rester VERTS de bout en bout. Périmètre : tout porteur d'état d'app/domaine passe en provider @riverpod ; inversion de l'injection (constructeur → ProviderScope) ; découpler client HTTP / intercepteur / session sans dépendance circulaire en gardant le refresh auto ; les doubles de test injectés par constructeur deviennent des overrides de ProviderScope ; infra codegen (riverpod_generator + build_runner + riverpod_lint via custom_lint, .g.dart committés). Verrouiller le pattern dans la constitution pour que les cycles métier suivants (CRS, VND, CMD…) partent du même moule. Hors périmètre : aucune nouvelle fonctionnalité ni écran ; aucun changement backend ; la décision R14 (double-submit concurrent du dossier) et le chantier iOS/enregistrement vocal restent intouchés."

## Clarifications

### Session 2026-07-17

- Q: `ServiceConfig` n'est pas un `ChangeNotifier` (classe nue) et n'est observé par personne : ses deux consommateurs en prennent un instantané figé en `initState`, si bien que le rafraîchissement horaire n'atteint jamais l'UI. Le passer en provider le rendrait réactif « gratuitement ». Est-il dans le périmètre, et à quelle condition ? → A: Dans le périmètre, **non-réactivité gelée**. Le provider expose le service (ou un instantané), jamais une valeur observée : la version de consentement et la liste des transports restent lues une fois, à l'entrée de l'écran. Rendre la configuration vivante serait une amélioration — donc un changement visible — et relève d'un autre cycle. Point de vigilance assumé : les deux méthodes concernées ne sont couvertes par aucun test ; ce sont précisément celles que la migration réécrit.
- Q: La demande initiale range les « faux plugins caméra/micro/audio » parmi les doubles à convertir en surcharges. Or ce ne sont pas des objets injectés mais quatre fonctions passées en paramètre de widget (choix de pièce, lecture de note, capture de note, relecture du code dev), sous une doctrine écrite dans le code — « on double la FONCTION, pas le canal ». Deviennent-elles des providers ? → A: **Non — elles restent des paramètres de constructeur.** Ce cycle migre l'ÉTAT, pas les callbacks : un callback passé à un widget reste idiomatique sous Riverpod. Les providerifier élargirait le périmètre à quatre widgets de plus et ajouterait un couplage au client HTTP de la session (relecture du code dev), dans le nœud le plus risqué du cycle. Règle : tout ou rien — aucune des quatre ne bascule.
- Q: Le state management n'apparaît dans aucun document produit. Le cycle se rattache-t-il à une story ? → A: **Oui — TRX-08, priorité produit P1**, écrite dans le module « Transverse & infrastructure » de `docs/user-stories-v2.md` (et son tableau §0.6 mis à jour) **avant le `/speckit.specify`**, comme la constitution l'impose. P1 et non P0 : le statu quo fonctionne, donc « sans cette story on ne lance pas » est faux — le fallback est de ne rien faire.

## User Scenarios & Testing *(mandatory)*

Persona unique de ce cycle : **Admin (toi)** — fondateur et développeur solo. Le bénéficiaire n'est pas l'utilisateur final : c'est le développement de tous les cycles métier suivants (CRS, VND, CMD…), qui partiront d'un moule unique au lieu de recopier une convention non écrite.

Priorités produit : le cycle porte la story **TRX-08 (P1)** de `docs/user-stories-v2.md`. Les priorités P1→P6 ci-dessous sont l'ordre de livraison interne au cycle (dépendances techniques), pas une hiérarchie produit.

**L'invariant central prime sur toutes les stories** : ce cycle est un refactor pur. Aucun écran, aucun texte, aucun enchaînement, aucune requête réseau ne change. Le contrat de comportement, ce sont les **86 cas de test existants** (61 dans `mefali_core`, 23 dans `mefali_pro`, 2 dans `mefali_client` — chiffre vérifié par exécution, dont 84 en CI et 2 goldens). Toute story qui améliorerait un comportement au passage a échoué, même si elle est verte.

### User Story 1 - Le pattern est armé et vérifié mécaniquement (TRX-08, Priority: P1 — produit : P1)

L'Admin dispose, dans les trois paquets Flutter, de la chaîne complète qui rend le pattern obligatoire et vérifiable sans relecture humaine : les dépendances Riverpod figées, la génération de code déterministe, l'analyse statique dédiée qui refuse les erreurs classiques de providers, et un garde-fou d'intégration continue qui bloque toute dérive entre le code annoté et le code généré commité.

**Why this priority**: Aucun porteur d'état ne peut migrer avant que la chaîne existe. C'est aussi la seule story dont le bénéfice survit à une interruption du cycle : outillage posé, le reste peut être repris story par story. Développeur solo — la revue est outillée, pas humaine (constitution, Governance) : un pattern qu'aucun outil ne vérifie n'est pas un pattern, c'est une intention.

**Independent Test**: Ajouter volontairement une erreur classique de provider (dépendance non déclarée, référence mal utilisée), puis modifier un fichier annoté sans régénérer : l'analyse échoue dans le premier cas, la CI échoue sur le diff dans le second.

**Acceptance Scenarios**:

1. **Given** les trois paquets Flutter, **When** l'Admin inspecte leurs dépendances, **Then** Riverpod, son générateur et ses règles d'analyse sont présents en dernière version stable vérifiée à l'ouverture du cycle, figée par les trois lockfiles commités, et les trois lockfiles s'accordent sur les mêmes versions.
2. **Given** le code annoté, **When** la génération s'exécute deux fois de suite, **Then** elle produit le même résultat et ne laisse aucune modification non commitée.
3. **Given** une modification d'un fichier annoté sans régénération, **When** la CI s'exécute, **Then** le build échoue sur le diff de code généré non commité — sur le modèle du garde-fou contrat/clients existant.
4. **Given** un fichier de code généré, **When** l'analyse statique s'exécute, **Then** elle est verte sur les trois paquets, y compris sous les options strictes du paquet cœur, sans qu'aucune règle existante ait été désactivée pour le confort.
5. **Given** l'analyse dédiée aux providers, **When** une erreur classique est introduite volontairement, **Then** elle est signalée en échec, pas en avertissement ignorable.
6. **Given** les deux applications, **When** l'Admin les lance, **Then** leur point d'entrée enveloppe l'arbre dans la portée de providers, et le comportement au démarrage est inchangé — écran de démarrage identique, mêmes appels réseau, dans le même ordre.

---

### User Story 2 - La session et son intercepteur migrent sans jamais dédoubler le renouvellement (TRX-08, Priority: P2 — produit : P1)

L'Admin migre le nœud le plus risqué : la session d'authentification, le client HTTP qu'elle porte et l'intercepteur qui pose le jeton et renouvelle sur expiration. Les trois sont découplés sans dépendance circulaire, le renouvellement automatique continue de fonctionner à l'identique, et le harnais de test qui naît ici — piloté par le cas le plus dur — sert ensuite à toutes les autres stories.

**Why this priority**: C'est le seul endroit où une migration naïve ne dégrade pas la qualité mais **déconnecte l'utilisateur**. La rotation des jetons de renouvellement invalide le jeton précédent : deux intercepteurs sur le même client, c'est deux renouvellements concurrents, un jeton déjà tourné rejoué, un vol présumé côté serveur, et la session révoquée. Le code actuel documente précisément ce désastre comme la raison d'être de son verrou. Tout ce qui suit s'appuie sur la session : la migrer en premier, avec son harnais, évite de recopier six fois un montage bancal.

**Independent Test**: Rejouer les cas de session et d'appareils existants, puis lancer plusieurs requêtes concurrentes qui expirent en même temps et compter les renouvellements émis : exactement un.

**Acceptance Scenarios**:

1. **Given** une session ouverte, **When** une requête part, **Then** elle porte l'en-tête d'autorisation ; sans session, aucun en-tête n'est ajouté.
2. **Given** une requête refusée pour jeton expiré, **When** l'intercepteur agit, **Then** il renouvelle, rejoue la requête une seule fois, et l'appelant ne sait jamais qu'il y a eu un refus.
3. **Given** un renouvellement refusé par le serveur, **When** l'intercepteur le constate, **Then** la session se ferme et l'application retourne au parcours d'authentification — sans navigation impérative, par simple reconstruction de l'arbre.
4. **Given** un refus portant sur l'appel de renouvellement lui-même, **When** l'intercepteur l'examine, **Then** il ne tente aucun renouvellement — l'anti-boucle est préservé.
5. **Given** **plusieurs requêtes concurrentes** qui se voient toutes refusées pour jeton expiré, **When** elles atteignent l'intercepteur, **Then** **un seul** appel de renouvellement est émis et toutes le partagent. (Comportement existant, **aujourd'hui non couvert par un test** : ce cycle le couvre — voir Assumptions.)
6. **Given** la portée de providers sollicitée, le provider de session ré-évalué, ou une session fermée puis rouverte, **When** on inspecte le client HTTP de la session, **Then** il porte **exactement une** instance de l'intercepteur d'autorisation de l'application — jamais deux.
7. **Given** l'application au démarrage, **When** la session relit les jetons persistés, **Then** l'écran de démarrage tient l'attente comme aujourd'hui, le premier rendu n'est pas retardé, et l'état « chargé » ne redevient jamais « en cours » ensuite — l'écran de démarrage ne peut pas réapparaître en plein parcours.
8. **Given** le client HTTP de la configuration, **When** il émet une requête, **Then** elle ne porte **jamais** d'en-tête d'autorisation : les deux clients restent distincts, avec leurs délais d'attente actuels inchangés.

---

### User Story 3 - Le paquet cœur migre, configuration gelée comprise (TRX-08, Priority: P3 — produit : P1)

L'Admin migre les porteurs d'état restants du paquet cœur : le parcours d'authentification, la racine, les listes d'adresses et d'appareils, et le service de configuration — ce dernier avec sa non-réactivité explicitement gelée. L'état strictement local (saisies, focus, compte à rebours, brouillons non soumis) reste où il est.

**Why this priority**: Le paquet cœur concentre 26 des 34 mutations d'état locales et il est partagé par les deux applications : tant qu'il n'est pas migré, ni `mefali_pro` ni `mefali_client` ne peuvent l'être. La configuration y est le piège le plus contre-intuitif du cycle : la migrer « bien » la rendrait vivante, et la rendre vivante est une régression au sens de ce cycle.

**Independent Test**: Rejouer les cas d'authentification, d'adresses, d'appareils et de configuration ; puis, sur émulateur, laisser tourner l'application au-delà d'un rafraîchissement de configuration et vérifier qu'aucun écran affiché ne bouge.

**Acceptance Scenarios**:

1. **Given** la configuration rafraîchie en arrière-plan, **When** un écran est affiché, **Then** **rien ne change à l'écran** : la version de consentement et la liste des transports restent celles lues à l'entrée de l'écran.
2. **Given** l'application au démarrage, **When** le point d'entrée s'exécute, **Then** il déclenche l'amorçage de la configuration avant de lancer l'application, **sans l'attendre** — comme aujourd'hui —, et le service continue de rafraîchir une fois par heure, indéfiniment, sans jamais s'arrêter ni redémarrer.
3. **Given** un démarrage hors ligne, **When** la configuration est demandée, **Then** le cache est servi ; une version identique n'écrit pas dans le cache, une version nouvelle remplace valeur et cache.
4. **Given** une liste d'adresses ou d'appareils affichée, **When** l'Admin renomme, supprime ou révoque un élément, **Then** **le squelette de chargement réapparaît** pendant le rechargement, exactement comme aujourd'hui.
5. **Given** le parcours d'authentification, **When** l'Admin le déroule, **Then** les étapes s'enchaînent à l'identique : case de consentement jamais pré-cochée, renvoi verrouillé 60 secondes puis compte à rebours relancé et saisie vidée, version de consentement issue de la zone et inscription refusée si elle est absente.
6. **Given** la surface de relecture du code en développement, **When** on construit l'application sans le drapeau dédié, **Then** elle reste une constante de compilation évaluée à faux, la branche est éliminée du binaire, et **aucun provider ne la remplace**.
7. **Given** les écrans à état local (saisie du téléphone, saisie du code, consentement, dialogue de renommage, enregistreur vocal, brouillon d'adresse), **When** on inspecte le code après migration, **Then** leur état est resté local — le cycle ne les a pas providerifiés.

---

### User Story 4 - Les rôles migrent sans jamais fuiter d'un compte à l'autre (TRX-08, Priority: P4 — produit : P1)

L'Admin migre l'état des rôles de `mefali_pro` : chargement des attributions, bascule de rôle actif, écran d'état de demande, formulaire de dossier. La durée de vie de cet état reste strictement liée à la session : les rôles d'un compte ne peuvent pas survivre à un changement de compte.

**Why this priority**: C'est le second et dernier porteur d'état de type notificateur, et le seul dont la durée de vie est une **garantie de sécurité**, pas un détail de performance. Aujourd'hui, la déconnexion démonte le sous-arbre et tue l'état des rôles ; un provider à portée racine survivrait au changement de compte et afficherait les rôles du compte précédent. C'est aussi la story qui contient le formulaire de dossier, donc la clé d'idempotence : le point où R14, déclaré hors périmètre, pourrait sortir de son isolement sans qu'on le remarque.

**Independent Test**: Rejouer les cas de routeur de rôles et de formulaire de dossier ; puis, sur émulateur, se connecter avec un compte, se déconnecter, se connecter avec un autre et vérifier qu'aucune trace du premier n'apparaît.

**Acceptance Scenarios**:

1. **Given** un compte connecté avec ses rôles chargés, **When** l'Admin se déconnecte puis se connecte avec un autre compte, **Then** **aucun rôle du compte précédent n'est visible**, à aucun instant, même fugitivement.
2. **Given** un statut de rôle inconnu, **When** le routeur décide, **Then** la porte reste fermée ; les rôles non professionnels sont ignorés.
3. **Given** un rôle actif toujours validé, **When** les rôles sont rechargés, **Then** il **reste** actif ; s'il a été suspendu entre deux chargements, il ne reste pas affiché.
4. **Given** l'Admin qui bascule de rôle, **When** la bascule s'opère, **Then** elle ne parle pas au réseau et ne touche pas à la session.
5. **Given** un rechargement des rôles demandé, **When** il s'exécute, **Then** l'écran de chargement **réapparaît** — contrairement à la session, dont l'état chargé ne redevient jamais « en cours ».
6. **Given** le formulaire de dossier, **When** l'Admin soumet, puis re-soumet après un échec, **Then** la clé d'idempotence est présente et **identique** d'un essai à l'autre ; un dossier refusé puis reconstitué en génère une **nouvelle**. La portée de cette clé est exactement celle d'aujourd'hui — ni élargie, ni rétrécie.
7. **Given** un rechargement déclenché après un retour d'écran, **When** l'écran a pu disparaître entre-temps, **Then** aucune erreur d'accès à un contexte démonté ne se produit.

---

### User Story 5 - Plus aucun porteur d'état hors du moule (TRX-08, Priority: P5 — produit : P1)

L'Admin termine par `mefali_client`, puis constate que les compteurs sont à zéro : plus aucun notificateur manuel, plus aucun observateur manuel, plus aucune notification manuelle dans les applications. Le code mort qui documentait l'ancienne convention disparaît avec elle.

**Why this priority**: C'est la story qui rend le résultat vérifiable d'un seul geste. `mefali_client` est trivial (deux fichiers, aucun état) mais il ferme le périmètre : tant qu'un porteur subsiste, la convention est « Riverpod sauf exceptions », ce qui n'est pas une convention. Elle nettoie aussi la seule couche d'injection de test qui n'a jamais été câblée — du code mort à supprimer, pas à porter.

**Independent Test**: Rechercher les symboles de l'ancien pattern dans les applications : aucun résultat. Rejouer les 86 cas existants, plus les cas ajoutés en US2.

**Acceptance Scenarios**:

1. **Given** l'ensemble des applications, **When** on recherche les notificateurs manuels, les observateurs manuels et les notifications manuelles, **Then** il n'en reste **aucun** — les décomptes passent de 2, 2 et 6 à zéro.
2. **Given** `mefali_client`, **When** l'Admin le lance, **Then** son point d'entrée n'instancie plus ni session ni configuration à la main, et son écran de démarrage est identique au pixel près.
3. **Given** la couche d'injection de test des rôles jamais câblée nulle part, **When** le cycle se termine, **Then** elle a été **supprimée**, pas portée.
4. **Given** le commentaire du code qui énonce la convention actuelle comme normative, **When** le cycle se termine, **Then** il énonce la nouvelle convention.
5. **Given** les défauts latents préexistants repérés à la cartographie, **When** le cycle se termine, **Then** ils sont **consignés et non corrigés** — un refactor pur ne répare pas en passant.

---

### User Story 6 - Le moule est opposable aux cycles suivants (TRX-08, Priority: P6 — produit : P1)

L'Admin verrouille le résultat : la constitution nomme Riverpod codegen comme LE pattern de gestion d'état des applications Flutter, et le guide d'exécution courant est synchronisé. Les cycles métier suivants n'ont plus à choisir.

**Why this priority**: C'est la raison d'être du cycle. Sans ce verrou, le refactor n'est qu'un goût personnel exprimé une fois : rien n'empêche le cycle CRS de réintroduire un notificateur, et l'on aurait payé la migration pour rien. On verrouille en dernier, une fois le pattern prouvé sur le code réel plutôt que sur l'intention.

**Independent Test**: Ouvrir la constitution et y trouver une règle opposable, citable en revue, qui tranche sans discussion le choix de gestion d'état d'un futur cycle.

**Acceptance Scenarios**:

1. **Given** la constitution, **When** un cycle suivant introduit un porteur d'état, **Then** une règle nommée tranche : provider généré, injection par la portée, état local réservé à ce qui ne sort pas du widget, et le choix entre les deux moules de porteurs (état propre pour une sémantique de chargement dédiée, porteur asynchrone pour les listes) — cette dernière distinction protégeant FR-022.
2. **Given** l'amendement, **When** il est passé, **Then** il l'est par la procédure prévue (rapport d'impact en tête, propagation aux templates dépendants) et versionné en conséquence — ajout de principe, donc incrément mineur.
3. **Given** `CLAUDE.md`, **When** le cycle se termine, **Then** il énonce la même règle que la constitution et ne la contredit pas.
4. **Given** `docs/user-stories-v2.md`, **When** le cycle se termine, **Then** TRX-08 y figure toujours avec ses critères, et le tableau de comptage §0.6 est resté à jour.

---

### Edge Cases

Chaque cas ci-dessous correspond à un piège relevé dans le code réel, avec sa conséquence si la migration est menée de la façon la plus naturelle.

- **Que se passe-t-il si le porteur de session est ré-évalué une seconde fois ?** L'intercepteur est aujourd'hui posé dans le corps du constructeur, et rien ne l'en retire : une seconde évaluation en empile un deuxième sur le même client. Deux intercepteurs, deux verrous, deux renouvellements concurrents, rotation des jetons, vol présumé, **session révoquée**. C'est le mode de panne n°1 du cycle.
- **Que se passe-t-il si la durée de vie par défaut du générateur s'applique à la session et à la configuration ?** Ces deux objets naissent aujourd'hui au lancement et vivent tout le processus. Sous la valeur par défaut, ils seraient détruits dès que plus personne ne les écoute : soit le rafraîchissement horaire s'arrête et redémarre — comportement qui n'existe pas aujourd'hui — soit chaque nouvelle souscription relit le cache et redemande la configuration au serveur.
- **Que se passe-t-il si l'on applique la même durée de vie à l'état des rôles ?** L'inverse exact : il survivrait au changement de compte et **fuiterait les rôles du compte précédent**. Se tromper dans un sens coûte des requêtes ; dans l'autre, c'est une régression de sécurité silencieuse. Les deux réglages sont opposés et aucun défaut ne convient aux deux.
- **Que se passe-t-il si la configuration devient observable ?** Les rafraîchissements horaires atteindraient l'UI et la version de consentement comme les choix de véhicules changeraient sous les doigts de l'utilisateur. C'est une amélioration, donc une **violation de l'invariant central**.
- **Que se passe-t-il si l'on garde le comportement par défaut d'affichage des états asynchrones lors d'un rechargement ?** Le squelette **cesserait** de réapparaître après un renommage, une suppression ou une révocation. Le défaut du framework est exactement l'inverse du comportement actuel : il faut le désactiver explicitement, et personne ne pense à un défaut.
- **Que se passe-t-il si l'on route sur changement d'état de session ?** C'est le réflexe du framework, et c'est le seul geste que le code interdit noir sur blanc : la racine reconstruit déjà l'arbre sur ouverture de session ; router en plus **pousserait deux fois vers l'accueil**.
- **Que se passe-t-il si la surface dev de relecture du code devient un provider ?** Elle cesse d'être une constante de compilation, l'élimination de branche morte meurt, et le code de relecture entre dans le binaire de production. Le garde serveur tiendrait, mais l'invariant côté application serait détruit **en silence** — et le test qui le protège **resterait vert**.
- **Que se passe-t-il si le formulaire de dossier devient un widget sans état ?** C'est le geste naturel quand on supprime les widgets à état, et il n'y a alors plus d'endroit où poser la clé d'idempotence. Régénérée trop souvent, elle crée un doublon ; conservée trop longtemps, elle fait rejouer une clé périmée. C'est le **seul chemin** par lequel un refactor « pur » ferait sortir R14 de son isolement.
- **Que se passe-t-il si un rechargement est demandé après un retour d'écran ?** L'écran d'état de demande est sans état et n'a donc aucun garde de montage ; aujourd'hui c'est inoffensif, mais l'accès à la référence de providers après démontage lève une erreur.
- **Que se passe-t-il si l'ensemble de véhicules continue d'être muté en place ?** La mutation en place fonctionne avec le mécanisme actuel, mais un porteur qui compare par identité ne notifierait pas.
- **Que se passe-t-il si les deux clients HTTP sont fusionnés derrière un provider unique ?** Le client de configuration porterait un en-tête d'autorisation qu'il n'a jamais porté, et les délais d'attente actuels — qui ne vivent que dans la branche par défaut du client généré — seraient perdus.
- **Que se passe-t-il si l'amorçage de la configuration devient paresseux ?** Il est aujourd'hui impératif et inconditionnel : le point d'entrée le déclenche au lancement et ne l'attend pas, délibérément, pour ne pas faire patienter devant un écran vide. Sous un provider paresseux, le déclenchement quitte le point d'entrée et devient contingent d'un consommateur qui lit. À consommateurs inchangés, le décalage est négligeable — la racine lit la configuration dès son montage, donc à chaque lancement. Le piège est le geste que l'idiome invite juste après : lire la configuration là où elle compte — l'étape du consentement, les véhicules du formulaire — plutôt qu'à la racine. La requête ne partirait alors qu'à l'entrée de ces écrans : un démarrage qui ne les atteint pas n'appellerait jamais le serveur, et le rafraîchissement horaire ne démarrerait pas. C'est un déplacement de requête au sens de FR-002, pas un réglage.

## Requirements *(mandatory)*

### Functional Requirements

**L'invariant central — il prime sur tout le reste**

- **FR-001**: Le système DOIT se comporter, après migration, de façon indiscernable pour l'utilisateur : mêmes écrans, mêmes textes, mêmes enchaînements, mêmes états de chargement et d'erreur, mêmes temporisations perceptibles.
- **FR-002**: Le système DOIT émettre exactement les mêmes requêtes réseau, avec les mêmes en-têtes, dans le même ordre, aux mêmes moments du cycle de vie — aucune ajoutée, aucune supprimée, aucune déplacée avant ou après le premier rendu.
- **FR-003**: Les **86 cas de test existants** DOIVENT rester verts, et chacun DOIT prouver le même comportement qu'avant. Seule leur **mécanique d'injection et d'observation** peut être réécrite. Exception unique et nommée : le cas « ouvrir persiste les jetons et notifie » compte aujourd'hui les notifications via l'API d'écoute que FR-008 supprime ; il DOIT être traduit en une assertion de **force équivalente** sur le nombre d'émissions du provider (exactement 1 pour une ouverture), jamais relâché en simple contrôle d'état.
- **FR-004**: Aucun test existant NE DOIT être supprimé, désactivé, ni affaibli dans ce qu'il affirme. Un test qui ne passe qu'au prix d'une assertion relâchée compte comme un échec du cycle.
- **FR-005**: Les deux tests de référence visuelle DOIVENT passer sans régénération de leur image de référence.
- **FR-006**: Le contrat d'API, le backend et les clients générés NE DOIVENT PAS être modifiés.

**Le pattern**

- **FR-007**: Tout porteur d'état d'application ou de domaine DOIT être exposé par un provider généré par annotation.
- **FR-008**: Les applications NE DOIVENT contenir aucun notificateur manuel, aucun observateur manuel de notificateur, aucune notification manuelle.
- **FR-009**: L'état strictement local à un widget — contrôleur de saisie, focus, compte à rebours ergonomique, brouillon non soumis, ressource native liée au widget — DOIT rester local. Le cycle ne le providerifie pas.
- **FR-010**: L'injection DOIT passer par la portée de providers ; les points d'entrée des deux applications NE DOIVENT plus instancier session ni configuration à la main.
- **FR-011**: Les quatre fonctions injectées en paramètre de widget (choix de pièce, lecture de note, capture de note, relecture du code dev) DOIVENT rester des paramètres de constructeur — tout ou rien, aucune ne bascule (clarification du 2026-07-17).
- **FR-012**: Le paramètre d'environnement de l'URL d'API DOIT rester une constante de compilation dans chaque point d'entrée ; le paquet cœur DOIT continuer de recevoir cette URL sans jamais lire l'environnement lui-même.

**Le nœud session / client HTTP / intercepteur**

- **FR-013**: Le client HTTP de la session DOIT porter **exactement une** instance de l'intercepteur d'autorisation de l'application, sur toute la durée de vie du processus ; aucune ré-évaluation de provider NE DOIT pouvoir en empiler une seconde. Le client HTTP de la configuration NE DOIT en porter **aucune**. Les quatre intercepteurs d'authentification que le client généré installe par défaut sur tout client (OAuth, Basic, Bearer, clé d'API) sont **hors décompte** : ils sont déjà présents sur les deux clients aujourd'hui et restent inertes faute de jeton.
- **FR-014**: Le système DOIT garantir qu'un ensemble de requêtes concurrentes refusées pour jeton expiré ne déclenche **qu'un seul** renouvellement, partagé. Ce comportement existe et n'est aujourd'hui couvert par aucun test : le cycle DOIT le couvrir.
- **FR-015**: Le système DOIT préserver l'anti-boucle (aucun renouvellement sur un refus portant sur l'appel de renouvellement) et la règle du rejeu unique.
- **FR-016**: Un renouvellement refusé DOIT fermer la session et ramener au parcours d'authentification par reconstruction de l'arbre, sans navigation impérative — et sans double poussée vers l'accueil à la reconnexion.
- **FR-017**: Le système DOIT conserver **deux clients HTTP distincts** : celui de la configuration NE DOIT jamais porter d'en-tête d'autorisation, et les deux DOIVENT conserver leurs délais d'attente actuels.
- **FR-018**: Le système DOIT libérer ce qu'il acquiert : tout intercepteur posé sur un client dont la durée de vie diffère DOIT être retiré à la destruction du provider qui l'a posé.

**Les durées de vie — chacune est un comportement, pas un réglage**

- **FR-019**: La session et le service de configuration DOIVENT vivre toute la durée du processus ; le rafraîchissement horaire NE DOIT jamais s'arrêter ni redémarrer.
- **FR-020**: L'état des rôles DOIT être détruit au changement de compte ; les rôles d'un compte NE DOIVENT jamais être visibles sous un autre.
- **FR-021**: Le rafraîchissement horaire de la configuration NE DOIT **jamais** atteindre l'interface : les consommateurs en lisent un instantané à l'entrée de l'écran (clarification du 2026-07-17).
- **FR-022**: Le système DOIT préserver deux sémantiques de rechargement **opposées** : l'état « chargé » de la session ne redevient jamais « en cours » (l'écran de démarrage ne peut pas réapparaître en plein parcours), tandis qu'un rechargement des rôles réaffiche bien l'écran de chargement.
- **FR-023**: Le squelette de chargement DOIT réapparaître à chaque rechargement de liste, comme aujourd'hui.
- **FR-024**: L'amorçage de la configuration DOIT rester déclenché impérativement depuis le point d'entrée, au lancement, et **non attendu** — jamais différé au premier usage par un provider paresseux. Le lancement ne l'attend pas : aucun appel réseau ne retarde le premier rendu.

**Sécurité et périmètre gelé**

- **FR-025**: La surface de relecture du code en développement DOIT rester gouvernée par une **constante de compilation**, évaluée à faux en l'absence du drapeau dédié, afin que la branche soit éliminée du binaire. Elle NE DOIT pas devenir un provider.
- **FR-026**: La clé d'idempotence du dossier DOIT conserver exactement sa portée actuelle. Le formulaire de dossier DOIT conserver un état de widget qui survit aux reconstructions et disparaît à la fermeture de l'écran. R14 DOIT rester exactement dans l'état où le cycle l'a trouvé.
- **FR-027**: Les défauts latents préexistants relevés à la cartographie DOIVENT être consignés et **non corrigés** dans ce cycle. Exception unique et nommée : une dérive de code généré préexistante que la première exécution du garde-fou (FR-031) révélerait ; le plan tranche alors entre la corriger en la nommant comme telle et cadrer le garde-fou pour ne pas la révéler.

**L'outillage**

- **FR-028**: Riverpod, son générateur et ses règles d'analyse DOIVENT être pris en dernière version stable vérifiée à l'ouverture du cycle, puis figés par les trois lockfiles commités, accordés entre eux.
- **FR-029**: Le code généré DOIT être commité, à l'image des clients Dart générés.
- **FR-030**: La génération DOIT être déterministe : deux exécutions successives ne laissent aucune modification non commitée.
- **FR-031**: La CI DOIT échouer sur tout diff de code généré non commité pour les applications — le garde-fou qui protège aujourd'hui le contrat et ses clients ne couvre pas `apps/`.
- **FR-032**: L'analyse statique DOIT être verte sur les trois paquets, règles dédiées aux providers comprises, sans qu'aucune règle existante n'ait été désactivée par confort. La configuration d'analyse du paquet cœur — la plus stricte, et la seule à ne pas tolérer les annotations du générateur — DOIT être ajustée au minimum nécessaire.
- **FR-033**: Les erreurs classiques de providers DOIVENT être signalées en **échec**, pas en avertissement ignorable.
- **FR-034**: La régénération DOIT précéder le contrôle de dérive ; l'analyse s'exécute sur le code généré commité, présent dès la récupération du dépôt.

**Le harnais de test**

- **FR-035**: Les doubles aujourd'hui injectés par constructeur — stockage de jetons en mémoire, source et cache de configuration — DOIVENT devenir des surcharges de la portée de providers.
- **FR-036**: Le doublage du transport HTTP DOIT rester ce qu'il est (substitution de l'adaptateur sur un client réel), et il DOIT rester ordonné après la pose de l'intercepteur.
- **FR-037**: Le cycle DOIT livrer un harnais de test partagé (montage d'application sous portée de providers, conteneur explicite pour les cas sans arbre de widgets, doubles réutilisables). Il n'en existe aujourd'hui aucun : les doubles sont recopiés d'un fichier à l'autre.
- **FR-038**: Les cas de test aujourd'hui écrits sans arbre de widgets DOIVENT pouvoir surcharger leurs dépendances via un conteneur explicite.
- **FR-039**: Aucun canal de plateforme NE DOIT être simulé : la doctrine « on double la fonction, pas le canal » est préservée.

**La documentation — le verrou**

- **FR-040**: La constitution DOIT nommer Riverpod codegen comme LE pattern de gestion d'état des applications Flutter, par amendement passé selon la procédure prévue et versionné en incrément mineur. Le principe DOIT nommer **les deux moules de porteurs d'état** — un porteur à état propre pour ce qui a une sémantique de chargement dédiée (session, rôles), un porteur asynchrone pour les chargements de liste — sans quoi un cycle suivant les uniformiserait derrière un état asynchrone unique et détruirait la préservation des deux sémantiques opposées (FR-022).
- **FR-041**: `CLAUDE.md` DOIT énoncer la même règle et ne pas la contredire.
- **FR-042**: Le commentaire de code qui énonce aujourd'hui l'ancienne convention comme normative DOIT énoncer la nouvelle.
- **FR-043**: La couche d'injection de test des rôles, prévue mais câblée nulle part, DOIT être supprimée plutôt que portée.

### Hors périmètre

- **R14 — double-submit concurrent du dossier** : le cycle ne le traite pas. Il en préserve strictement l'état actuel (FR-026). La seule chose que ce cycle doit à R14, c'est de ne pas le déplacer.
- **iOS et l'enregistrement vocal** : ni vérification, ni correction, ni migration au-delà de ce que le refactor d'état impose. L'enregistreur vocal garde son état local (FR-009).
- **Toute nouvelle fonctionnalité, tout nouvel écran, toute amélioration d'ergonomie** — y compris celles que la migration rendrait « gratuites ».
- **Rendre la configuration réactive** : c'est un changement de comportement, il relève d'un autre cycle (clarification du 2026-07-17).
- **Le backend, le contrat d'API, les clients générés, le web Nuxt** : intouchés.
- **Les quatre fonctions injectées par constructeur** : elles ne deviennent pas des providers (clarification du 2026-07-17).
- **La correction des défauts latents préexistants** : consignés, pas corrigés (FR-027).
- **Les autres briques repérées puis différées au cycle 001** (routeur déclaratif, base locale de la file hors-ligne) : ce cycle ne migre que la gestion d'état. Les répertoires réservés à la file hors-ligne restent vides.
- **Toute réorganisation de fichiers ou renommage** qui ne découle pas mécaniquement de la migration.

### Key Entities

- **Porteur d'état d'application** : objet qui détient un état survivant à la reconstruction d'un widget et consommé par plusieurs endroits de l'interface — aujourd'hui injecté par constructeur, demain un provider généré. Les deux **notificateurs manuels** du projet : la session d'authentification et l'état des rôles. Le **service de configuration** est un porteur d'état **sans** notificateur (classe nue, non observée) : il est également hébergé par un provider, en non-réactivité gelée (FR-021).
- **État strictement local** : état qui naît et meurt avec un widget et que rien d'autre ne lit — saisies, focus, comptes à rebours, brouillons non soumis, ressources natives. Il n'est pas un porteur d'état et ne migre pas.
- **Portée de providers** : périmètre qui héberge les instances et permet, en test, de substituer une dépendance par un double sans passer par le constructeur du sujet.
- **Surcharge de test** : substitution d'une dépendance déclarée, dans une portée, pour la durée d'un cas de test — remplace l'injection par constructeur actuelle.
- **Durée de vie d'un porteur** : caractéristique **fonctionnelle** et non technique, puisqu'elle décide ici de la persistance d'un timer, de la réapparition d'un écran de chargement et de l'isolation des données entre deux comptes.
- **Code généré commité** : fichiers dérivés mécaniquement du code annoté, versionnés, dont toute dérive avec leur source casse le build — même règle que les clients d'API dérivés du contrat.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: **0** notificateur manuel, **0** observateur manuel et **0** notification manuelle subsistent dans les applications — les décomptes passent respectivement de 2, 2 et 6 à zéro.
- **SC-002**: **100 %** des 86 cas de test existants sont verts ; **0** test supprimé, désactivé ou affaibli ; les 2 tests de référence visuelle passent **à l'identique (0 diff)**, sans régénération d'image.
- **SC-003**: **0** changement observable : le parcours complet (inscription, rôles, dossier, adresses) rejoué de bout en bout sur émulateur est indiscernable de son déroulement avant migration — mêmes écrans, mêmes états de chargement, mêmes messages.
- **SC-004**: **0** requête réseau ajoutée, supprimée ou déplacée sur le parcours complet, ordre et en-têtes compris — vérifié de bout en bout.
- **SC-005**: Le client HTTP de la session porte **exactement 1** instance de l'intercepteur d'autorisation de l'application, celui de la configuration **0** — après ré-évaluation du provider de session, après fermeture puis réouverture de session, et après invalidation explicite de la portée (les 4 intercepteurs du client généré hors décompte). **1 seul** renouvellement pour N requêtes concurrentes expirées, toutes rejouées une fois. Vérifié par des tests **qui n'existaient pas avant ce cycle**.
- **SC-006**: **0** avertissement et **0** erreur d'analyse statique sur les 3 paquets, règles dédiées aux providers comprises ; **0** règle existante désactivée par confort.
- **SC-007**: La génération de code est déterministe : deux exécutions successives laissent **0** modification non commitée ; **100 %** du code généré est commité ; **100 %** des dérives entre code annoté et code généré sont bloquées avant fusion.
- **SC-008**: **100 %** des briques Riverpod introduites sont figées à une version exacte, vérifiée à la date d'ouverture du cycle, et **accordées entre les 3 paquets** — **0** désaccord, contrôlé mécaniquement. Le gel passe par le lockfile commité pour les briques que le gestionnaire de paquets résout, et par une version exacte répétée à l'identique pour celle que l'outil d'analyse résout **hors lockfile**. Les **trois** écarts au principe X que la recherche a mis au jour — une prérelease imposée transitivement, un plafond de version, et une brique (les règles d'analyse) que le gestionnaire de paquets ne verrouille pas — sont nommés et justifiés dans le plan (Complexity Tracking), pas contournés.
- **SC-009**: **0** rebuild d'écran déclenché par un rafraîchissement de configuration, application laissée tourner au-delà d'un cycle de rafraîchissement.
- **SC-010**: **0** donnée d'un compte visible sous un autre après déconnexion puis reconnexion, à aucun instant.
- **SC-011**: **0** double injecté par constructeur subsiste dans les tests pour les dépendances d'état ; **0** copie dupliquée de double entre fichiers de test — là où il en existe aujourd'hui 6 du transport et 6 du montage de session.
- **SC-012**: La constitution nomme le pattern : **100 %** des cycles suivants disposent d'une règle opposable, citable en revue, qui tranche le choix de gestion d'état sans discussion.

## Assumptions

- **Prérequis satisfait avant ce cycle** : `docs/user-stories-v2.md` porte TRX-08 (P1) et son tableau §0.6 est à jour (3 P1 pour TRX). Ce n'est pas un livrable du cycle : la constitution impose `docs/` d'abord, puis le `/speckit.specify` — la story précède la spec, jamais l'inverse. US6 n'en contrôle que la non-régression.
- **Le principe IX ne vise pas ce cycle.** IX (« toute fonctionnalité qui n'augmente pas les commandes/jour ou la fiabilité des livraisons est REFUSÉE ») porte sur les **fonctionnalités** : un refactor défini par « aucun changement visible » n'en est pas une — il n'y a rien à reporter. Surtout, IX ne gouverne pas la pratique d'ingénierie : s'il le faisait, il refuserait le principe X (revue mensuelle des versions) et la section « Workflow & portes qualité » de la constitution elle-même, dont aucune n'augmente les commandes/jour. Le précédent est dans le fait, non dans une exégèse : le module TRX porte déjà cinq P0 sans bénéfice utilisateur direct. **Sur IX bullet 3** (« les priorités font foi ») : TRX-08 est un P1 et passe devant des P0 de la tranche T1. C'est délibéré et c'est la seule fenêtre utile — un moule n'a de valeur que s'il précède les cycles qui l'appliquent ; livré après CRS/VND/CMD, il faudrait le repayer sur du code déjà écrit. **Note factuelle, sans valeur de mandat** : `specs/001-socle-monorepo/research.md:40` relève riverpod 3 (3.3.2), avec go_router et drift, comme « **Différés** : aucun état ni navigation ni file offline nécessaires ce cycle […] ; versions notées pour les cycles CPT/CRS […] ». La brique n'est donc pas nouvelle pour le projet, mais rien n'y est tranché — la ligne dit « Différés », et CPT est passé sans. Le mandat du cycle est TRX-08, dans `docs/`.
- **Le décompte de 86 cas de test** (61 cœur, 23 pro, 2 client ; 84 en CI, 2 goldens) est vérifié par exécution sur Flutter 3.44.6, et non estimé — la demande initiale disait « ~80 ». Ce chiffre est un critère de réussite (SC-002) : il vaut à l'ouverture du cycle et se met à jour des tests que le cycle ajoute — unicité de l'intercepteur (FR-013), partage du renouvellement (FR-014), plus le cas-garde de la préservation d'émission (FR-022, verrouillé au portage de `session_auth_test`). Décompte de sortie : **≥ 89** — plancher, aucun des 86 existants n'a disparu ; le nombre exact dépend du découpage en cas de test vs assertions, tranché à l'implémentation.
- **`ServiceConfig` n'est pas un notificateur** : c'est une classe nue, non observée. La demande initiale et la mémoire projet le rangeaient parmi les `ChangeNotifier` ; le projet n'en compte que **deux** (session, rôles). Le périmètre réel est donc plus petit qu'annoncé sur ce point, et plus subtil : le risque n'est pas de le migrer, c'est de l'améliorer en le migrant.
- **Les invariants non couverts sont le vrai risque du cycle**, et ils sont nommés plutôt que découverts en route : le partage du renouvellement entre requêtes concurrentes (couvert par ce cycle, FR-014) ; l'unicité de l'intercepteur (FR-013) ; la non-réactivité de la configuration ; le fait que l'état chargé de la session ne redevient jamais « en cours ». **Les deux méthodes que la migration réécrit pour la configuration ne sont couvertes par aucun test** — aucun test ne passe de configuration, si bien que les deux méthodes sortent immédiatement dans les 86 cas. Ce cycle y avance sans filet, et l'accepte explicitement plutôt que de découvrir la régression sur émulateur.
- **Refactor pur ≠ correction** : la cartographie a relevé des défauts latents préexistants. Ils sont consignés dans le plan et **laissés en l'état** — un refactor qui corrige en passant rend impossible d'attribuer une régression. Une exception nommée : la couche d'injection de test des rôles, prévue mais câblée nulle part, est **supprimée** et non portée (FR-043) — porter du code mort dans le nouveau moule le graverait.
- **La Definition of Done (§0.4) comporte des points vacants pour ce cycle** : aucune API, donc aucun contrat ni client à régénérer ; aucun SQL, donc aucune migration ni `cargo sqlx prepare` ; aucune transition d'état métier, donc aucun événement outbox ; aucun paramètre « paramétrable ». Le point « critères d'acceptation couverts » se réinterprète : un refactor pur ne crée pas de critères nouveaux, il **préserve** les 86 existants — c'est là que « aucun changement visible » se vérifie. Le point « clés i18n externalisées » reste un invariant à ne pas régresser.
- **La constitution ne dit rien du state management** : ses onze principes encadrent l'UI (Material 3 thémé, `.adaptive`, pas de Cupertino) mais pas l'état. La convention actuelle n'est écrite que dans **un commentaire de code** et dans la mémoire projet. L'amendement est donc un **ajout de principe** (incrément mineur, 1.0.1 → 1.1.0), passé par la procédure prévue avec rapport d'impact et propagation aux templates — un livrable du cycle, pas un effet de bord.
- **Trois paquets, trois lockfiles, aucun espace de travail partagé** : les dépendances devront être ajoutées et résolues trois fois, et rien n'oblige mécaniquement les trois lockfiles à s'accorder — d'où l'exigence explicite d'accord (FR-028, SC-008).
- **Chaîne de génération** : le graphe de génération de source est absent des trois paquets Flutter (aucun fichier généré par annotation sous `apps/`) — l'ajout est net. Mais une génération y tourne déjà : celle des traductions, déclarée dans les trois `pubspec.yaml` et rejouée à chaque récupération de dépendances. **Trois** politiques de code généré coexistent donc dans le dépôt : clients Dart **commités et gardés** par un contrôle de dérive ; traductions des deux applications **ignorées** ; traductions du paquet cœur **commitées et gardées par rien** (hors du motif d'exclusion). Ce cycle tranche pour **commité + gardé**, conformément à la demande. **Portée du garde-fou (FR-031), à trancher au plan** : cadré aux seuls artefacts du générateur de providers, le trou des traductions du paquet cœur reste ouvert et est consigné au titre de FR-027 ; étendu à tout `apps/`, il le ferme — mais sa première exécution peut révéler une dérive préexistante, qui est alors une **exception nommée** à FR-027, pas une correction opportuniste.
- **La CI des applications ne vérifie aujourd'hui ni le format ni la dérive** ; le seul modèle de garde-fou anti-dérive existant (contrat/clients) ne couvre pas `apps/`. FR-031 crée ce garde-fou pour les applications.
- **Version de Flutter** : 3.44.6, épinglée en dur dans deux fichiers de CI qui en sont l'unique source de vérité (ni `.fvmrc`, ni gestionnaire de version). La version de Riverpod notée au cycle 001 (3.3.2) date de juillet 2026 et **doit être re-vérifiée à l'ouverture du cycle** (constitution, principe X) plutôt que reprise telle quelle.
- **L'outil qui rend le pattern vérifiable n'est plus celui que la demande nommait** (recherche du 2026-07-17, vérifiée par exécution) : les règles d'analyse dédiées aux providers ne passent plus par le mécanisme de plugin que la demande citait — il est devenu insoluble avec les versions requises — mais par le mécanisme de plugin natif de l'outil d'analyse, déclaré hors du gestionnaire de paquets. Les exigences du cycle sont inchangées : elles portent sur le **résultat** (règles vertes, erreurs bloquantes en échec — FR-032, FR-033), jamais sur l'outil. Conséquences consignées dans le plan : la commande d'analyse de la CI doit changer (celle en place aujourd'hui n'exécute pas les règles de plugin et rend **succès** en leur présence), et le gel de cette brique sort du lockfile (SC-008).
- **Garde-fou de périmètre** : si l'outillage (US1) et le harnais de test partagé (FR-037) dépassent **2 jours de tâches à la planification**, le lot est dégradé — outillage et harnais livrés d'abord, migration des porteurs reportée story par story — plutôt que d'entamer le nœud de session sans filet. Procédé repris du cycle socle.
- **Environnement de validation** : émulateur Android, conformément à la demande. iOS reste non vérifié (chantier hors périmètre) ; le parcours de validation de bout en bout est celui déjà utilisé au cycle précédent (inscription, rôles, dossier, adresses).
