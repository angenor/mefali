# Cycle 008 (CMD) — rapport de clôture T067

**Branche** `008-commandes-cycle-de-vie` · **2026-07-26** · non fusionnée dans `main`

**68 tâches sur 68 livrées.** `cargo test --workspace` **484 verts**, Flutter
**57 (client) + 94 (core)**, `dart analyze` propre sur les deux paquets,
`cargo sqlx prepare` vert, clients Dart/TS régénérés **sans diff**.

> **Reprise du 2026-07-26** — le dernier geste manquant (accepter la scission)
> est livré. Voir « [La scission est acceptable](#la-scission-est-acceptable-cmd-01-c3-3d) »
> ci-dessous ; le point ouvert n° 1 a disparu.

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

## Commits

```
ee27f0c  feat(commandes): CMD-01 accepter la scission — N commandes, N clés
26ad6ee  feat(commandes): T067 alerte outbox du code de remise épuisé + clôture
9449df1  test(commandes): T067 câblage du parcours couvert, deux défauts d'UI corrigés
8a1b4ce  feat(commandes): T067 parcours client — accueil, vendeur, panier, suivi
91b9b9e  feat(commandes): T067 couche d'appel CommandesApi et cache de commande
```

(+ un `chore` alignant le lockfile de `mefali_pro`.)

## Checklist de fin de cycle

- [x] Critères d'acceptation des stories couverts par des tests — 484 backend, 57 + 94 Flutter (17 tests neufs sur le câblage, 7 sur la scission)
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
8. **`Commande.livraison` est `required` au contrat** (`openapi.json`,
   `components.schemas.Commande.required`), alors que la doctrine tient la
   livraison pour un **composant optionnel 0..n**. Vrai dans le MVP — toute
   commande en a exactement une — mais un retrait sur place casserait le contrat
   avant de casser le tronc. **À arbitrer** au prochain cycle touchant le
   contrat ; rien changé ici, le serveur est clos.
9. **Une proposition de scission imbriquée est ignorée.** Le devis d'un tronçon
   peut lui-même proposer une scission (deux moitiés encore dispersées, cause
   `plafond_eclatement`). L'app ne la présente pas : le client vient d'arbitrer,
   lui reposer la question au même écran serait une boucle. Il la reverra au
   prochain devis du panier. Choix délibéré, à confirmer par l'usage.
10. **La liste d'accueil n'est pas rafraîchie après création.**
    `mesCommandesProvider` garde sa valeur en cache tant que l'accueil reste
    monté : revenir dessus après avoir commandé montre la liste d'avant jusqu'au
    tirer-pour-rafraîchir. Antérieur à cette reprise, mais plus visible avec N
    commandes. Le corriger proprement demande de sortir ce provider de
    `accueil.dart` (il rend un type d'`actions_commande.dart`) — refactor non
    demandé, laissé à l'arbitrage.

## Pièges d'environnement payés (ne pas les repayer)

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
