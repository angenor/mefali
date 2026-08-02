# Rapport d'écarts — cycle PAY 011 (paiements cash & prépaiement)

Ce que le cycle **n'a pas fait comme prévu**, et pourquoi. Chaque écart est à
porter au produit, pas à contourner en silence : un écart tu devient une dette
dont personne ne connaît le prix.

Quatre familles : les **défauts trouvés sur appareil** (§1) — dont un corrigé
dans la foulée —, les **limites déférées** à un module non construit (§2), les
**décisions prises en cours d'implémentation** (§3), et les **réserves
ouvertes** (§4).

Méthode : T085 déroule `quickstart.md` §4 sur émulateur Android (Medium Phone
API 36.1), API en mode `PAIEMENT_FOURNISSEUR=simule`, base seedée, zone
Tiassalé. Le fournisseur simulé sert une URL `paiement.invalid` : le navigateur
s'ouvre réellement, la page n'existe pas — c'est la limite §2.1.

---

## 1. Défauts trouvés sur appareil

### 1.1 Le suivi ne relisait la session qu'UNE fois — CORRIGÉ

**Ce qui a été observé** : une commande de 18 000 F (au-dessus du plafond cash
de 15 000) est payée ; le serveur passe la commande en `en_attente_coursier`,
`etat_paiement = regle`, transaction `reglee`, moyen `wave`. L'écran de suivi,
lui, continue d'afficher **« En attente de votre paiement »**, le compte à
rebours qui descend, et le bouton **« Reprendre le paiement »** — plus de trois
minutes après la confirmation, y compris après avoir quitté puis rouvert
l'écran.

**Pourquoi** : [`pages_commande.dart`](../../apps/mefali_client/lib/parcours/pages_commande.dart)
portait un garde `_paiementDemande` qui n'autorisait qu'**une seule** lecture
de `GET /commandes/{id}/paiement`. Ce garde évitait un vrai problème (le compte
à rebours se recalait à chaque frame et ne bougeait plus), mais il fermait
définitivement le seul chemin par lequel l'app apprend qu'un paiement est
arrivé — ce que le commentaire de `relirePaiement` énonce pourtant
explicitement. `SessionPaiement` étant `keepAlive`, l'état figé survivait même
à la fermeture de l'écran.

**Conséquence pour Awa** : elle a payé, son application lui redemande de payer,
avec un minuteur qui l'y presse. Le bouton rouvre une session — donc
**invite au double débit**. Symétriquement, l'annulation par expiration
n'apparaissait jamais **d'elle-même** (FR-017, geste 3 du quickstart), puisque
rien ne relisait.

**Ce qui a été livré** : une **sonde** de 10 secondes, active tant que la
commande attend son règlement, qui relit la session ET le suivi, puis s'arrête
dès que la session ne bouge plus (`reglee`, `expiree`, `payee_hors_delai`). Le
tic local continue de faire descendre le compte à rebours entre deux recalages
— ce que `SessionPaiement.poser` décrit déjà comme le partage des rôles.

**Ce qui le tient** : `test/parcours/sonde_paiement_test.dart`, trois tests qui
**échouent tous les trois** si la sonde est neutralisée (vérifié). Le geste 3
a été rejoué sur appareil avec `paiement.session_duree_s` abaissé à 90 s : le
suivi affiche de lui-même « Le délai de paiement est écoulé. Votre commande a
été annulée, sans aucun frais. » et propose « Recommander ».

### 1.2 L'écran de confirmation s'intercale sur une commande NON payée

**Ce qui a été observé** : après « Commander » sur une commande prépayée,
l'app affiche « Commande confirmée » avec le bloc **« À la livraison »**, le QR
et le code de remise — puis un bouton **« Suivre ma commande »**. Le règlement
n'est atteint qu'en touchant ce bouton.

