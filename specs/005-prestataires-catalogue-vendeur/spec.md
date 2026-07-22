# Feature Specification: Prestataires agréés et catalogue vendeur

**Feature Branch**: `005-prestataires-catalogue-vendeur`

**Created**: 2026-07-18

**Status**: Draft

**Input**: User description: "Module VND — Vendeurs & catalogue (crate prestataires), docs/user-stories-v2.md + cadrage v5 §5, §6, §11.13. Fonctionnalité : prestataires agréés et catalogue vendeur. Périmètre : VND-01, VND-02, VND-03, VND-04 — critères tels quels. Le crate s'appelle prestataires : agrément, charte, QR (lien vers QRC), sites, notes, score et plan freemium sont portés par le prestataire ; catalogue d'articles et stock vivent dans l'extension vendeur (type de prestataire du MVP). Prix barrés (prix_barré > prix, informatif) ; prix verrouillés à la création de commande ; statut boutique ouvert/fermé/pause avec horaires ; site unique par défaut ; rupture par trois sources (vendeur, coursier sur place avec masquage auto après 2 signalements/7 j, admin), chaque bascule émettant un événement. Hors périmètre : VND-05 (score de fiabilité, P1), VND-08 (livraison offerte, P1, tranche T3), VND-09 (« me prévenir au retour », P1, tranche T4), VND-06/07 (multi-sites et plans = PROVISIONS : tables seulement) ; article à prix variable du marché = P1. Personas : Tantie Affoué, Kofi, Admin. Points d'attention : la suspension d'un prestataire retire la fiche ET révoque le QR immédiatement ; la charte inclut l'acceptation de la retenue à la source ; maquettes de référence : docs/design/png/V1, V2, C2."

## Clarifications

### Session 2026-07-18

