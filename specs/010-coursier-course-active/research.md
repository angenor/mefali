# Research — cycle CRS 010 (app coursier : course active, cash, hors-ligne)

Décisions prises **avant** d'écrire une ligne de code, chacune avec ce qu'elle
coûte et ce qu'elle évite. Le fil rouge : ce cycle ne réécrit rien de ce que les
cycles 006, 008 et 009 ont livré — il **branche**, **compose** et **comble** les
trous que ces cycles ont explicitement laissés.

---

## R1 — Le crate `coursier` devient réel ; `commandes` continue de l'ignorer

**Décision** : le crate `coursier` (vide depuis le socle) porte le domaine du
cycle — course active composée, appels, présence, preuves, caisse,
indemnisations — avec son propre schéma Postgres `coursier`. Il **dépend** de
`commandes` (lecture de la course, port `PreuvesEchec` à implémenter) et de `qr`
(empreintes de plaque, politique photo). Aucune dépendance inverse n'est
introduite.

**Rationale** : la constitution II impose un crate par domaine et interdit qu'un
crate partagé suppose autre chose que le tronc. Le cycle 008 a **conçu** le port
`PreuvesEchec` pour qu'un autre crate l'implémente (« les preuves d'échec
(CRS-05) sont une précondition vérifiée, fournie par un double »). `commandes`
pèse déjà ≈ 6 500 lignes : y ajouter la caisse le rendrait illisible.

**Alternatives rejetées** : (a) tout mettre dans `commandes` — casse la frontière
et grossit le crate le plus chargé ; (b) un crate `caisse` séparé de `coursier` —
deux crates pour un domaine qui a un seul acteur et un seul écran de sortie.

---

## R2 — `GET /courses/active` déménage de `qr` vers `coursier`, chemin inchangé

**Décision** : l'endpoint garde son chemin (`/courses/active`) et son rôle
(coursier), mais son handler passe dans `coursier_http` et sa réponse s'enrichit
de façon **additive** : la liste d'arrêts existante gagne ses **lignes
d'articles**, et deux objets apparaissent — `client` (nom d'usage, repère texte,
clé de la note vocale, position, téléphone, drapeau de dépôt) et `remise`
(empreintes du code et du jeton, essais déjà consommés, montant à encaisser).

**Rationale** : un seul aller-retour au moment de l'assignation doit suffire à
faire fonctionner **toute** la course hors ligne (FR-011, FR-028). Le chemin
inchangé évite de casser l'app livrée au cycle 006. Et le contenu enrichi n'a
rien à faire dans `qr`, dont le domaine est la plaque, pas le client.

**Alternatives rejetées** : (a) un second endpoint `/courses/active/details` —
deux appels au pire moment, et deux caches à réconcilier ; (b) enrichir
`qr_http` — `qr` deviendrait dépendant du client et des lignes de commande,
c'est-à-dire de tout.

---

## R3 — Les empreintes de remise existent déjà : rien à créer, tout à exposer

**Décision** : `commande.code_livraison_hash` et `commande.jeton_reception_hash`
(migration 0009, cycle 008, commentées « empreinte salée → coursier (offline
CRS-04) ») sont **lues telles quelles** et servies dans le pré-provisionnement.
Le sel du code est l'`id` de la commande ; le jeton, aléa long, n'est pas salé.
Les fonctions vivent déjà dans `socle::empreintes`.

**Rationale** : le cycle 008 a fait le travail en prévision de celui-ci. Recréer
un hachage local produirait deux vérités pour un même secret.

**Conséquence** : **aucune migration** n'est nécessaire pour le
pré-provisionnement de remise — seulement une lecture de plus.

---

## R4 — Idempotence de la remise et de l'échec : le manque du cycle 008