**Pourquoi** : `_apresCreation` route bien vers le règlement quand
`creee.attendPaiement` (l'intention est documentée dans le code), mais elle est
branchée sur le `onSuivre` de l'écran de confirmation, dont le libellé est
constant.

**Conséquence** : la cliente vient de choisir « mobile money » plutôt
qu'« espèces à la livraison », et l'écran suivant lui montre « À la livraison »
en gros, avec un code de remise. Rien ne dit qu'un paiement est attendu, ni que
la commande expirera dans 15 minutes. Le parcours n'est pas bloqué — il est
trompeur, sur un chemin d'argent à échéance.

**À décider par le produit** : soit l'écran de confirmation est sauté quand la
commande attend un règlement (le plus simple), soit son libellé et son contenu
s'adaptent (« Payer maintenant » plutôt que « Suivre ma commande », pas de code
de remise tant que rien n'est payé).

**Non corrigé dans ce cycle** : le correctif touche l'enchaînement du parcours
CMD 008, hors périmètre PAY, et mérite une décision produit plutôt qu'un
arbitrage d'implémentation.

### 1.3 Une commande en attente SANS session ouverte laisse le suivi muet

**Ce qui a été observé** : une commande `en_attente_paiement` pour laquelle
aucune session n'a encore été ouverte (l'app a été fermée avant que l'écran de
règlement ne s'ouvre) affiche un suivi **sans aucun bandeau** : ni « en
attente », ni bouton pour payer. `GET /commandes/{id}/paiement` rend `404`, et
le bandeau reste muet — comportement voulu pour une commande cash, mais qui
laisse ici la cliente sans chemin vers le règlement depuis le suivi.

**Conséquence** : la commande expirera sans que rien à l'écran n'ait expliqué
pourquoi, ni proposé d'agir.

**À décider par le produit** : le suivi d'une commande `en_attente_paiement`
devrait ouvrir la session lui-même (comme le fait `PagePaiement`) plutôt que de
se taire sur un `404`.

### 1.4 Le bloc « À la livraison » s'affiche sur une commande annulée

**Ce qui a été observé** : après annulation pour délai écoulé, le suivi
continue d'afficher le QR et le code de remise sous le titre « À la livraison ».
L'écran de confirmation de cette même commande reste accessible et se ré-affiche
avec son code.

**Conséquence** : un code qui n'ouvre plus rien reste présenté comme valide.
C'est mineur — le bandeau d'annulation, lui, est parfaitement clair — mais un
code de remise sur une commande morte n'a pas de raison d'être montré.

### 1.5 Le titre « À la livraison » est ambigu dans un parcours prépayé

La clé `suiviALaLivraison` est documentée comme le « titre du bloc code + QR de
remise » : elle désigne le **moment de la remise**, pas le mode de paiement. Sur
un parcours où la cliente vient d'arbitrer entre « Espèces à la livraison » et
« Mobile money », le même vocabulaire réapparaît au-dessus d'un code, avec un
sens différent. Aucun bug, un mot à revoir.

### 1.6 Deux types revendiquaient le nom de schéma `OffreLivraisonVendeur` — CORRIGÉ

**Ce qui a été observé** : le vendeur règle son offre de livraison, touche
« Enregistrer », et lit **« Impossible de charger la boutique. »** Le réglage
est pourtant **enregistré en base** (`au_dela`, seuil 10 000, vérifié).

**Pourquoi** : `vendeur_http::OffreLivraisonDto` (nouveau, ce cycle) déclarait
`#[schema(as = OffreLivraisonVendeur)]` — un nom **déjà pris** par l'entrée de
calcul de `tarification` (`admin_tarification_http`), dont la forme est tout
autre (`toujours`, `au_dela`). Deux types qui revendiquent le même nom n'en
laissent qu'un dans `openapi.json` : le client Dart généré désérialisait donc
la réponse de `PUT /vendeur/prestataires/{id}/offre-livraison` avec le **mauvais
modèle**, et échouait systématiquement. `declarer` traduisait cette
`DioException` en refus, et l'écran affichait un message d'erreur sur un geste
réussi.

**Conséquence pour le vendeur** : il croit son réglage refusé. Il recommence,
ou renonce — et son offre de livraison reste, à ses yeux, jamais prise en
compte. Aucun test ne le voyait : les tests backend n'utilisent pas le client
généré, et les tests widget bouchonnent le transport.

**Ce qui a été livré** : le schéma du DTO de réponse est renommé
`OffreLivraisonReglee` (le nouveau cède le nom, pas l'ancien déjà consommé), le
contrat et les clients sont régénérés, et un commentaire dans
[`vendeur_http.rs`](../../backend/api/src/vendeur_http.rs) explique pourquoi ce
nom ne doit pas revenir.

**À retenir** : rien n'empêche aujourd'hui une seconde collision. Un contrôle
mécanique de l'unicité des `#[schema(as = …)]` serait le vrai correctif — porté
en réserve §4.7.

### 1.7 Le rechargement se faisait depuis un porteur auto-dispose — CORRIGÉ

**Ce qui a été observé** : le nom de schéma corrigé, l'enregistrement réussit —
mais la feuille **reste figée** sur son état de chargement, options grisées,
indéfiniment. Le réglage est en base ; le vendeur n'en sait rien.

**Pourquoi** : `OffreLivraison.declarer` rechargeait le pilotage
(`ref.read(pilotageProvider.notifier).recharger()`) **après** l'aller-retour
réseau. Ce porteur est `@riverpod` nu — auto-dispose — et sa portée meurt avec
la feuille : le `ref.read` lève alors une `UnmountedRefException`, qui n'est
**pas** une `DioException` et traverse donc le `catch`. La future d'où dépend
la fermeture de la feuille ne se résout jamais.

Ce défaut existait depuis T062 mais était **masqué** par §1.6 : l'appel échouait
plus tôt, sur la désérialisation. Corriger le schéma l'a révélé — y compris
dans `offre_livraison_test.dart`, qui passait jusque-là par le mauvais chemin
et a échoué dès la régénération.

**Ce qui a été livré** : le rechargement est remonté dans
[`ecran_boutique.dart`](../../apps/mefali_pro/lib/vendeur/boutique/ecran_boutique.dart),
dont la portée survit à la feuille. `declarer` ne fait plus que déclarer.
Vérifié sur appareil : la feuille se ferme, et la carte affiche la **nouvelle**
valeur (« Sur toutes les commandes », confirmée en base).

### 1.8 Un coursier sans véhicule déclaré est bloqué sans issue

**Ce qui a été observé** : le coursier de démo, rôle validé, ne peut pas passer
en ligne : « Déclarez un véhicule pour recevoir des courses. » Le bandeau
n'offre **aucune action**, et aucun des trois onglets (Tableau, Courses, Caisse)
ne mène à cette déclaration — elle n'existe que dans le formulaire de dossier
d'inscription, qu'un coursier déjà validé ne repasse jamais.

**Conséquence** : le blocage est nommé, mais rien ne permet de le lever depuis
l'application.

Relève du cycle CRS/CPT, pas de PAY. C'est ce qui a empêché de dérouler les
gestes 5 et 6 (voir §2).

### 1.9 Le devis absent laisse l'écran de panier entièrement vide

Entre l'ouverture du panier et l'arrivée du devis, l'écran ne montre **rien** :
ni contenu, ni chargement, ni message. Tout le corps est conditionné à
`devis != null`. Observé pendant l'attente d'un devis retardé par une demande de
permission. Relève du cycle CMD 008 ; consigné ici parce que la validation
d'appareil l'a rencontré.

---

## 2. Les huit gestes, un par un

| # | Geste | Résultat |
|---|---|---|
| 1 | Commander au-dessus du plafond, payer | **Partiel.** Espèces grisées avec le motif (« Espèces indisponibles au-dessus de 15 000 FCFA »), mobile money proposé, session ouverte, **le navigateur système s'ouvre** (`url_launcher` vérifié). « Tous les moyens y sont » **non validable** : le double sert `https://paiement.invalid/…`, la page n'existe pas. |
| 2 | Tuer l'app pendant le paiement, la rouvrir | **Validé.** Le suivi montre « En attente de votre paiement », le temps restant, et « Reprendre le paiement » (FR-016). |
| 3 | Laisser expirer, écran allumé | **Validé après correction §1.1**, avec `paiement.session_duree_s` abaissé à 90 s : « Le délai de paiement est écoulé. Votre commande a été annulée, sans aucun frais. » + « Recommander ». Aucun jargon de paiement. |
| 4 | Couper le réseau après avoir payé, le rétablir | **Partiel.** Le chemin serveur est vérifié de bout en bout : notification signée acceptée (`traite: true`), rejeu refusé (`motif: rejeu`), commande passée en `en_attente_coursier` / `etat_paiement = regle` / moyen `wave`. La **coupure réseau elle-même** n'a pas été rejouée. |
| 5 | Côté coursier, course prépayée : « rien à encaisser » | **NON DÉROULÉ.** Le coursier de démo ne peut pas passer en ligne (§1.8), donc aucune course active. Couvert par `coursier_positions.rs` et les tests widget, pas par l'œil. |
| 6 | Côté coursier, arrêt avec retenue | **NON DÉROULÉ.** Même cause, plus un prérequis : une commande passée **après** l'activation de l'offre vendeur. |
| 7 | Ouvrir la caisse après une journée mixte | **Partiel.** Les trois positions sont là, séparées et lisibles d'un coup d'œil, en langage courant (« Avancé, non récupéré », « Mefali me doit », « Je détiens pour Mefali »). Toutes à **zéro** : aucune course livrée, faute de §1.8. La lisibilité de valeurs non nulles reste à voir. |
| 8 | Côté vendeur, activer l'offre de livraison | **Validé après corrections §1.6 et §1.7.** Les trois choix, la saisie du seuil, le rappel « Les commandes déjà passées ne changent pas de prix » (FR-048). Enregistrement → feuille fermée → carte à jour, cohérente avec la base. |

### Ce qui reste non validable ce cycle

| Non validé | Pourquoi | Quand le valider |
|---|---|---|
| La page de paiement du fournisseur, et « tous les moyens y sont » | Aucun agrégateur choisi (cadrage §10.7). | à la sélection du prestataire — recette du fournisseur, sur appareil |
| Le retour depuis le navigateur | Même raison : sans page réelle, il n'y a pas de retour à observer. | idem |
| Les gestes 5, 6 et la caisse non nulle | §1.8 — aucun coursier ne peut passer en ligne | dès que la déclaration de véhicule est atteignable |
| iOS | Xcode/CocoaPods non installés | quand l'environnement sera monté |

---

## 3. Décisions prises en cours d'implémentation

### 3.1 `acces_paiement` est CONSERVÉ sur l'état `echouee`

`data-model.md` §6 disait « effacé dès que l'état quitte `ouverte` ». L'effacer
rendait le « réessayez » de FR-026 inopérant : un refus d'opérateur ne clôt pas
la session, il invite à recommencer — encore faut-il que l'accès existe encore.
Écart assumé, trouvé par test.

### 3.2 Le rechargement d'un écran appartient à l'écran

Trouvé en §1.7, mais la règle dépasse ce cas : un porteur **auto-dispose** ne
doit pas, après un `await`, toucher un `ref` qui peut avoir été détruit. Le
geste appartient au notifier ; le rafraîchissement de la vue appartient à
l'écran, dont la portée survit à une feuille modale.

### 3.3 La sonde de règlement bat toutes les 10 secondes

Ni un flux poussé (aucun canal temps réel dans le produit), ni une lecture par
frame (le compte à rebours ne bougerait plus). Dix secondes : un paiement
confirmé se voit sans avoir à ressortir de l'écran, et une attente de quinze
minutes coûte 90 requêtes, pas 900. La sonde s'arrête dès que la session est
close, et à la fermeture de l'écran.

---

## 4. Réserves ouvertes

1. **Aucun contact avec le réel.** `simule.rs`, `AgregateurHttp` et
   `FournisseurAlternatif` valident la FORME de l'abstraction, pas son contact
   avec un vrai fournisseur — aucun sandbox n'existe, l'agrégateur n'étant pas
   choisi (cadrage §10.7). Leçon du cycle CRS 010 : neuf défauts invisibles de
   758 tests attendaient la première exécution réelle. Ce cycle vient d'en
   ajouter la preuve — le défaut §1.1 était invisible de 957 tests backend et
   de 331 tests Flutter.
2. **Webhook** : si `confirmer_prepaiement` échoue APRÈS le commit du paiement,
   l'argent est encaissé et la commande reste `en_attente_paiement`. Journalisé
   en `error`. Ordre délibéré : l'inverse annulerait une course commencée.
3. **Expiration** : si `annuler_pour_expiration` échoue APRÈS le commit, la
   commande reste `en_attente_paiement` avec une transaction `expiree`, et le
   balayage ne la reverra pas. Journalisé en `error`.
4. **SC-004** : cent signatures invalides du MÊME corps ne laissent qu'UNE
   trace — l'unicité inclut l'empreinte. Voulu.
5. **Le reçu vendeur (T063) n'a aucun point d'entrée dans l'app** : la liste des
   commandes entrantes relève de VAP-01, non construit. L'écran s'ouvre par
   `MaterialPageRoute` depuis l'appelant.
6. **Débordement `verifier-accord-locks`** : les trois plugins natifs de
   `mefali_pro` plus `url_launcher` de `mefali_client` sont figés par lockfile.
   Aucun d'eux n'est patchable par Shorebird — l'écran de paiement compris.
7. **Rien n'empêche une seconde collision de nom de schéma.** §1.6 a été trouvé
   par hasard, sur appareil. Deux `#[schema(as = …)]` homonymes produisent
   silencieusement un client faux, qu'aucune suite ne traverse. Un contrôle
   mécanique (script CI comparant les `as = …` du workspace) fermerait la
   famille entière ; il n'est pas écrit.
8. **Les gestes 5 et 6 restent non vus.** Ce que le cycle CRS 010 a appris —
   neuf défauts invisibles de 758 tests — vaut ici : la caisse à trois positions
   et la retenue à l'écran n'ont **jamais** été regardées avec des montants
   réels. C'est la zone d'ombre la plus large de ce cycle.