- Q: Quelle surface d'interface ce cycle livre-t-il ? Les documents se contredisent — VAP-01/02 (écrans vendeur) sont P1 en tranche T4, mais le placeholder `InterfacePro` de Mefali Pro désigne V1..V3 comme « cibles des cycles CRS et VND ». → A: Capacités serveur PLUS les deux écrans vendeur de Mefali Pro : V1 (statut boutique) et V2 (catalogue & stock), qui remplacent le placeholder. Sans eux, VND-03 « statut boutique » et la source vendeur de VND-04 ne sont démontrables par personne. L'écran admin (A2 / ADM-03) reste au cycle ADM (tranche T3) et les écritures d'administration passent par une API protégée par le rôle admin et journalisée, selon le précédent des cycles 002 et 003 ; la fiche vendeur côté client (C2) reste au cycle CMD ; V3 « commande entrante » (VAP-03) est hors périmètre car il dépend du module commandes.
- Q: Que livre ce cycle sur le QR, alors que le point d'attention exige que « la suspension révoque le QR immédiatement » mais que QRC-01/02/03 forment un module distinct ? → A: Le prestataire PORTE le jeton signé révocable et le code de secours à 4 chiffres, générés à l'agrément, et la validité du jeton DÉRIVE de l'état d'agrément — il n'existe aucune action de révocation séparée qu'on pourrait oublier d'appeler. Ce cycle expose la RÉSOLUTION d'un jeton (à quel prestataire il renvoie, et s'il est valide) pour que la révocation soit observable ; la génération du PDF de plaque, le scan en course, la vérification de distance et le mode dégradé restent au cycle QRC.
- Q: Après un masquage automatique d'article (2 signalements coursier en 7 jours), qui peut le lever et qu'advient-il du compteur ? Les documents disent seulement « levée du signalement coursier ». → A: Le vendeur ou l'Admin peut remettre l'article en vente à tout moment — le vendeur reste maître de son stock. Les signalements déjà reçus restent comptés dans la fenêtre glissante : un signalement coursier supplémentaire re-masque aussitôt. Ni file d'arbitrage manuelle, ni réarmement du compteur qui permettrait de neutraliser indéfiniment le signalement terrain.
- Q: Quand un prestataire est suspendu, que devient le rôle vendeur des comptes rattachés ? Une cascade échouerait : la machine à états du cycle 003 n'autorise `Suspendre` que depuis `valide` et exige un motif — un rôle dans un autre état ferait échouer la suspension entière, puisque tout tient dans la même transaction. → A: AUCUNE cascade. Les capacités vendeur d'un compte DÉRIVENT de l'état du prestataire auquel il est rattaché, exactement comme le jeton de plaque : le rôle du compte ne bouge pas, mais toute action vendeur est refusée tant que le prestataire est suspendu. Un seul état fait foi, rien à rejouer au rétablissement, aucun échec transactionnel possible.
- Q: La réouverture automatique en fin de pause doit-elle émettre un événement ? Une réouverture « sans aucune action » et un événement « dans la même transaction » ne peuvent pas tenir ensemble : un état dérivé à la lecture n'ouvre aucune transaction. → A: L'échéance de pause N'ÉMET AUCUN événement. Seuls les changements DÉCIDÉS en émettent — geste du vendeur, décision Admin. L'événement de mise en pause portant son échéance, la durée réelle de fermeture reste reconstituable a posteriori pour les métriques, sans ordonnanceur et sans contradiction.
- Q: Qui peut signaler une rupture depuis le terrain ? Sans condition, n'importe quel compte porteur du rôle coursier pourrait masquer le catalogue d'un concurrent en deux signalements. → A: Seul un coursier dont la commande active comporte un arrêt chez ce prestataire peut signaler, et seulement sur les articles de cette commande — la précondition que QRC-02 pose déjà pour le scan, et le sens littéral de « coursier sur place » (cadrage §6.4). Le module commandes n'existant pas encore, la condition est exercée par un déclencheur simulé dans les tests, même patron que le verrouillage des prix.
- Q: La consultation de la fiche et du catalogue est-elle ouverte sans authentification ? Le cadrage §3.1 et §5.3 établissent que la fiche est publique, mais ils décrivent WEB-01, hors périmètre — et FR-011 (« tout endpoint protégé par rôle ») l'interdirait en l'état. → A: Publique en lecture seule, limitée au sous-ensemble destiné aux applications — nom, photos, catégorie, statut de boutique, horaires, catalogue avec prix et disponibilité. Le contact téléphonique et les coordonnées exactes du site restent réservés à l'administration. Exception au principe VIII documentée, exactement comme `/config?zone=` au cycle 002 ; la plaque QR reste un canal d'acquisition dès ce cycle.
- Q: Que devient un article retiré du catalogue ? Les documents produit ne le disent nulle part, alors qu'un article retiré reste référencé par les commandes passées et par les métriques. → A: Retrait RÉVERSIBLE. L'article disparaît du catalogue servi et cesse d'être commandable, mais la ligne subsiste : les commandes passées gardent leur référence, les agrégats restent calculables, et le vendeur peut le remettre en vente sans le ressaisir. Patron du cycle 003 pour les adresses (suppression logique, événement dédié). Le retrait et la remise au catalogue émettent chacun un événement.
- Q: Peut-on corriger la catégorie de service ou la ville d'un prestataire déjà agréé, alors que l'une et l'autre déterminent le compteur d'activation de catégorie du cycle 002 ? Aucun document produit n'aborde leur modification après agrément. → A: Oui, l'Admin peut les corriger à tout moment ; la modification recalcule le compteur de l'ANCIEN couple catégorie/ville et celui du NOUVEAU dans la même transaction, et émet un événement. Une faute de saisie relevée sur le terrain se corrige sans suspendre puis ré-agréer le prestataire — ce qui lui coûterait sa plaque et son historique.
- Q: Quelle valeur seed pour la durée de conservation de la charte après la fin de la relation, sachant que ce paramètre ne figure pas encore au « Récapitulatif des paramètres de zone » ? → A: 5 ans — ordre de grandeur de la prescription commerciale usuelle, qui couvre un litige tardif sur l'acceptation de la retenue à la source sans conserver indéfiniment une signature manuscrite. Paramètre de zone, éditable sans code ; à inscrire au Récapitulatif avec le mode d'affichage des articles en rupture.
- Q: Combien de temps conserve-t-on la charte signée et les photos, alors que le principe VIII exige une rétention limitée des photos ? → A: À la durée de vie de l'objet porté. Les photos de fiche et d'articles vivent tant que la fiche ou l'article existe et sont purgées à leur suppression — ce sont des photos de plats et d'étals, pas des données personnelles. La charte signée, qui porte une signature manuscrite, est conservée comme pièce contractuelle tant que la relation dure, avec une durée post-relation paramétrable par zone dont la valeur seed est de 5 ans — ordre de grandeur de la prescription commerciale usuelle, éditable sans code. Aucune purge périodique à construire.

## User Scenarios & Testing *(mandatory)*

Personas de ce cycle : **Tantie Affoué (vendeuse)** — maquis au marché, pas d'app, peu lettrée, veut son argent immédiatement ; **Kofi (vendeur équipé)** — boutique, smartphone, installera Mefali Pro, fera des promos ; **Admin (toi)** — fondateur, seul au lancement, agrée les prestataires sur le terrain.

Priorités produit : les quatre stories VND-01 → VND-04 sont toutes **P0** dans `docs/user-stories-v2.md` (VND-01/02/03 en tranche T1, VND-04 en tranche T2). Les priorités P1→P5 ci-dessous sont l'ordre de livraison interne au cycle (dépendances), pas une hiérarchie produit. VND-05, VND-08 et VND-09 (P1 produit) sont hors périmètre ; VND-06 et VND-07 sont des PROVISIONS — tables uniquement.

Surface utilisateur de ce cycle : les deux écrans de la maquette V1 (statut boutique) et V2 (catalogue & stock) sont construits dans **Mefali Pro**, où ils remplacent l'interface vendeur aujourd'hui réduite à un placeholder. Côté Admin, comme aux cycles 002 et 003, aucun écran n'est construit avant le cycle ADM (tranche T3) : l'agrément, la fiche, la charte, le catalogue et la suspension sont exposés en API, protégés par le rôle admin et journalisés (qui, quand, avant/après). La consultation de la fiche et du catalogue est exposée en API par ce cycle — c'est elle qui rend observable tout ce que les stories promettent — mais AUCUN écran client n'est construit : la fiche vendeur de l'application cliente (maquette C2) reste au cycle CMD et la fiche publique web au cycle WEB. L'écran depuis lequel un coursier signale une rupture appartient au cycle CRS ; ce cycle en livre la capacité et sa protection.

Le vendeur est la **spécialisation MVP** du prestataire : l'agrément, la charte, l'identité de plaque, les sites et le plan sont portés par le prestataire ; le catalogue d'articles et le stock vivent dans l'extension vendeur. Aucune règle de ce cycle ne suppose que tout prestataire est un vendeur.

### User Story 1 - Agréer un prestataire et lui donner son identité de plaque (VND-01, Priority: P1 — produit : P0)

L'Admin visite le maquis de Tantie Affoué, remplit la grille d'agrément, lui fait signer la charte qualité — hygiène, prix identiques sur place et sur Mefali, délais, joignabilité, et acceptation de la retenue à la source — puis en scanne l'exemplaire signé. Il crée la fiche : nom, catégorie, photos, contact, délai de préparation moyen, et le site unique qui porte la position GPS relevée sur place et les horaires d'ouverture. À l'agrément, le prestataire reçoit son identité de plaque — un jeton signé révocable et un code de secours à quatre chiffres — et devient consultable et commandable. Tantie Affoué n'a ni smartphone ni compte : cela ne l'empêche en rien d'être agréée.

**Why this priority**: Rien n'existe sans elle — ni catalogue, ni statut de boutique, ni rupture. C'est aussi la story qui alimente le compteur de vendeurs agréés dont dépend l'activation des catégories par ville, livrée au cycle 002 et restée sans appelant depuis.

**Independent Test**: Agréer un prestataire complet de bout en bout — fiche, charte scannée, site avec position et horaires, catégorie — puis vérifier par la consultation exposée qu'il est commandable, que son identité de plaque se résout, que l'activation de sa catégorie dans sa ville a été recalculée, et que chaque transition a laissé un événement métier ; le tout sans qu'aucun compte utilisateur ne soit rattaché et sans qu'aucune autre story de ce cycle ne soit livrée.

**Acceptance Scenarios**:

1. **Given** un prestataire à l'état prospect, doté d'une fiche complète, d'un site avec position et horaires, et d'une charte signée déposée, **When** l'Admin l'agrée, **Then** son statut passe à « agréé », son jeton de plaque et son code de secours à quatre chiffres sont créés, et la transition émet un événement métier dans la même transaction.
2. **Given** un prestataire agréé dont la catégorie est active dans sa ville et dont la boutique est ouverte, **When** un client consulte la fiche, **Then** elle est servie avec son catalogue et le prestataire est commandable.
3. **Given** un prestataire à l'état prospect dont la charte signée n'a pas été déposée, ou dépourvu de site, **When** l'Admin tente de l'agréer, **Then** l'agrément est refusé avec un motif explicite et le statut reste « prospect ».
4. **Given** une catégorie comptant seuil − 1 prestataires agréés dans une ville, **When** l'Admin y agrée un prestataire supplémentaire de cette catégorie, **Then** le nombre de prestataires agréés est recalculé et la catégorie s'active dans cette ville sans action manuelle.
5. **Given** Tantie Affoué, agréée et sans aucun compte utilisateur rattaché, **When** un client consulte le catalogue de sa ville, **Then** sa fiche et ses articles sont disponibles exactement comme ceux d'un vendeur équipé.
6. **Given** Kofi, agréé, qui installe Mefali Pro, **When** l'Admin rattache le compte vérifié de Kofi à son prestataire, **Then** le rôle vendeur lui est attribué et vaut validation immédiate — aucune demande in-app n'est requise — et Kofi ne peut piloter que ce prestataire.

---

### User Story 2 - Tenir le catalogue et ses prix (VND-02, Priority: P2 — produit : P0)

L'Admin saisit le catalogue de Tantie Affoué pendant la visite d'agrément : attiéké poisson 1 500, garba 1 000, jus de bissap 500. Kofi, lui, gère le sien depuis Mefali Pro : il ajoute un article, puis passe l'alloco de 1 000 à 800 en promotion, l'ancien prix restant barré sur la fiche. Quand Awa commande, le prix retenu est celui affiché au moment de sa commande — une promotion qui se termine dix minutes plus tard ne change rien à ce qu'elle paiera.

**Why this priority**: Un vendeur agréé sans catalogue ne génère aucune commande. Dépend de la story 1 : un article appartient à l'extension vendeur d'un prestataire.

**Independent Test**: Créer des articles avec et sans prix barré, depuis l'API d'administration et depuis la surface vendeur, vérifier qu'un prix barré inférieur ou égal au prix courant est refusé, qu'un montant est toujours un entier accompagné du code de devise de la zone, puis figer un prix par le déclencheur simulé de verrouillage, modifier le prix courant, et constater que le montant figé n'a pas bougé.

**Acceptance Scenarios**:

1. **Given** un prestataire agréé, **When** l'Admin ou le vendeur crée un article avec nom, prix, photo et catégorie interne, **Then** l'article apparaît au catalogue, disponible par défaut.
2. **Given** un article à 800 FCFA, **When** on lui associe un prix barré de 1 000 FCFA, **Then** l'article est marqué en promotion et les deux montants sont exposés — le prix barré étant purement informatif.
3. **Given** un article à 800 FCFA, **When** on tente d'y associer un prix barré de 800 ou de 700 FCFA, **Then** l'opération est refusée : le prix barré DOIT être strictement supérieur au prix courant.
4. **Given** un prix courant figé pour un article, **When** le vendeur modifie ensuite ce prix, **Then** le montant figé reste inchangé et la modification ne vaut que pour les verrouillages suivants.
5. **Given** un article dont on saisit un montant, **When** le montant est enregistré, **Then** il l'est en unités mineures entières accompagnées du code de devise de la zone — aucun montant n'est jamais représenté par un nombre à virgule.

---

### User Story 3 - Ouvrir, fermer et mettre la boutique en pause (VND-03, Priority: P3 — produit : P0)

Tantie Affoué part au marché s'approvisionner : d'un geste, elle met sa boutique en pause pour une heure, et la boutique se rouvre toute seule à son retour — elle n'a rien à se rappeler. Ses horaires habituels sont 8 h — 19 h du lundi au samedi : à 20 h, sa fiche est fermée même si elle a oublié de basculer l'interrupteur. Un matin où elle a fermé par erreur, l'app le lui signale doucement : « il est 10 h 15, d'habitude votre boutique est ouverte à cette heure. »

**Why this priority**: Une boutique qui reçoit une commande alors qu'elle est fermée produit une course perdue, un client déçu et un coursier non payé — c'est la première cause d'échec évitable. Dépend de la story 1 : le statut et les horaires sont portés par le site du prestataire.

**Independent Test**: Faire basculer un prestataire par chacun des chemins — interrupteur manuel, sortie des horaires, pause temporisée arrivée à échéance, prolongation, fermeture pour la journée, modification des horaires — et vérifier à chaque fois, par la consultation exposée, l'état effectif de la boutique, la commandabilité du prestataire, et l'émission ou l'absence d'événement selon l'origine du changement.

**Acceptance Scenarios**:

1. **Given** une boutique ouverte pendant ses horaires, **When** le vendeur la met en pause pour une durée proposée, **Then** elle devient fermée immédiatement, l'heure de réouverture est annoncée, un événement métier est émis, et elle se rouvre automatiquement à échéance sans aucune action ni aucun nouvel événement.
2. **Given** une boutique en pause, **When** le vendeur prolonge la pause ou choisit de fermer pour la journée, **Then** l'échéance est repoussée ou la boutique reste fermée jusqu'au prochain jour d'ouverture, sans que le vendeur ait à revenir la rouvrir.
3. **Given** une boutique dont l'interrupteur est sur « ouvert » mais dont l'heure courante est hors des horaires du jour, **When** un client consulte la fiche, **Then** la boutique est présentée comme fermée et le prestataire n'est pas commandable.
4. **Given** une boutique fermée, **When** un client consulte sa fiche, **Then** le catalogue reste consultable en lecture seule, les horaires et l'heure de réouverture sont servis, et le prestataire n'est pas commandable.
5. **Given** une boutique fermée manuellement alors que l'heure courante tombe dans ses horaires habituels, **When** le vendeur ouvre l'écran de statut, **Then** un rappel non bloquant le lui signale, avec une action pour ouvrir et une sortie pour rester fermé.
6. **Given** des horaires à corriger, **When** le vendeur ou l'Admin les modifie, **Then** les nouveaux horaires s'appliquent immédiatement à l'état effectif et la modification émet un événement métier.

---

### User Story 4 - Suspendre un prestataire coupe tout, immédiatement (VND-01, Priority: P4 — produit : P0)

Trois incidents graves sur le même maquis : l'Admin le suspend. Dans la seconde, sa fiche n'est plus servie, plus aucune commande ne peut le viser, la plaque QR posée sur son mur ne vaut plus rien, et Kofi — s'il s'agissait de sa boutique — ne peut plus rien piloter depuis Mefali Pro. La plaque physique n'a pas à être retirée ni remplacée. Quand la situation est réglée, l'Admin rétablit : tout revient, avec la même plaque.

**Why this priority**: C'est la seule garantie qui protège la marque « Vendeur agréé Mefali ». Elle doit être immédiate et sans action manuelle oubliable. Dépend des stories 1 à 3 : elle éteint tout ce qu'elles ont allumé.

**Independent Test**: Suspendre un prestataire agréé et vérifier, sans redémarrage ni délai, que sa fiche n'est plus servie, qu'il n'est plus commandable, que la résolution de son jeton de plaque le déclare invalide, et qu'un compte rattaché porteur du rôle vendeur se voit refuser toute action sur lui — puis rétablir et constater le retour à l'identique, jeton et code de secours inchangés.

**Acceptance Scenarios**:

1. **Given** un prestataire agréé et commandable, **When** l'Admin le suspend avec motif, **Then** sa fiche cesse d'être servie, il cesse d'être commandable, et la résolution de son jeton de plaque le déclare invalide — sans aucune action de révocation distincte.
2. **Given** un prestataire suspendu, **When** un client atteint sa fiche par un lien direct, **Then** il obtient une réponse neutre indiquant l'indisponibilité, sans photo et sans motif de suspension.
3. **Given** un prestataire suspendu auquel un compte porteur du rôle vendeur est rattaché, **When** ce compte tente une action vendeur — statut de boutique, prix, disponibilité — **Then** elle est refusée tant que dure la suspension, sans que le rôle vendeur du compte ait été modifié.
4. **Given** un prestataire suspendu, **When** l'Admin le rétablit, **Then** il redevient agréé, redevient commandable dès lors que sa catégorie est active et sa boutique ouverte, son jeton et son code de secours retrouvent leur validité sans changement de valeur, et le compteur de prestataires agréés de sa catégorie est recalculé.
5. **Given** toute suspension ou rétablissement, **When** la décision est prise, **Then** un motif est exigé pour la suspension, la décision est journalisée avec son auteur et son horodatage, et un événement métier est émis dans la même transaction.

---

### User Story 5 - Signaler une rupture par trois chemins (VND-04, Priority: P5 — produit : P0)

Le garba de Tantie Affoué est épuisé à 14 h. Trois chemins mènent au même résultat : elle bascule l'article d'un geste depuis Mefali Pro ; ou bien Yao, venu collecter une commande chez elle, signale l'article introuvable — et au deuxième signalement de ce genre en une semaine, l'article se masque tout seul ; ou bien l'Admin le fait depuis la console. Côté client, l'article apparaît grisé ou disparaît selon ce que la catégorie prévoit. Chaque bascule laisse une trace : c'est elle qui, plus tard, préviendra les clients abonnés au retour en stock.

**Why this priority**: Un article vendu puis introuvable produit une substitution, un appel, parfois un litige. C'est la story de la tranche T2 du cycle — le produit est lançable sans elle, mais elle assainit le catalogue. Dépend de la story 2 : la disponibilité porte sur un article d'un site.

**Independent Test**: Basculer un même article en rupture puis en vente par chacune des trois sources, vérifier que la source et l'auteur sont tracés à chaque fois, provoquer deux signalements de coursiers distincts dans la fenêtre — chacun sous la précondition de commande active simulée — pour déclencher le masquage automatique, le lever côté vendeur, puis constater qu'un signalement suivant re-masque immédiatement, et qu'un coursier sans commande active chez ce prestataire est refusé.

**Acceptance Scenarios**:

1. **Given** un article en vente, **When** le vendeur le bascule en rupture depuis Mefali Pro, **Then** il devient indisponible immédiatement, la source « vendeur » et l'auteur sont tracés, et un événement métier est émis.
2. **Given** un article en vente et un seuil de deux signalements sur sept jours, **When** deux coursiers distincts, chacun porteur d'une commande active comportant un arrêt chez ce prestataire, le signalent introuvable, **Then** l'article est masqué automatiquement, la source « coursier » est tracée, et un événement métier est émis.
3. **Given** un coursier dont la commande active ne comporte aucun arrêt chez ce prestataire, ou qui ne porte aucune commande active, **When** il tente de signaler un article, **Then** le signalement est refusé et n'est compté nulle part.
4. **Given** un article masqué automatiquement, **When** le vendeur ou l'Admin le remet en vente, **Then** il redevient disponible immédiatement, un événement de retour en stock est émis, et les signalements déjà reçus restent comptés dans leur fenêtre.
5. **Given** un article remis en vente dont la fenêtre porte encore le seuil de coursiers distincts, **When** un coursier éligible le signale à nouveau, **Then** l'article est masqué de nouveau sans attendre d'autres signalements.
6. **Given** un article en rupture, **When** un client consulte le catalogue, **Then** l'article est servi grisé ou absent selon ce que la configuration de sa catégorie prévoit, et il n'est pas commandable.
7. **Given** des signalements sortis de la fenêtre glissante, **When** le seuil est réévalué, **Then** ils ne comptent plus — seuls les signalements de la fenêtre déclenchent un masquage.

---

### Edge Cases

- **Prestataire agréé dans une catégorie inactive dans sa ville** : la fiche existe et reste administrable, mais elle n'est ni servie ni commandable tant que la catégorie n'est pas active dans cette ville (ZON-03) — l'activation est ce que l'agrément fait justement basculer quand le seuil est atteint.
- **Suspension d'un prestataire qui fait repasser sa catégorie sous le seuil** : la catégorie reste active. Le seuil ne joue qu'à la hausse (précédent du cycle 002) — le recalcul de FR-009 est donc sans effet à la baisse, et c'est voulu.
- **Correction de catégorie qui fait passer l'ancienne sous son seuil** : l'ancienne catégorie reste active dans la ville — la règle de seuil ne joue qu'à la hausse, et le recalcul de FR-056 n'y change rien. Seul le forçage Admin ferme une catégorie (précédent du cycle 002).
- **Prestataire rattaché à une zone plus fine qu'une ville** : refusé. Le rattachement se fait à une zone de type ville, seule granularité que l'activation de catégorie sait lire (FR-002).
- **Prestataire sans aucun compte rattaché** : c'est le cas nominal de Tantie Affoué — agrément, catalogue, statut de boutique et ruptures sont pilotés par l'Admin via l'API. Aucune capacité n'exige un compte.
- **Plusieurs comptes rattachés au même prestataire** : accepté (le patron et son gérant) ; chacun porte le rôle vendeur et agit sur le même prestataire, chaque action restant attribuée à son auteur.
- **Compte porteur du rôle vendeur rattaché à aucun prestataire, ou visant un autre prestataire** : toute action vendeur est refusée. Le rôle seul n'autorise rien — c'est le rattachement qui délimite (FR-011).
- **Un compte rattaché est suspendu au niveau du compte** : cela n'affecte pas le prestataire, qui reste agréé et commandable. Les deux cycles de vie sont distincts, et la dérivation ne va que du prestataire vers le compte.
- **Article dont le prix barré devient invalide** : baisser le prix courant en dessous du prix barré reste valide ; le porter au-dessus ou à égalité est refusé, l'opération échouant plutôt que de retirer silencieusement la promotion.
- **Pause dont l'échéance tombe hors des horaires d'ouverture** : la boutique ne rouvre pas — l'échéance lève la pause, elle ne force jamais l'ouverture contre les horaires, et n'émet aucun événement.
- **Changement d'horaires pendant une pause en cours** : la pause continue de courir jusqu'à son échéance ; les nouveaux horaires s'appliquent ensuite.
- **Deux signalements du même coursier sur le même article** : ils comptent pour un seul. Le seuil porte sur des coursiers distincts, sans quoi un seul signaleur suffirait à masquer n'importe quel article.
- **Signalement coursier sur un article déjà en rupture** : il est enregistré et compté dans la fenêtre, sans changement d'état — c'est ce qui permet au re-masquage de la story 5 de fonctionner après une remise en vente.
- **Article mis en rupture par l'Admin** : seul l'Admin peut le remettre en vente. Une bascule d'Admin arbitre un litige ou une non-conformité ; laisser le vendeur la lever la viderait de son sens — contrairement au masquage automatique, que le vendeur peut lever (FR-041).
- **Rejeu d'un signalement coursier déjà reçu** : sans effet — même identifiant client, même résultat, aucun double comptage (FR-039).
- **Article retiré du catalogue puis remis** : il revient avec son historique et sa disponibilité telle qu'elle était ; les signalements de rupture reçus avant le retrait restent comptés s'ils sont encore dans la fenêtre. Un article retiré n'est ni servi ni commandable, et aucun signalement ne peut le viser (FR-055).
- **Site unique et multi-sites** : le modèle porte n sites par prestataire et rattache stock et horaires au site, un seul site est créé à l'agrément et aucune sélection de site n'est proposée nulle part (provision VND-06).
- **Plan freemium** : tous les prestataires portent le plan « Gratuit » ; aucune règle ne lit ni n'écrit ce plan au MVP (provision VND-07).

## Requirements *(mandatory)*

### Functional Requirements

#### Prestataire, agrément et cycle de vie (VND-01)

- **FR-001**: Le modèle DOIT traiter le prestataire comme l'entité générale — agrément, charte, identité de plaque, sites, plan — et le vendeur comme une extension portant catalogue et stock. AUCUNE règle de ce cycle NE DOIT supposer que tout prestataire est un vendeur (constitution, principe II).
- **FR-002**: La fiche d'un prestataire DOIT porter : nom, catégorie de service, zone de rattachement, photos, contact téléphonique et délai de préparation moyen déclaré. La zone de rattachement DOIT être de type ville — seule granularité que l'activation de catégorie sait lire (ZON-03) ; toute autre profondeur est REFUSÉE. La position GPS et les horaires ne sont PAS portés par la fiche mais par le site (FR-018).
- **FR-003**: Le système DOIT conserver la charte signée sous forme de document scanné dans un stockage objet sécurisé à accès restreint, accompagnée de la version de charte en vigueur au moment de la signature et de sa date de signature. La charte inclut l'acceptation de la retenue à la source ; l'agrément DOIT être refusé tant qu'elle n'est pas déposée. Un changement de version de charte NE DOIT PAS invalider les agréments existants.
- **FR-004**: Le prestataire DOIT porter un statut parmi {prospect, agréé, suspendu}, dont les SEULES transitions autorisées sont prospect → agréé, agréé → suspendu et suspendu → agréé. Toute autre transition est REFUSÉE. SEUL l'état « agréé » rend la fiche servie et le prestataire commandable.
- **FR-005**: L'agrément DOIT être refusé tant que le prestataire ne porte pas une fiche complète (FR-002), une charte signée (FR-003) et exactement un site doté d'une position GPS et d'horaires (FR-018, FR-019).
- **FR-006**: Un prestataire DOIT pouvoir exister, être agréé et recevoir des commandes sans qu'AUCUN compte utilisateur ne lui soit rattaché ; le rattachement de comptes est optionnel et multiple (0..n).
- **FR-007**: Le rattachement d'un compte vérifié à un prestataire agréé DOIT attribuer à ce compte le rôle vendeur — l'agrément VAUT validation, aucune demande in-app n'existe pour ce rôle (cadrage §5.1). Le rattachement DOIT être idempotent : rattacher un compte qui porte déjà le rôle vendeur au titre d'un autre prestataire NE DOIT PAS échouer ni rejouer l'attribution.
- **FR-008**: Les capacités vendeur d'un compte DOIVENT DÉRIVER de l'état du prestataire auquel il est rattaché : toute action vendeur est REFUSÉE tant que ce prestataire n'est pas agréé. AUCUNE cascade NE DOIT modifier le statut du rôle vendeur du compte lors d'une suspension ou d'un rétablissement — un seul état fait foi.
- **FR-009**: L'agrément et le rétablissement d'un prestataire DOIVENT déclencher le recalcul du nombre de prestataires agréés de sa catégorie dans sa ville, alimentant l'activation de catégorie par seuil livrée au cycle 002 (ZON-03). La suspension DOIT le déclencher aussi, sans effet attendu : la règle de seuil ne joue qu'à la hausse.
- **FR-056**: L'Admin DOIT pouvoir corriger la catégorie de service et la ville de rattachement d'un prestataire agréé. Une telle correction DOIT recalculer, dans la même transaction, le compteur de prestataires agréés de l'ANCIEN couple catégorie/ville ET celui du NOUVEAU, et émettre un événement métier. Corriger ces champs NE DOIT exiger ni suspension, ni ré-agrément, ni changement d'identité de plaque.
- **FR-010**: Toute transition du cycle de vie d'un prestataire — agrément, suspension, rétablissement — DOIT être journalisée (qui, quand, motif) et émettre un événement métier dans la MÊME transaction que la transition (constitution, principe VI). Un motif est REQUIS pour la suspension.
- **FR-011**: Toute capacité d'écriture de ce cycle DOIT être protégée par rôle (constitution, principe VIII). Un compte porteur du rôle vendeur NE DOIT pouvoir lire et piloter QUE les prestataires auxquels il est rattaché ; les capacités d'administration exigent le rôle admin ; la capacité de signalement de rupture exige le rôle coursier et la précondition de FR-038. SEULE la consultation publique de FR-027 échappe à cette règle, dans les limites qu'elle fixe — exception au principe VIII documentée, au même titre que la configuration distante du cycle 002.
- **FR-012**: L'Admin DOIT pouvoir créer, modifier, agréer, suspendre et rétablir un prestataire, rattacher et détacher un compte, gérer les sites, les horaires, le statut de boutique, le catalogue et la disponibilité des articles, via l'API d'administration de ce cycle — protégée par le rôle admin et journalisée ; les écrans arrivent au cycle ADM (tranche T3).

#### Identité de plaque (lien vers QRC)

- **FR-013**: Le prestataire DOIT porter, dès son agrément, une identité de plaque : un jeton signé révocable et un code de secours à quatre chiffres.
- **FR-014**: Le code de secours DOIT être tiré aléatoirement à l'agrément et rester stable ensuite. Il N'EST PAS un identifiant global : il est destiné à être comparé localement à celui du prestataire attendu (QRC-04). AUCUNE recherche de prestataire par ce code NE DOIT être exposée, et son unicité n'est requise à AUCUNE échelle.
- **FR-015**: La validité du jeton DOIT DÉRIVER de l'état d'agrément du prestataire — il N'EXISTE AUCUNE action de révocation distincte. Une suspension rend le jeton invalide immédiatement ; un rétablissement lui rend sa validité sans changer sa valeur, la plaque physique restant en place.
- **FR-016**: Le système DOIT exposer la résolution d'un jeton de plaque : à un jeton présenté, il répond le prestataire correspondant et sa validité courante. Les parcours qui la consomment — scan en course, préconditions de commande, distance, photo, mode dégradé — appartiennent au cycle QRC.
- **FR-017**: Une réponse concernant un prestataire suspendu NE DOIT révéler ni ses photos, ni le motif de sa suspension — seulement son indisponibilité.

#### Sites (VND-03) et provision multi-sites (VND-06)

- **FR-018**: Le modèle DOIT relier un prestataire à ses sites (1..n) ; la position GPS, les horaires, le statut de boutique et la disponibilité des articles sont rattachés au SITE, jamais au prestataire.
- **FR-019**: Exactement UN site DOIT être créé à l'agrément, doté d'une position GPS, d'horaires hebdomadaires et d'un statut de boutique initial. AUCUNE sélection de site NE DOIT être proposée nulle part : le multi-sites est une PROVISION — le modèle l'accueille sans migration future, sans aucune UI ni logique dédiée au MVP (constitution, principe IX).

#### Catalogue et prix (VND-02)

- **FR-020**: Un article DOIT porter : nom, prix, prix barré optionnel, photo optionnelle, disponibilité et catégorie interne au catalogue du vendeur ; il appartient à l'extension vendeur d'un prestataire.
- **FR-021**: La catégorie interne DOIT être une étiquette libre propre au catalogue de chaque vendeur, facultative, servant uniquement à regrouper les articles à l'affichage — elle n'est PAS le référentiel de catégories de service des zones et n'est lue par aucune règle.
- **FR-055**: Le retrait d'un article du catalogue DOIT être RÉVERSIBLE : l'article cesse d'être servi et d'être commandable, mais sa ligne subsiste pour que les commandes passées gardent leur référence et que les agrégats restent calculables. Le vendeur ou l'Admin DOIT pouvoir le remettre au catalogue sans le ressaisir. Le retrait et la remise émettent chacun un événement métier dans la même transaction. Un article retiré NE DOIT PAS être confondu avec un article en rupture : la rupture est temporaire et porte sur le stock d'un site, le retrait porte sur le catalogue du vendeur.
- **FR-022**: Tout montant DOIT être un entier en unités mineures accompagné du code de devise porté par la zone. AUCUN montant NE DOIT être représenté par un nombre à virgule (constitution, principe III).
- **FR-023**: Le prix barré DOIT être strictement supérieur au prix courant ; toute tentative contraire est REFUSÉE. Le prix barré est purement informatif : le montant retenu est TOUJOURS le prix courant.
- **FR-024**: Le système DOIT permettre de figer le prix courant d'un article, de sorte qu'une modification ultérieure du prix NE DOIT affecter AUCUN montant déjà figé (constitution, principe III). La création de commande qui exercera ce verrouillage appartient au module commandes (CMD-03).
- **FR-025**: Les photos d'articles et de fiches DOIVENT être conservées dans un stockage objet sécurisé à accès restreint, jamais servies directement depuis un emplacement public.
- **FR-026**: Les photos DOIVENT être purgées à la suppression de la fiche ou de l'article qu'elles portent. La charte signée DOIT être conservée tant que dure la relation avec le prestataire, puis pendant une durée post-relation paramétrable par zone, dont la valeur seed est de 5 ans (constitution, principe VIII — minimisation ARTCI). AUCUNE purge périodique n'est requise pour les photos.

#### Consultation de la fiche et du catalogue

- **FR-027**: Le système DOIT exposer la consultation de la fiche d'un prestataire et de son catalogue, en lecture seule et SANS authentification — la plaque est un canal d'acquisition (cadrage §3.1, §5.3). Cette consultation DOIT être limitée au sous-ensemble destiné aux applications : nom, photos, catégorie, statut de boutique, horaires, catalogue avec prix et disponibilité. Elle NE DOIT servir ni le contact téléphonique, ni les coordonnées exactes du site, ni aucune donnée d'exploitation, qui exigent le rôle admin. C'est cette capacité qui rend observables les états définis par ce cycle ; AUCUN écran client ne l'accompagne (cycles CMD et WEB).
- **FR-028**: Le système DOIT exposer, pour tout prestataire, un état de disponibilité commerciale dit « commandable », VRAI si et seulement si le prestataire est agréé, que sa catégorie est active dans sa ville, et que l'état effectif de sa boutique est ouvert. Cet état est la SEULE définition de « commandable » ; les modules ultérieurs s'y réfèrent sans la redupliquer.
- **FR-029**: La consultation d'un prestataire dont la boutique est fermée DOIT servir le catalogue en lecture seule ainsi que les horaires et, s'il y a lieu, l'heure de réouverture ; la consultation d'un prestataire non agréé NE DOIT servir que son indisponibilité (FR-017).

#### Statut de boutique et horaires (VND-03)

- **FR-030**: Le site DOIT porter un statut de boutique parmi {ouvert, fermé, fermé pour la journée, en pause}, et des horaires d'ouverture hebdomadaires. « Fermé pour la journée » DOIT cesser de produire effet au prochain jour d'ouverture, sans que le vendeur ait à revenir rouvrir.
- **FR-031**: Les horaires DOIVENT admettre plusieurs plages par jour et des jours sans aucune plage (jour de fermeture).
- **FR-032**: L'état effectif d'une boutique DOIT se déduire, dans cet ordre, de l'état d'agrément du prestataire, des horaires du jour, du statut de boutique et de l'échéance de pause éventuelle. Hors horaires, la boutique est FERMÉE quel que soit son statut. Une boutique en pause est fermée jusqu'à l'échéance.
- **FR-033**: La pause DOIT être temporisée : le vendeur choisit une durée parmi celles proposées, la boutique rouvre automatiquement à échéance sans aucune action, et le vendeur PEUT prolonger la pause ou basculer en « fermé pour la journée ». L'échéance lève la pause mais NE DOIT jamais forcer l'ouverture contre les horaires.
- **FR-034**: Le vendeur et l'Admin DOIVENT pouvoir modifier les horaires hebdomadaires d'un site ; les nouveaux horaires s'appliquent immédiatement à l'état effectif.
- **FR-035**: Lorsqu'une boutique est fermée manuellement alors que l'heure courante tombe dans ses horaires habituels, l'application vendeur DOIT afficher un rappel NON bloquant à l'ouverture de l'écran de statut, offrant d'ouvrir ou de rester fermé. Le rappel NE DOIT PAS être réaffiché tant que le vendeur a choisi de rester fermé pour la journée en cours.
- **FR-036**: Tout changement DÉCIDÉ de statut de boutique ou d'horaires — geste du vendeur, décision Admin — DOIT émettre un événement métier dans la même transaction (constitution, principe VI). L'échéance de pause N'ÉMET AUCUN événement : elle ne décide rien et n'ouvre aucune transaction ; l'événement de mise en pause porte son échéance, ce qui suffit à reconstituer la durée de fermeture.

#### Rupture — trois sources (VND-04)

- **FR-037**: La disponibilité d'un article sur un site DOIT pouvoir être basculée par TROIS sources : le vendeur, le coursier sur place, l'Admin. La source ET l'auteur de chaque bascule DOIVENT être tracés.
- **FR-038**: Un signalement de rupture par un coursier DOIT être REFUSÉ à moins que sa commande active ne comporte un arrêt chez ce prestataire et que l'article signalé n'appartienne à cette commande (précondition alignée sur QRC-02).
- **FR-039**: Tout signalement de rupture émis depuis l'application coursier DOIT porter un identifiant unique généré côté client et un horodatage local, DOIT pouvoir attendre dans une file locale hors réseau, et son rejeu DOIT être idempotent — un même identifiant ne compte jamais deux fois (constitution, principe V).
- **FR-040**: Un nombre paramétrable de signalements, émanant de coursiers DISTINCTS et reçus dans une fenêtre glissante paramétrable, DOIT masquer l'article automatiquement (défaut : 2 signalements en 7 jours). Les signalements sortis de la fenêtre ne comptent plus.
- **FR-041**: Le vendeur ou l'Admin DOIT pouvoir remettre en vente, à tout moment, un article masqué automatiquement ; les signalements déjà reçus RESTENT comptés dans leur fenêtre, de sorte que tout signalement éligible ultérieur re-masque immédiatement l'article tant que la fenêtre porte le seuil. Un article mis en rupture par l'Admin NE DOIT être remis en vente que par l'Admin.
- **FR-042**: Un article en rupture DOIT être servi grisé ou absent selon ce que la configuration de sa catégorie prévoit dans la zone, et NE DOIT être commandable dans aucun cas.
- **FR-043**: Chaque bascule de disponibilité — mise en rupture comme retour en vente — DOIT émettre un événement métier dans la même transaction, quelle qu'en soit la source. Ces événements sont ceux que VND-09 consommera pour prévenir les clients abonnés (tranche T4).

#### Surface vendeur — Mefali Pro (maquettes V1 et V2)

- **FR-044**: Mefali Pro DOIT offrir au vendeur un écran de statut de boutique (maquette V1) où ouvrir, fermer et mettre en pause se font en UN geste, avec l'échéance de réouverture, les horaires du jour, l'accès à leur modification (FR-034) et le rappel non bloquant de FR-035.
- **FR-045**: Mefali Pro DOIT offrir au vendeur un écran de catalogue et de stock (maquette V2) permettant de basculer la disponibilité d'un article en un geste, de rechercher un article, d'ajouter un article et de le retirer du catalogue (FR-055), et d'éditer son prix et son prix promotionnel avec un aperçu de ce que le client verra.
- **FR-046**: Ces écrans DOIVENT remplacer le contenu vendeur de l'interface Mefali Pro, aujourd'hui réduit à un placeholder, sans altérer le comportement de la porte des rôles, du routeur, du sélecteur de rôles ni du pied de page livrés au cycle 003.
- **FR-047**: L'état de ces écrans DOIT être porté selon le moule Riverpod codegen du projet (constitution, principe XII), et toute chaîne affichée DOIT être une clé i18n fr.

#### Provision — plans freemium (VND-07, hors périmètre)

- **FR-048**: Le modèle DOIT comporter les plans et leurs caractéristiques — tables UNIQUEMENT : aucune UI, AUCUNE logique ne lit ni n'écrit ce plan au MVP, et aucun comportement du produit n'en dépend (constitution, principe IX).

#### Transverse

- **FR-049**: Toute chaîne visible par l'utilisateur DOIT être une clé i18n fr ; tout paramètre qualifié de paramétrable — seuil et fenêtre de masquage automatique après signalements coursier, mode d'affichage des articles en rupture par catégorie, durée de conservation post-relation de la charte — DOIT vivre dans la configuration de zone (héritage ZON-01), jamais en dur (constitution, principes I et VII).
- **FR-050**: Le mode d'affichage des articles en rupture DOIT être lisible par les applications ; s'il ne l'est pas par le mécanisme de configuration distante existant, ce cycle DOIT l'y rendre accessible sans élargir la portée des paramètres exposés.
- **FR-051**: Les types d'événements émis par ce cycle DOIVENT être déclarés dans `docs/taxonomie-evenements.md` AVANT implémentation, selon la convention `<entite>.<action>` (constitution, principe VI ; précédent des cycles 002 et 003).
- **FR-052**: Les payloads d'événements NE DOIVENT porter AUCUNE donnée nominative ni position GPS — ni contact téléphonique, ni coordonnées de site : les données sensibles sont décrites par des booléens de présence ou des identifiants (minimisation ARTCI, précédent du cycle 003).
- **FR-053**: Le parcours vendeur livré par ce cycle (écrans V1 et V2) DOIT déclarer ses événements produit dans la taxonomie MET-01, conformément au point 4 de la Definition of Done de `docs/user-stories-v2.md`.
- **FR-054**: Les seeds de prestataires et d'articles DOIVENT être rejouables (une ré-exécution ne duplique rien et converge vers le même état) et n'émettre AUCUN événement — un chargement initial n'est pas une transition (précédent des cycles 002 et 003). Ils DOIVENT poser directement l'état d'activation de catégorie cohérent avec les prestataires qu'ils créent, sans passer par le recalcul de FR-009.

### Hors périmètre

- **VND-05 — Score de fiabilité et classement (P1)** : ni score quotidien, ni tri pondéré, ni file « à réévaluer ». La note moyenne affichée sur la maquette admin est produite par le cycle AVI ; ce cycle ne crée ni le calcul, ni l'agrégat, ni le champ.
- **VND-08 — Livraison offerte par le vendeur (P1, tranche T3)** : ni configuration par vendeur, ni badge client, ni retenue à la source au paiement. Seule l'ACCEPTATION de la retenue est couverte, en tant que clause de la charte signée (FR-003).
- **VND-09 — « Me prévenir au retour » (P1, tranche T4)** : ni abonnement, ni notification, ni compteur d'abonnés. Ce cycle se borne à émettre les événements de bascule que VND-09 consommera (FR-043). Le « me prévenir à l'ouverture » de la maquette C2 relève de la même story.
- **VND-06 — Multi-sites** et **VND-07 — Plans freemium** : PROVISIONS, tables uniquement (FR-019, FR-048).
- **Article à prix variable du marché (P1)** : ni fourchette affichée, ni confirmation de prix sur place — un article porte un prix ferme.
- **VAP-02 — bornes admin sur les prix du vendeur** : le vendeur édite ses prix et ses prix barrés sans limite fixée par l'Admin. L'encadrement « dans les limites fixées par l'admin » appartient à VAP-02 (P1, tranche T4) ; ce cycle livre l'édition, pas ses bornes.
- **QRC-01/02/03/04** : ni génération de PDF de plaque, ni scan en course, ni vérification de distance, ni saisie du code de secours en mode dégradé. Ce cycle porte la donnée, sa validité dérivée et sa résolution (FR-013 à FR-016) ; le cycle QRC porte les parcours.
- **ADM-03 — écran admin « Vendeurs & agrément » (maquette A2)** : aucune page web n'est construite ; les capacités correspondantes sont exposées en API protégée par le rôle admin (FR-012), les écrans arrivant au cycle ADM (tranche T3).
- **VAP-03 — commande entrante (maquette V3)**, ainsi que l'onglet « Commandes » et le compteur de commandes du jour visibles sur la maquette V1 : ils dépendent du module commandes. L'écran V1 livré par ce cycle en est dépourvu.
- **Écran coursier de signalement de rupture** : ce cycle livre la capacité, sa précondition et sa protection (FR-037 à FR-039) ; l'écran appartient au cycle CRS.
- **Fiche vendeur côté client (maquette C2) et fiche publique web (WEB-01)** : aucun écran client ni page SSR. La consultation exposée par FR-027 est une capacité, pas une interface ; la maquette C2 sert de référence pour ce que le catalogue doit rendre disponible.
- **Toute logique de commande** : panier, mixage de catégories, substitution, création et refus de commande. Ce cycle livre la capacité de figer un prix (FR-024) et l'état « commandable » (FR-028) ; le module commandes les exerce.

### Key Entities

- **Prestataire** : entité générale agréée par Mefali — nom, catégorie de service, ville de rattachement, photos, contact, délai de préparation, statut {prospect, agréé, suspendu}, charte signée, identité de plaque, plan. Le vendeur en est la spécialisation MVP ; un artisan de phase N sera un autre type sans migration.
- **Extension vendeur** : la spécialisation qui porte le catalogue et le stock d'un prestataire de type vendeur.
- **Site** : lieu d'exercice d'un prestataire — position GPS, horaires hebdomadaires à plages multiples, statut de boutique, échéance de pause, et rattachement de la disponibilité des articles. Un seul site au MVP, n sites prévus par le modèle (provision).
- **Rattachement compte ↔ prestataire** : lien optionnel et multiple (0..n) entre des comptes vérifiés et un prestataire ; il porte le rôle vendeur du compte, délimite ce que ce compte peut piloter, et attribue chaque action à son auteur.
- **Charte signée** : document scanné à accès restreint, avec la version en vigueur à la signature et sa date ; inclut l'acceptation de la retenue à la source. Condition nécessaire de l'agrément, conservée comme pièce contractuelle.
- **Identité de plaque** : jeton signé révocable et code de secours à quatre chiffres, portés par le prestataire ; leur validité dérive de l'état d'agrément, sans action de révocation distincte, et le jeton est résolvable.
- **Article** : élément du catalogue d'un vendeur — nom, prix courant, prix barré optionnel, photo, catégorie interne libre. Les montants sont des entiers en unités mineures avec code de devise.
- **Disponibilité d'article** : état vendable ou non d'un article sur un site, avec la source et l'auteur de la dernière bascule.
- **Signalement de rupture** : constat qu'un coursier éligible porte sur un article à un instant donné, muni de son identifiant client ; les signalements d'une fenêtre glissante alimentent le masquage automatique et restent comptés après une remise en vente.
- **Plan** : offre commerciale rattachée à un prestataire, avec ses caractéristiques (provision).

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Un prestataire agréé au terme d'une seule séquence d'agrément — fiche, charte, site, catalogue — est consultable et commandable immédiatement, sans aucune étape manuelle supplémentaire et sans qu'aucun compte utilisateur ne lui soit rattaché.
- **SC-002**: 100 % des suspensions rendent, immédiatement et sans aucune action supplémentaire, le prestataire non servi, non commandable, son jeton de plaque invalide à la résolution, et toute action vendeur d'un compte rattaché refusée.
- **SC-003**: 100 % des rétablissements restaurent le prestataire avec le même jeton et le même code de secours — aucune plaque physique n'a besoin d'être remplacée après une suspension.
- **SC-004**: L'état « commandable » est FAUX dans 100 % des cas où le prestataire n'est pas agréé, où sa catégorie est inactive dans sa ville, ou où sa boutique est fermée ou en pause — vérifié sur la totalité des combinaisons de ces états ; et aucun article en rupture n'est commandable.
- **SC-005**: Un montant figé pour un article ne varie jamais, dans 100 % des cas, quelle que soit la suite des modifications de prix.
- **SC-006**: Un prix barré inférieur ou égal au prix courant est refusé dans 100 % des tentatives, et aucun montant n'est jamais enregistré autrement qu'en entier accompagné de son code de devise.
- **SC-007**: Le vendeur bascule la disponibilité d'un article ou le statut de sa boutique en UN geste, et aucune consultation postérieure à la bascule ne renvoie l'état précédent.
- **SC-008**: Deux signalements de coursiers distincts et éligibles sur sept jours masquent l'article sans aucune intervention ; un article remis en vente est de nouveau masqué dès le signalement éligible suivant tant que la fenêtre porte le seuil ; et 100 % des signalements de coursiers non éligibles sont refusés sans être comptés.
- **SC-009**: 100 % des transitions décidées — agrément, suspension, rétablissement, statut de boutique, horaires, bascule de disponibilité — sont journalisées avec leur auteur, leur horodatage et leur source, et ont émis un événement métier ; aucun indicateur de ce module ne se calcule autrement qu'à partir de ces événements.
- **SC-010**: L'agrément ou le rétablissement d'un prestataire qui porte une catégorie au-dessus de son seuil active cette catégorie dans sa ville sans action manuelle, dans la même opération.
- **SC-011**: Aucun payload d'événement émis par ce cycle ne contient de donnée nominative ni de position GPS.
- **SC-013**: Aucune consultation non authentifiée ne révèle de contact téléphonique, de coordonnées de site ni de donnée d'exploitation, sur la totalité des états d'un prestataire.
- **SC-012**: Les seeds de prestataires et d'articles, ré-exécutés deux fois de suite, produisent un état strictement identique (aucun doublon), n'ont émis aucun événement, et les prestataires qu'ils créent sont commandables.

## Assumptions

- **Les critères produit sont repris tels quels** : les libellés opérationnels de VND-01 → VND-04 sont repris verbatim depuis `docs/user-stories-v2.md` à la demande du cadrage — aucune exigence produit supplémentaire n'a été inventée ; la forme exacte du modèle et de l'API relève du plan et du contrat OpenAPI (TRX-01).
- **Surface d'administration minimale** (précédent des cycles 002 et 003) : agrément, fiche, charte, catalogue et suspension sont exposés en API, protégés par le rôle admin et journalisés (qui, quand, avant/après) ; les écrans d'administration arrivent au cycle ADM (tranche T3).
- **Prestataire et compte sont deux cycles de vie distincts** : Tantie Affoué, qui n'a pas d'app, est le cas nominal — un prestataire agréé sans compte est pleinement commandable. Le rôle vendeur n'existe que sur les comptes rattachés, sa machine à états est celle livrée au cycle 003, et ce cycle la consomme sans la redéfinir ni la cascader (FR-008).
- **Déclencheurs simulés** : deux capacités de ce cycle sont exercées par le module commandes, qui n'existe pas encore — le verrouillage d'un prix (FR-024) et la précondition de commande active du signalement coursier (FR-038). Ce cycle les livre complètes et les teste par un déclencheur simulé, patron du cycle 003 pour l'enregistrement d'adresse après livraison.
- **Durées de pause** : les durées proposées (30 min, 1 h, 2 h) et le pas de prolongation (30 min) sont des constantes MVP issues de la maquette V1 — elles ne figurent pas au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md`. Le seuil et la fenêtre de masquage automatique (2 en 7 jours), eux, y figurent et sont donc des paramètres de zone.
- **Fuseau horaire des horaires d'ouverture** : celui de la zone du prestataire ; la ville de lancement n'a ni décalage saisonnier ni ambiguïté. Ni jours fériés, ni fermetures exceptionnelles datées ne sont modélisés au MVP — « fermé pour la journée » (FR-030) en tient lieu.
- **Le masquage automatique porte sur des coursiers distincts** : deux signalements du même coursier comptent pour un. Le produit dit « 2 signalements » sans le préciser ; sans cette lecture, un signaleur unique pourrait masquer n'importe quel article.
- **Mode d'affichage des articles en rupture** : « config par catégorie » (VND-04) est lu comme un paramètre de catégorie résolu par l'héritage de zone, au même titre que les paramètres de catégorie déjà en place au cycle 002. Sa valeur seed est **grisé** pour toutes les catégories : les maquettes `docs/design/png/V2-catalogue-stock.png` (panneau « Ce que voit le client ») et `C2-fiche-vendeur.png` montrent l'une et l'autre une ligne grisée portant sa mention « Rupture », jamais un article absent ; le masquage reste l'autre valeur possible.
- **Deux paramètres de zone créés par ce cycle** : le mode d'affichage des articles en rupture par catégorie (seed « grisé ») et la durée de conservation de la charte après la fin de la relation (seed 5 ans). Conformément à la règle de gouvernance de la constitution — les documents produit d'abord — ils ont été inscrits au « Récapitulatif des paramètres de zone » de `docs/user-stories-v2.md` le 2026-07-18, avant l'écriture du plan ; c'est ce document qui fait foi pour leurs valeurs.
- **Stockage de la charte et des photos** : le stockage objet du projet, exprimé ici « stockage objet sécurisé à accès restreint ». Le port d'accès vit aujourd'hui dans le domaine des comptes ; le rendre consommable par ce cycle suppose une reprise, dont l'ampleur et l'emplacement relèvent du plan (constitution, principes II et VIII).
- **Recalcul de l'activation de catégorie** : ce cycle appelle la capacité livrée au cycle 002, qui prend le nombre de prestataires agréés en entrée et n'est monotone qu'à la hausse. La forme de cette dépendance entre domaines — et le fait que la capacité ne relève pas aujourd'hui de l'interface de lecture de la configuration — relève du plan.
- **Interface de l'extension vendeur** : conformément à la constitution (principe II — un crate par domaine, interfaces par traits), la distinction prestataire / extension vendeur est exposée comme un trait propre du crate `prestataires` ; la signature exacte relève du plan, pas de la spec.
- **Le crate s'appelle `prestataires`, pas `vendeurs`** : c'est la note de tête du module dans `docs/user-stories-v2.md` et la provision §11.13 du cadrage — le nommage porte l'extensibilité vers les prestataires de phase N (plombier, électricien), qui réutiliseront agrément, plaque, notes et dispatch sans migration.
- **Notes et score de fiabilité** : aucune colonne n'est inventée pour eux dans ce cycle. La note moyenne visible sur la maquette A2 est produite par AVI-02 et le score par VND-05, tous deux hors périmètre ; le prestataire les portera quand ces cycles les livreront.
- **Contenu des seeds** : deux à trois prestataires de Tiassalé, chacun avec son site et une poignée d'articles, suffisants pour exercer la consultation et la commandabilité. Les seeds ne portent aucune configuration de livraison offerte, qui appartient à VND-08 (hors périmètre).