**Décision** : `POST /courses/{id}/remise` et `POST /courses/{id}/echec`
reçoivent un `uuid_client` **obligatoire**, et deviennent idempotents sur le
patron déjà en place pour la collecte (`collecte_uuid_client`) et les transitions
d'arrêt (`transition_uuid_client`) : le rejeu d'un même identifiant rend le même
résultat sans réécrire ni ré-émettre. Deux colonnes : `livraison.remise_uuid_client`,
`coursier.issue_uuid_client` (côté échec, sur la table d'issue existante).

**Rationale** : la constitution V l'exige pour **toute** action coursier, et
FR-089 (le test obligatoire du module) est impossible sans : couper le réseau
entre le scan et la livraison, c'est précisément rejouer une remise.

**Alternatives rejetées** : déduire l'idempotence de l'état (« déjà livrée →
succès ») — indistinguable d'un second coursier qui rejouerait une remise sur une
course qui ne lui appartient plus, et donc silencieusement faux.

---

## R5 — Essais du code : compteur serveur, consolidation des essais hors ligne

**Décision** : trois règles.

1. Les essais **faux** consommés hors ligne ne partent **pas** un par un dans la
   file : l'app compte localement et transporte `essais_hors_ligne` **avec** la
   demande de remise (ou avec une action dédiée si la course se termine
   autrement).
2. Le serveur retient `max(essais_serveur, essais_hors_ligne)` et bloque au seuil
   de zone **déjà existant** : `commande.essais_code_livraison` = 3, seedé par le
   cycle 008 (`backend/seeds/60_commandes_parametres.sql`) et **lu en production**
   par `valider_remise` (`collecte.rs`). Ce cycle le **réutilise** et n'en crée
   surtout pas un second — deux clés pour un même seuil divergeraient au premier
   réglage d'exploitation (constitution I, FR-106).
3. Le blocage est un **état durable de la commande** (`code_bloque_le`), levable
   par l'exploitation avec motif tracé.

**Rationale** : envoyer des codes faux au serveur les ferait voyager sans aucun
bénéfice ; ne rien envoyer laisserait le compteur diverger. Le `max` est la seule
règle qui ne perd jamais un essai et n'en invente jamais.

**Alternatives rejetées** : (a) compteur purement local — un coursier qui
réinstalle l'app repart à zéro ; (b) compteur purement serveur — inopérant hors
ligne, ce qui est exactement le cas d'usage.

---

## R6 — Numéros de téléphone : dans le pré-provisionnement, jamais dans un journal

**Décision** : le numéro du client et celui du vendeur entrent dans le
pré-provisionnement (l'appel doit fonctionner **sans réseau**, FR-029/FR-032),
sont stockés dans le cache local de course, **effacés à la clôture** de la
course, et n'apparaissent dans **aucun** événement, journal ou réponse d'API
autre que celle-ci. L'événement `appel.intention` porte l'intention, la direction
et le motif — jamais le numéro (taxonomie existante).

**Rationale** : minimisation ARTCI. Le masquage par relais téléphonique serait la
solution idéale mais suppose un fournisseur et un coût récurrents : hors
périmètre, à porter au produit si le besoin apparaît.

---

## R7 — Le risque résiduel du code à 4 chiffres hors ligne, assumé et encadré

**Constat** : l'empreinte d'un code à 4 chiffres, salée par un identifiant que
l'app connaît, se casse en 10 000 hachages — quelques secondes sur un téléphone.
Un coursier malhonnête peut donc, hors ligne, retrouver le code et « confirmer »
une remise qu'il n'a pas faite.

**Décision** : le risque est **assumé** — c'est le prix du hors-ligne que CRS-04
exige — et encadré par quatre garde-fous : (1) la validation locale n'engage
rien, le **serveur revalide** au rejeu ; (2) la remise porte son **mode** et le
fait qu'elle a été validée hors ligne ; (3) le jeton QR, aléa long, reste
inattaquable, et c'est la voie **principale** de la maquette ; (4) le client qui
n'a rien reçu ouvre un litige, et la trace désigne immédiatement la course.

**Alternatives rejetées** : (a) un dérivateur lent (Argon2/PBKDF2 à coût élevé) —
ralentit l'attaque de quelques minutes, pas plus, contre un coût de batterie réel
à chaque saisie légitime ; (b) interdire le code hors ligne — casse le scénario
central de CRS-04 (« le coursier hors ligne valide quand même »).

---

## R8 — Preuves d'échec : deux tables, une distance, aucune coordonnée

**Décision** : `coursier.appel_coursier` (livraison, motif, horodatage serveur,
`uuid_client`) et `coursier.releve_presence` (livraison, horodatage, **distance
arrondie** au point de livraison). La photo de preuve va dans Garage, sa clé dans
`coursier.preuve_photo`. Le calcul de « 10 minutes de présence » somme les
**intervalles entre relevés consécutifs** dans le rayon, en ignorant tout
intervalle supérieur à un « trou » paramétrable — sans cette règle, deux relevés
espacés de dix minutes vaudraient dix minutes de présence.

**Rationale** : le patron ARTCI est déjà celui du cycle 006 (`distance_scan_m`
arrondi, « pas de GPS brut »). Et la règle du trou est ce qui distingue une
présence d'un aller-retour.

**Alternatives rejetées** : (a) déduire la présence des positions du pool (Redis)
— éphémère, donc impropre à fonder une indemnisation ; (b) faire confiance à une
durée calculée par l'app — FR-060 exige que le serveur revérifie.

---

## R9 — La caisse est un livre d'écritures alimenté par l'outbox

**Décision** : `coursier.ecriture_caisse` est **append-only** (aucun `UPDATE`,
aucun `DELETE` ; une correction est une écriture inverse) et est alimentée par un
**second consommateur outbox**, `CaisseOutbox`, sur le patron exact de
`DispatchOutbox` (cycle 009, premier consommateur réel). Il consomme
`arret.collecte` (→ avance), `livraison.livree` (→ remboursement par
encaissement, **si et seulement si** le mode de paiement est cash) et
`indemnisation.due` (→ indemnisation « demandée »). Idempotence par
`evenement_id UNIQUE`.

**Rationale** : c'est la seule façon d'alimenter la caisse **sans** dépendance
inverse `commandes → coursier` (constitution II) ; le worker garantit
l'at-least-once et le consommateur est idempotent par construction. Une
projection en lecture (SUM sur `arret`) aurait été plus simple mais ne tient ni
FR-070 (une écriture par mouvement) ni FR-073 (immuabilité).

**Conséquence assumée** : la caisse est cohérente **à quelques secondes** près
(délai du worker), ce que SC-010 accepte explicitement (≤ 5 s).

---

## R10 — Commande prépayée : l'avance reste ouverte, et le dit

**Décision** : à la remise d'une commande dont le mode de paiement n'est pas le
cash, **aucune** écriture de remboursement n'est produite ; l'avance reste
ouverte, marquée `en_attente_reglement`, et la caisse l'affiche comme telle.

**Rationale** : c'est la clarification du 2026-07-28 (déféré à PAY, tranche T3).
Écrire un remboursement fictif ferait mentir un solde d'argent réel ; masquer
l'avance la ferait disparaître d'un écran dont c'est la seule raison d'être.

---

## R11 — La checklist coche des lignes, et les coches restent locales

**Décision** : les lignes viennent de `commandes.ligne_commande` (déjà en base),
groupées par arrêt via le prestataire. La **coche** d'un article est un état
**local** (drift), jamais envoyé au serveur. L'indisponibilité d'une ligne
emprunte le chemin de substitution existant (`POST /courses/{id}/substitutions`),
celle d'un arrêt entier le chemin d'arrêt existant.

**Rationale** : le serveur ne connaît que « arrêt collecté » et « ligne retirée /
remplacée » ; inventer un état serveur « article coché » créerait une troisième
vérité que rien ne consomme. La coche est un aide-mémoire d'achat, pas un fait
métier.

---

## R12 — Service continu : deux plugins natifs, toute la logique en Dart

**Décision** : un **service de premier plan Android** maintient l'app vivante
tant que Yao est en ligne (publication de position, interrogation d'offre,
échantillonnage de présence), et un plugin de **notifications locales** porte le
canal dédié de haute importance (son prolongé, ouverture directe de l'écran
d'offre). Les deux paquets sont choisis en dernière version stable au moment de
l'ajout et figés par lockfile ; **toute** la logique métier reste en Dart.

**Rationale** : c'est la réponse à la clarification du 2026-07-28. Le cycle 009
avait constaté que sans cela, « téléphone en poche, écran éteint, Yao ne sait pas
qu'une course lui est offerte ».

**Conséquence assumée** : deux plugins natifs = un passage store obligatoire
(Shorebird ne patche que le Dart). D'où la règle : les ajouter **en une fois**,
tôt, et ne plus y toucher.

**Alternatives rejetées** : (a) attendre le push de NTF-01 — le push seul ne
maintient pas la publication de position ni la mesure de présence ; (b) un
`WorkManager` périodique — granularité de 15 minutes, inutilisable pour une offre
de 40 secondes.

---

## R13 — L'interrogation d'offre déménage dans le service, sans doubler le débit

**Décision** : l'interrogation courte (`GET /courses/offre-courante`, 2 s) livrée
au cycle 009 dans `InterfaceCoursier` reste la seule au **premier plan** ; le
service continu prend le relais **quand l'app passe en arrière-plan**, à une
période plus lente (paramétrable), et déclenche la notification sonore. Jamais
les deux en même temps.

**Rationale** : le cycle 009 avait déjà écarté une seconde horloge dans K2 pour
ne pas doubler le débit pendant les 40 secondes de décision. La même règle
s'applique ici.

---

## R14 — Navigation : trois destinations, mais la course garde la priorité

**Décision** : `InterfaceCoursier` gagne une `NavigationBar` Material 3 à trois
destinations (Tableau, Courses, Caisse), **sous** la règle de priorité déjà
écrite au cycle 009 : une **offre en vol** prend tout l'écran, une **course
active** occupe l'écran tant qu'elle dure. La barre n'apparaît donc que lorsque
Yao n'est ni en offre ni en course… **sauf** l'accès à la caisse depuis la
course, qui reste possible (K5 est consultable pendant une course : c'est là que
Yao voit ce qu'il a avancé).

**Rationale** : la maquette montre la barre sur K1 et K5, jamais sur K2, et K3 a
son propre entête. La priorité du cycle 009 n'est pas négociable : une offre a
40 secondes.

---

## R15 — État Flutter : deux moules, durées de vie explicites

**Décision** :

| Porteur | Moule | Durée de vie | Pourquoi |
|---|---|---|---|
| `EtatCourseActive` (existant, étendu) | `AsyncNotifier` | `@riverpod` nu | chargement + cache, se jette avec l'écran |
| `EtatRemise` (essais, blocage, voie choisie) | `Notifier<EtatRemise…>` | `keepAlive` pendant la course | c'est un **processus** : les essais ne doivent pas se réinitialiser quand l'écran se reconstruit |
| `EtatPreuves` (3 preuves, décomptes) | `Notifier<EtatPreuves…>` | `keepAlive` pendant la course | idem : un décompte de 10 minutes ne survit pas à un `autoDispose` |
| `EtatCaisse`, `EtatJournee` | `AsyncNotifier` | `@riverpod` nu | chargements de liste |
| `ServiceContinu` | `Notifier` | `keepAlive: true` | processus de session |

**Rationale** : constitution XII — « DEUX MOULES, nommés », durée de vie
« EXPLICITE et ARGUMENTÉE ». Le piège identifié au cycle 004 (un compte à rebours
providerifié qui tourne sur un arbre démonté) est évité en gardant les minuteries
d'affichage **locales** au widget, et l'état de progression dans le provider.

---

## R16 — Modules non construits : ce qui est simulé, et par quoi

| Module | Ce que ce cycle pose | Double / substitut |
|---|---|---|
| **NTF-01/02** | rien de neuf : le contrat d'émission du cycle 009 est intact | l'app se réveille elle-même (R12/R13) |
| **ADM-02/04/07** | endpoints d'exploitation (exposition, indemnisations, blocages, dépôt) | exercés **par API** dans les tests ; aucun écran Nuxt |
| **AVI-04** | rattachement d'une indemnisation à un identifiant de litige | port `LitigesOuverts` + double « aucun litige » |
| **PAY-01/02/03** | rien : le remboursement non-cash n'est pas modélisé (R10) | l'avance reste ouverte et visible |

---

## R17 — Paramètres de zone ajoutés (seed `80_coursier_parametres.sql`)

| Clé | Défaut Tiassalé | Source |
|---|---|---|
| `coursier.preuve_appels_min` | 2 | CRS-05 |
| `coursier.preuve_appels_espacement_s` | 180 | CRS-05 |
| `coursier.preuve_presence_s` | 600 | CRS-05 |
| `coursier.preuve_presence_rayon_m` | 100 | aligné sur `qr.distance_scan_max_m` (Récapitulatif — « Distance max de scan QR 100 m ») ; le Récapitulatif n'a pas de ligne dédiée, la valeur seed reprend la porte de présence déjà en service |
| `coursier.preuve_presence_trou_max_s` | 120 | R8 — intervalle au-delà duquel deux relevés ne comptent plus comme une présence continue |
| `coursier.retention_photo_preuve_jours` | 365 | aligné sur `qr.retention_photo_collecte_jours` (Récapitulatif — « Rétention des photos de récupération 365 j ») |
| `coursier.offre_interrogation_arriere_plan_s` | 5 | R13 — période d'interrogation en arrière-plan (le premier plan reste à 2 s, constante d'UI du cycle 009) |

**Sept paramètres, pas huit** : le nombre d'essais du code de remise **existe déjà**
(`commande.essais_code_livraison`, R5) et est réutilisé tel quel.

**Trois rétentions de photo, et c'est voulu** : `qr.retention_photo_collecte_jours`
(récupération, cycle 006), `substitution.photo_retention_jours` (remplacement,
cycle 008) et `coursier.retention_photo_preuve_jours` (preuve d'échec, ce cycle)
sont trois durées **distinctes par nature de preuve** — le patron est celui des
deux cycles précédents, une clé par usage, éditable séparément. Ce n'est pas une
duplication : aucune des trois ne décrit la même photo.

Tous éditables par zone (ADM-05), hérités par l'arbre, aucun en dur.

---

## R18 — La remise passe en multipart : sans cela, le dépôt ne marche pas hors ligne

**Constat** : `POST /courses/{id}/remise` accepte aujourd'hui un JSON dont le mode
`depot` porte une `photo_cle` — c'est-à-dire la **clé d'un objet déjà déposé**
dans Garage. Hors ligne, aucun dépôt n'est possible : la troisième voie de CRS-04
serait, en l'état, la seule à exiger du réseau.

**Décision** : l'endpoint devient un **multipart** (`demande` JSON + `photo`
binaire facultative), exactement comme la collecte du cycle 006 et la déclaration
de rupture du cycle 008. La photo voyage **avec** la demande, donc dans la file,
donc hors ligne. Le serveur dépose l'objet à la réception et écrit la clé.

**Rationale** : c'est le patron déjà en service dans deux cycles, et il est le
seul compatible avec la constitution V. Le champ `photo_cle` reste accepté en
entrée pour ne pas casser un appelant existant, mais l'app coursier ne l'utilise
jamais.

**Alternatives rejetées** : (a) un endpoint d'upload préalable — inutilisable
hors ligne, ce qui est précisément le cas d'usage ; (b) transporter la photo en
base64 dans le JSON — gonfle la file et le journal pour rien.

---

## R19 — L'issue d'un appel est déclarée par le coursier, parce que K4-1e l'affiche

**Décision** : `coursier.appel_coursier` porte une **issue** (`sans_reponse` |
`repondu` | `inconnue`, défaut `inconnue`), déclarée par le coursier après
l'appel et modifiable jusqu'à la déclaration d'échec.

**Rationale** : la maquette `K4-confirmation-livraison.png` 1e écrit noir sur
blanc « 2 appels via l'app — Fait · 15:02 et 15:06, **sans réponse** ». Sans cette
donnée, l'écran ne peut pas être rendu, et FR-036 resterait une exigence sans
support. Le système ne peut pas l'observer lui-même (l'appel part du téléphone,
le serveur n'en voit rien) : elle est donc **déclarative**, et journalisée comme
telle.

**Conséquence sur la preuve** : l'issue **n'est pas** un critère de la preuve
d'échec — seuls le nombre, le motif et l'espacement le sont (FR-056). Un coursier
qui déclarerait « sans réponse » à tort ne gagne rien ; il informe seulement
l'exploitation.
