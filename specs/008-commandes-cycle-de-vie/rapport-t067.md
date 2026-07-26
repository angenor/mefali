# Cycle 008 (CMD) — rapport de clôture T067

**Branche** `008-commandes-cycle-de-vie` · **2026-07-26** · non fusionnée dans `main`

**68 tâches sur 68 livrées.** `cargo test --workspace` **491 verts**,
`cargo clippy --all-targets -- -D warnings` **vert**, Flutter **57 (client) +
95 (core)**, `dart analyze` propre sur les trois paquets, `cargo sqlx prepare`
vert, clients Dart/TS régénérés **sans diff**.

> **Reprise du 2026-07-26**, en trois temps :
> 1. le dernier geste manquant — accepter la scission — est livré
>    ([section](#la-scission-est-acceptable-cmd-01-c3-3d)) ; le point ouvert n° 1
>    a disparu ;
> 2. la **livraison devient un composant optionnel du contrat**
>    ([section](#la-livraison-devient-optionnelle-au-contrat)) ; l'ancien point
>    ouvert sur `Commande.livraison` a disparu ;
> 3. la scission est **passée sur émulateur** à deux et trois vendeurs, échec
>    partiel compris ([section](#passe-émulateur-de-la-scission)) ;
> 4. les trois suites de cette passe sont traitées
>    ([section](#suites-de-la-passe-émulateur)) : **fuite de secrets au rejeu**
>    fermée, clippy redevenu vert, et le 500 tarifaire devenu un refus lisible.

---

## Le problème levé

La session précédente concluait que la validation sur émulateur était
**impossible** : six écrans livrés, thémés et testés, mais aucune navigation
pour les atteindre et **aucun appel serveur câblé**. Ce n'était l'oubli d'aucune
tâche — T019, T020, T024, T032, T045, T046 et T053 demandent des *écrans*,
jamais un routeur ni une couche d'appel.

Le manque a été comblé, dans les limites strictes du parcours.

## Ce qui a été construit

| Ajout | Fichier | Rôle |
|---|---|---|
| `CommandesApi` | `mefali_core/src/commande/api_commandes.dart` | Les 7 routes du cycle sur le client Dart **généré** (constitution I) |
| `codeErreurApi` / `estPanneReseau` | idem | Un refus rend son **code** (constitution VII) ; une panne réseau se distingue et autorise la bascule sur le cache |
| `CacheCommandes` | `mefali_core/src/offline/cache_commandes.dart` | Écrit code + QR **à la création** ; c'est toute la base de SC-009 |
| `AdressesApi.enregistrer` | `mefali_core/src/adresses/api_adresses.dart` | Un repère **vocal** exige une clé S3 que seule `POST /moi/adresses` produit — la commande passe donc par le carnet (CPT-05) |
| `ActionsCommande` | `mefali_client/parcours/actions_commande.dart` | Devis, confirmation, suivi, annulation, intention d'appel, substitution |
| `AccueilClient`, `EcranVendeur`, `PagePanier` / `PageAdressePaiement` / `PageSuivi` | `mefali_client/parcours/` | Le parcours accueil → vendeur → panier → adresse → confirmation → suivi |
| `sourceSuiviProvider` surchargé | `mefali_client/main.dart` | Injection par la **portée**, patron `urlApiProvider` |

### Décision structurante

La couche d'appel rend le **corps JSON du contrat** (via les
`standardSerializers` du paquet généré), **pas les DTO**. Les vues d'écran se
construisent depuis le JSON (`depuisJson`), et c'est ce chemin que couvrent les
tests widget du cycle : rendre le DTO aurait ouvert un **second** chemin de
conversion, non couvert, voué à diverger au premier changement de contrat. Les
noms de champs viennent d'`openapi.json` (`wireName`), jamais de littéraux
recopiés à la main.

## Validation sur émulateur

Environnement : Postgres 5433, Redis, Garage, **OSRM absent** (image
`ghcr.io/project-osrm/osrm-backend:v26.7.3` disparue du registre) → devis en
**dégradé vol d'oiseau ×1,4 journalisé**, conforme constitution IV.
AVD : `Medium_Phone_API_36.1`.

| Critère | Résultat |
|---|---|
| **SC-001** | ✅ Panier chiffré par le serveur (regroupement vendeur, sous-totaux, Articles / Livraison / Total), pin GPS capté, repère écrit avec compteur, **appoint exact** affiché, code `5319` + QR remis **immédiatement** |
| **SC-004** | ✅ Stepper en langage clair, « Chez Boutique Kofi », position annoncée absente plutôt qu'inventée, coursier et annulation apparaissant/disparaissant selon l'état |
| **SC-009** | ✅ Mode avion : « Hors connexion · Dernier état connu », stepper masqué, bloc « À la livraison — **disponible sans réseau** » avec QR et code depuis le cache ; la **liste** des commandes retombe aussi sur le cache |
| **SC-011** | ✅ Création → collecte (scan QR, **rejeu idempotent** vérifié) → `en_livraison` → remise contre code → `terminee`, `etat_paiement = regle`, `commande.terminee` avec `total_encaisse = 9800 = total_unites`. Assertion structurelle : **aucune colonne logistique sur le tronc** |

## Deux défauts trouvés sur l'appareil, corrigés

1. La préférence **« M'appeler » se rendait une lettre par ligne** : trois
   segments à droite du libellé ne tiennent pas sur 1080 px. Titre remonté
   au-dessus, coche de sélection retirée.
2. Après confirmation, le **retour tombait sur un panier vide** : la pile
   panier → adresse → confirmation est maintenant vidée jusqu'à l'accueil
   (`pushAndRemoveUntil`).

## Point secondaire traité — alerte du code de remise épuisé

L'épuisement des essais bloque la commande à la porte du client et exige un
humain (l'app dit « un conseiller va vous contacter »). C'était un
`tracing::warn!`, auquel personne ne s'abonne.

- `remise.code_epuise` **déclaré dans `docs/taxonomie-evenements.md` d'abord**
  (27 → **28** événements), avec son payload ;
- **émis dans la même transaction** que le compteur d'essais qui le déclenche ;
- le payload ne porte **jamais** le code — le publier le sortirait du seul canal
  qui doit le porter (client ↔ coursier, R6). Un test l'assure.

## La scission est acceptable (CMD-01, C3-3d)

Le bandeau s'affichait, chiffré et prévisualisé, mais son bouton n'était branché
sur rien : une proposition qu'on ne peut pas accepter est pire qu'une proposition
absente. **Aucune route serveur n'a été ajoutée** — accepter, c'est appeler
`POST /commandes` N fois. Périmètre : `apps/mefali_client` + la l10n et rien
d'autre ; ni backend, ni contrat, ni migration.

| Ajout | Fichier | Rôle |
|---|---|---|
| `CommandeProposeeScission` | `panier/etat_panier.dart` | **Garde les identifiants d'articles** de chaque commande proposée. L'ancienne vue n'en gardait que le compte — donc rien pour répartir les lignes |
| `TronconScission` + `EtatPanier.troncons` | idem | Une des N commandes acceptées : ses lignes, **sa** clé d'idempotence, **son** devis |
| `ActionsCommande.accepterScission` | `parcours/actions_commande.dart` | Répartit les lignes, chiffre **chaque tronçon seul**, donne une clé par tronçon |
| `confirmer` en série | idem | N créations **en séquence**, arrêt au premier échec, reprise du seul reste |
| `BlocScissionAcceptee`, `BlocRepriseScission` | `panier/bloc_scission.dart` | La prévisualisation des N commandes, et l'échec partiel dit en clair |
| `Confirmation.commandesCreees` | `panier/etat_confirmation.dart` | Une **liste** : N commandes = N codes de remise, N QR |

### Trois décisions structurantes

**Chaque tronçon est chiffré par le serveur, séparément.** Le devis du panier
entier ne connaît qu'**un** frais de déplacement ; après scission il y en a N.
Afficher son total après acceptation aurait annoncé un montant que personne
n'encaisse. `accepterScission` appelle donc `POST /paniers/devis` une fois par
tronçon — lecture pure, aucun effet de bord (P4) — et l'écran montre les N frais
au lieu de les annoncer. L'app n'estime toujours **aucun** frais (R8). Effet de
bord utile : l'autorisation du cash et l'**appoint exact** deviennent justes par
commande, là où le total d'ensemble les aurait faussés tous les deux.

**Une clé d'idempotence par tronçon, née à l'acceptation et rangée dans l'état
du panier.** Elle survit donc à la tentative, et un nouvel essai après coupure
rejoue la même clé : le serveur rend la commande existante au lieu d'en créer une
seconde (R7). Les commandes créées quittent le panier **avec** leur clé ; celles
qui restent gardent la leur.

**L'échec partiel ne s'annule pas et ne se cache pas.** Une commande créée est
valide et due : elle n'est jamais annulée en silence. La série s'arrête au premier
refus — insister enverrait la suivante contre le même mur — l'écran dit
exactement combien sont passées et combien ne le sont pas, et « Reprendre le
reste » ne renvoie que les tronçons manquants. Le panier ne garde que leurs
lignes, sinon un nouvel essai recommanderait ce qui est déjà commandé.

### Ce que les tests tiennent

`test/parcours/scission_test.dart` — 7 cas sur le parcours RÉEL (`PagePanier` →
`PageAdressePaiement`), transport bouché, base drift en mémoire, position
injectée :

| Cas | Ce qui est prouvé |
|---|---|
| Acceptation | 2 tronçons chiffrés, **2 frais de 300 affichés**, celui de la tournée unique (250) **absent** de l'écran |
| Création | **2** `POST /commandes`, **2 clés distinctes**, chacune ne portant que ses lignes, 2 codes de remise rendus |
| Échec de la 2ᵉ | la 1ʳᵉ conservée, « 1 commande sur 2 a été créée », panier réduit à la ligne restante, **clé inchangée** |
| Reprise | 3 requêtes en tout, les deux tentatives de la 2ᵉ commande portent la **même** clé, et seul le reste repart |
| **SC-006** | sans appui : **une** seule commande tentée, panier **entier**, aucun tronçon chiffré |
| Révocation | « Revenir à une seule commande » rend la proposition et le total d'ensemble intacts |
| Invariant d'état | modifier le panier **abandonne** la scission acceptée — ses tronçons désignaient les lignes d'avant |

### Deux défauts trouvés en passant, corrigés

1. **Un échec réseau n'arrêtait pas la série.** La boucle s'arrêtait sur
   « le code de refus est non nul », or `codeErreurApi` rend `null` sur une panne
   réseau — l'échec le plus fréquent, et celui qui doit précisément tout arrêter.
   Le drapeau d'échec est maintenant distinct du code du message.
2. **Le bouton « Changer » du bloc adresse portait le libellé
   « Scinder en 2 commandes »** (`panierScissionAction`, copié par erreur). Jamais
   vu à l'écran — `onChangerAdresse` n'est encore branché nulle part — mais il
   l'aurait été au premier câblage du carnet. Clé propre ajoutée.

### Libellés paramétrés

`panierScissionAction` et `panierScissionAvertissement` étaient figés sur
**deux** commandes. Or `categorie_non_mixable` découpe **par vendeur** : trois
vendeurs donnent trois commandes, et l'écran aurait annoncé « deux frais de
déplacement » pour trois. Les deux clés prennent maintenant `n` ; le cas à deux
garde **mot pour mot** la lettre de la maquette (`{n, plural, =2{Deux
commandes, deux frais de déplacement.} …}`).

## La livraison devient optionnelle au contrat

Le contrat se contredisait **lui-même** : `SuiviCommande` rendait déjà
`livraison_id` et `livraison_etat` optionnels, le schéma Postgres n'exige aucune
livraison (test T037), et `creer_relivraison` (`echec.rs`) en crée bel et bien
une sans — seul `Commande`, la réponse de `POST /commandes`, la forçait. Corrigé
maintenant plutôt qu'après DSP, CRS et PAY, pour qui le changement deviendrait
cassant.

**Le défaut commençait dans le type du domaine.** `CommandeCreee` portait trois
champs plats — `livraison_id: Uuid`, `nb_arrets: i64`, `devis: Devis` — qui
peuvent se contredire : un identifiant nul avec deux arrêts, un devis à zéro
sans livraison. Ils vivent ou meurent ensemble : ils sont groupés dans un
`Option<LivraisonCreee>`.

**Dix valeurs par défaut supprimées.** `relire_commande_creee` lisait la
livraison en `LEFT JOIN`, ce qui rendait ses colonnes nullables pour sqlx alors
qu'elles sont `NOT NULL` en base (migration 0009) : il fallait dix `unwrap_or`
pour recomposer un devis, dont un `unwrap_or_default()` sur un `Uuid` — soit
`Uuid::nil()`, un identifiant qui a l'air valide et ne désigne rien. Une lecture
DÉDIÉE, sans jointure, type les colonnes non-`Option` : zéro défaut, et
l'absence naît là où elle est vraie, dans le `fetch_optional`. Coût : un
aller-retour SQL sur le seul chemin de rejeu.

**Aucun changement de comportement**, vérifié par quatre relecteurs
adversariaux (aucun défaut confirmé) : chemin nominal et rejeu **avec** livraison
rendent le même corps, octet pour octet. Deux écarts préexistants ont été
délibérément reconduits plutôt que corrigés en passant — `etat: "assignee"` en
dur (le lire en base changerait le corps du rejeu d'une course déjà avancée) et
`ordre: Vec::new()` au rejeu. Seul le rejeu d'une commande **sans** livraison
change : il rendait un UUID nul, il rend `null`.

Quatre tests, chacun ne prouvant que ce qu'il couvre : le rejeu sans livraison
rend `None` sur une **vraie base** (`tronc.rs` — le test qui aurait échoué sur
l'ancien `unwrap_or_default`) ; le schéma n'exige plus `livraison` mais la
décrit toujours (`lib.rs`) ; `"livraison": null` sur le fil et forme inchangée
sous `Option` (`commandes_http.rs`) ; le client **généré** lit une commande sans
livraison sans broncher (`mefali_core`).

## Passe émulateur de la scission

AVD `Medium_Phone_API_36.1`, API locale, **OSRM absent** → dégradé vol d'oiseau
×1,4. Trois restaurants créés **en base locale** (le seed n'en porte qu'un par
catégorie ; `restauration` est la seule catégorie seedée `mixable = false`).

| Scénario | Résultat |
|---|---|
| **2 vendeurs** | ✅ Proposition, acceptation, **deux frais de 150 FCFA chiffrés séparément** (la tournée unique n'en montrait qu'un), « Commander · 4 300 FCFA » = somme des deux, **2 commandes** créées, **2 codes distincts** (7204 / 1652), une livraison chacune |
| **3 vendeurs** | ✅ « Scinder en **3** commandes », « **3 commandes, 3 frais de déplacement.** », trois récapitulatifs (150 / 150 / 175), **aucun débordement** en 360 dp |
| **Échec partiel** | ✅ Article du 2ᵉ tronçon rendu indisponible entre acceptation et confirmation : « 1 commande sur 3 a été créée. » + « 2 commandes n'ont pas pu être créées. » — la série s'est **arrêtée au premier refus**, le 3ᵉ tronçon n'a jamais été tenté (vérifié en base) |
| **Reprise** | ✅ Après rétablissement, « Reprendre le reste » crée les deux manquantes avec **leurs clés d'origine** : trois commandes en base, **aucun doublon** (R7) |

**Un défaut trouvé sur l'appareil, corrigé** : le titre disait « Commande
confirmée » au **singulier** au-dessus de deux codes de remise — le contraire de
ce que l'écran montrait. La clé prend le nombre ; test widget ajouté.

Deux constats d'environnement sont devenus des points ouverts (n° 8 et n° 9) :
l'absence de contrôle de propriété au rejeu, et le choix du transport par
« premier actif de la zone » qui fait échouer toute tournée de plus de 800 m.

## Suites de la passe émulateur

### La fuite de secrets au rejeu est fermée (bloquant)

L'`Idempotency-Key` **EST** l'identifiant de la commande, et
`relire_commande_creee` filtrait sur `WHERE c.id = $1` seul : un compte `Client`
qui connaissait l'identifiant d'une commande d'autrui recevait un `200` portant
son `code_livraison` et son `jeton_reception` — les deux valeurs qui font
remettre la marchandise, que R6 réserve au propriétaire.

Le `client_id` est **lu, pas ajouté au `WHERE`** : la même lecture sert de sonde
d'existence, et l'usurpation est refusée AVANT les validations et l'appel de
routage. **404, jamais 403** — dire « ce n'est pas la vôtre » confirmerait que
la commande existe, ce qui est déjà une fuite ; c'est la règle que tient déjà
`GET /commandes/{id}`.

Le test a été **vérifié en neutralisant le contrôle** : sans lui, l'intrus reçoit
un `200` avec le code `8836` et le jeton en clair. Il asserte le 404, l'absence
des DEUX secrets dans le corps, qu'aucune commande n'est créée, et que le
propriétaire rejoue toujours (R7 intact). Un second test couvre le refus au
niveau du domaine.

### Clippy redevient vert

Ils étaient **neuf, pas cinq** : clippy s'arrête au premier crate en échec, et
`prestataires` cachait `commandes`. Six `too_many_arguments` (`#[allow]`
justifié au cas par cas, comme `PgCommandes::new` l'avait déjà tranché), deux
`items after a test module` (bloc déplacé), deux `doc_lazy_continuation` (une
ligne de doc commençant par `+` était lue comme une puce Markdown). Que des
attributs, des commentaires et un déplacement de bloc.

### Un trajet sans tarif est un refus, pas une panne

`ErreurTarif::AucuneRegle` tombait dans `Dependance`, donc en 500, donc en
« Une erreur est survenue ». La grille d'une zone est **bornée** en distance et
en véhicule : un trajet hors bornes n'a pas de prix, et TRF a raison de ne
jamais en inventer un. Variante `TarifIndisponible`, **409** (la demande est
bien formée, c'est l'état qui s'y oppose et le client peut agir dessus), clé
`tarif_indisponible`, et une phrase qui dit son LEVIER : « Retirez un vendeur
éloigné ». Les autres erreurs de TRF restent techniques, un test le fige. Le
**choix du véhicule** reste un point ouvert pour TRF (n° 9).

## Commits

```
37809a5  feat(commandes): CMD-01 un trajet sans tarif est un refus, pas une panne
6d83271  chore(backend): clippy --all-targets -D warnings redevient vert
0b12bf6  fix(commandes): CMD-03 le rejeu ne sert ses secrets qu'au propriétaire
766de2c  docs(commandes): rapport et tasks à jour
4db60dd  fix(commandes): CMD-01 le titre de confirmation compte les commandes
ad7df7f  feat(commandes): CMD-03 la livraison devient un composant optionnel
dd6ba61  feat(commandes): CMD-01 accepter la scission — N commandes, N clés
26ad6ee  feat(commandes): T067 alerte outbox du code de remise épuisé + clôture
9449df1  test(commandes): T067 câblage du parcours couvert, deux défauts d'UI corrigés
8a1b4ce  feat(commandes): T067 parcours client — accueil, vendeur, panier, suivi
91b9b9e  feat(commandes): T067 couche d'appel CommandesApi et cache de commande
```

(+ un `chore` alignant le lockfile de `mefali_pro`.)

## Checklist de fin de cycle

- [x] Critères d'acceptation des stories couverts par des tests — 488 backend, 57 + 95 Flutter (17 tests neufs sur le câblage, 8 sur la scission, 4 sur la livraison optionnelle)
- [x] Annotations utoipa à jour ; clients Dart/TS régénérés, **aucun diff**
- [x] Migrations sqlx versionnées ; `cargo sqlx prepare` vert ; seeds à jour
- [x] Événements outbox émis pour chaque transition ; événements de métriques déclarés — **28**
- [ ] **Aucun paramètre métier en dur** — voir point ouvert n° 1
- [x] Montants en entiers + devise ; aucun chemin de paiement partiel possible
- [x] Actions offline idempotentes (UUID) — clé d'idempotence stable, prouvée par test
- [ ] **UI conforme aux captures `docs/design/png/`** — voir point ouvert n° 6
- [ ] **Rien construit au-delà du périmètre** — voir point ouvert n° 7

## Points ouverts

1. **`commande.repere_texte_min_caracteres` n'est pas servi au client.** La
   liste blanche de `/config` n'expose que `client.*`, or ce paramètre vit dans
   `commande.*`. L'app garde son défaut de 10 — le serveur reste seul juge, et
   la garde locale n'évite qu'un aller-retour. À combler par une **vue dérivée**
   au prochain cycle touchant ZON.
2. **`en_route → collecte` refusé** (data-model §3.3) — **à signaler au
   produit** : un coursier qui a tapé « je pars » doit taper « je suis arrivé »
   avant de scanner, sinon `arrive_le` manque et la prime d'attente TRF-06 est
   perdue. Rien élargi sans arbitrage.
3. **`coursier.prenom` et `coursier.note` restent `null`** : `comptes` ne stocke
   aucun nom et le cycle AVI n'existe pas. Rien inventé — à combler par CPT et
   AVI.
4. **Le bloc « À la livraison » reste affiché sur une commande livrée**, avec
   son code. Sans conséquence (la commande est close), mais le code n'a plus
   d'objet : à masquer quand `etat == terminee`.
5. **La découverte des vendeurs n'existe pas** et n'a pas été construite :
   aucune route publique de recherche (`GET /prestataires/{id}` seul). L'accueil
   ouvre une fiche **par son lien de plaque ou son identifiant** — le canal que
   le produit prévoit (page `mefali.com/v/{id}`, plaque). Le tri par distance et
   fiabilité appartient à **VND**.
6. **L'accueil, la fiche vendeur et l'état « scission acceptée » n'ont aucune
   maquette** dans `docs/design/png/` — C3-3d ne montre que la *proposition*.
   Ils suivent les tokens, rien de plus.
7. **Trois ajouts dépassent la lettre des tâches** : accueil, fiche vendeur et
   `AdressesApi`. Sans eux le parcours n'existe pas, mais aucune tâche ne les
   demandait.
8. ~~**Le rejeu idempotent ne vérifie pas la propriété de la commande**~~ —
   **RÉSOLU** le 2026-07-26 (commit `0b12bf6`), voir
   [la section](#la-fuite-de-secrets-au-rejeu-est-fermée-bloquant). Le contrôle
   ne coûte aucune requête de plus et refuse l'usurpation avant les validations.
9. **L'app demande TOUJOURS le premier transport actif de la zone**
   (`ActionsCommande.transportDemande`), sans regarder la distance. Constaté à
   la passe émulateur : `a_pied` en tête, dont la règle plafonne à 800 m, fait
   répondre `500 « aucune règle tarifaire applicable »` dès que la tournée est
   plus longue — et l'app n'affiche qu'« Une erreur est survenue ». Contourné en
   local en mettant `moto` en tête. Le refus, lui, est désormais **lisible**
   (409 `tarif_indisponible`, commit `37809a5`) ; c'est le **choix du véhicule**
   selon distance et charge qui reste ouvert, et il appartient à **TRF/produit**.
10. **`livraison.etat` du corps de création est la constante `"assignee"`**
    (`commandes_http.rs`), jamais l'état réel lu en base : le rejeu d'une course
    déjà partie annonce donc un état faux. Écart **préexistant**, reconduit à
    l'identique par le regroupement de la livraison plutôt que corrigé en
    passant — le lire changerait le corps du `200`. **À trancher** : aucun test
    ne compare le corps du `201` et celui du `200`.

    *(L'autre écart de ce couple, `devis.ordre_arrets` vide au rejeu, n'en est
    plus un : le contrat le DIT désormais — l'ordre est figé sur les arrêts, pas
    sur la livraison, et le rejeu ne paie pas une lecture de plus pour une
    valeur déjà servie au `201`.)*
11. **La liste d'accueil n'est pas rafraîchie après création.**
    `mesCommandesProvider` garde sa valeur en cache tant que l'accueil reste
    monté : revenir dessus après avoir commandé montre la liste d'avant jusqu'au
    tirer-pour-rafraîchir. Antérieur à cette reprise, mais plus visible avec N
    commandes. Le corriger proprement demande de sortir ce provider de
    `accueil.dart` (il rend un type d'`actions_commande.dart`) — refactor non
    demandé, laissé à l'arbitrage.

## Pièges d'environnement payés (ne pas les repayer)

- **Aucun panier multi-vendeurs n'est possible avec le seed** : il ne porte
  qu'UN vendeur par catégorie, et la scission en exige deux dans une même
  catégorie **non mixable** — `restauration` est la seule seedée `mixable =
  false`. Deux restaurants ont été ajoutés **en base locale** (préfixe
  `019de000-…`, retirables d'un `DELETE`), avec site, horaires 7j/7 et articles.
- **`transport.actifs` mis à `["moto", …]` en base locale** : l'app demande le
  PREMIER transport actif, et la règle `a_pied` plafonne à 800 m — au-delà, le
  devis répond `500 « aucune règle tarifaire applicable »` (point ouvert n° 9).
- **`drapeau.livraison_offerte_mefali` mis à `false` en base locale** : à `true`
  (valeur du seed) tous les frais de livraison valent 0, et « N frais de
  déplacement » ne se vérifie pas à l'œil.
- **`adb shell input text` AJOUTE au contenu du champ** au lieu de le remplacer,
  et `identifiantVendeur` prend la PREMIÈRE correspondance : deux identifiants
  saisis à la suite rouvrent le premier vendeur. Vider le champ (≈45 `keyevent
  67`) avant chaque saisie, sinon le panier composé n'est pas celui qu'on croit.
- La démo tombait un **dimanche** : les horaires du seed couvrent lun–sam, donc
  boutiques **fermées** — comportement correct. Le dimanche a été ouvert **en
  base locale**, sans toucher au seed versionné. La bascule admin « ouvrir » ne
  suffit pas : hors horaires, l'état effectif reste fermé.
- **Plafond OTP par numéro ≈ 50 min** : trois codes faux détruisent le défi
  **et** bloquent le renvoi, pendant que l'écran DEV continue d'afficher le
  dernier code tracé — donc périmé. Purger `otp:sms:*` / `otp:ip:*` dans Redis
  en dev. *(L'écran DEV devrait dire que le renvoi a été refusé plutôt que
  d'afficher un code mort.)*
- L'émulateur manquait d'espace pour un APK debug de 251 Mo : désinstaller
  d'abord les vieux paquets (`com.mefali.mefali_b2c`, `_b2b`).
- Régler la position de l'émulateur sur Tiassalé
  (`adb emu geo fix -4.8210 5.8960`), sinon le pin part de Mountain View.
- `adb shell input text` **coupe aux espaces** — saisir sans espaces.
- Affecter un coursier **directement en base** laisse le tronc en `nouvelle` et
  fait refuser la remise : `nouvelle → terminee` n'est pas dans la table fermée,
  et c'est la table qui a raison.
- **2 tests `mefali_pro` (`routeur_roles_test.dart`) échouent déjà sur `main`** —
  pas une régression de ce cycle.

## Reste à faire côté machine

L'API de validation tourne encore sur le port 8080 :

```bash
pkill -f 'target/debug/api'
```
