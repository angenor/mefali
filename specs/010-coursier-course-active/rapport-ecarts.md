# Rapport d'écarts — cycle CRS 010 (app coursier)

Ce que le cycle **n'a pas fait comme prévu**, et pourquoi. Chaque écart est à
**porter au produit**, pas à contourner en silence : un écart tu devient une
dette dont personne ne connaît le prix.

Trois familles : les **écarts de maquette** (§1), les **limites déférées** à un
module non construit (§2), et les **décisions prises en cours
d'implémentation** (§3) — celles qui ne contredisent aucune spec mais que
personne ne pourrait deviner en relisant le code.

---

## 1. Écarts avec les maquettes

### 1.1 K1-1c « paie fixe » — hors produit, pas hors périmètre

**Ce que la maquette demande** : `K1-disponibilite.png` état 1c affiche
« Livraisons offertes — paie fixe en cours : 800 FCFA / course livrée » et
« 3 courses × 800 FCFA (paie fixe) ».

**Ce qui est livré** : le bandeau montre la **somme des parts coursier** des
courses livrées du jour, calculée sur le devis figé du cycle 007.

**Pourquoi** : la promotion de lancement est nommée « **hors produit** » par
`docs/user-stories-v2.md` (module CRS, note de fin) et par le cadrage §7.1 :
engagement opérationnel, présence vérifiée par les heartbeats DSP-01 déjà
livrés, paie **manuelle**. Il n'existe donc ni tarif de paie fixe en base, ni
règle qui dise quand elle s'applique. Le construire reviendrait à inventer les
deux.

**Conséquence pour Yao** : pendant la promotion, le bandeau affiche ce que le
produit sait calculer, pas ce que l'agence lui versera. L'écart est réel et
doit être expliqué au coursier à l'oral — c'est déjà le cas pour la paie.

**À décider par le produit** : modéliser la paie fixe (un paramètre de zone et
une règle de tarification), ou l'assumer comme un versement hors plateforme.

### 1.2 « Note du jour 4,8 / 5 » — un tiret plutôt qu'un chiffre inventé

**Ce que la maquette demande** : une tuile « Note du jour » sur K1-1a et 1b.

**Ce qui est livré** : la tuile existe, sa valeur est un **tiret**
(`crsJourneeNoteAbsente`). L'API rend explicitement `note_centiemes: null`.

**Pourquoi** : le module d'avis (AVI) n'est pas construit. Le cycle 009 avait
déjà tranché la même question pour le plafond d'avance : l'absence vaut mieux
qu'un chiffre inventé. Un « 5,0 / 5 » par défaut apprendrait à Yao à ignorer la
note le jour où elle deviendra réelle.

**À décider par le produit** : rien — l'écart se referme quand AVI arrive.

### 1.3 K5-1a « Signaler ou bloquer » et la feuille K5-1d — CRS-07

**Ce que la maquette demande** : une carte « Signaler ou bloquer — un client ou
un vendeur, traité par l'agence » sur K5-1a et 1c, et la feuille basse 1d
(5 motifs, commentaire libre, envoi à l'agence).

**Ce qui est livré** : **rien**. La caisse s'arrête aux indemnisations.

**Pourquoi** : **CRS-07** est P1, tranche T4 (`docs/cadrage-v5.md`). Il n'existe
aucun endpoint de signalement, aucune table, aucun destinataire côté agence.
Poser l'écran sans le chemin serveur donnerait un bouton qui ne fait rien —
pire qu'un bouton absent, parce qu'un coursier agressé croirait avoir signalé.

**Conséquence pour Yao** : le chemin reste le téléphone de l'agence, déjà servi
par K4-1d (blocage du code) et par les deux clés `texte.*` de contact au niveau
ville posées au cycle précédent.

**À décider par le produit** : ordonnancer CRS-07.

### 1.4 K4-1a « lien de paiement sur place » — PAY-03

**Ce que la maquette demande** : proposer au client un lien de paiement mobile
money quand il n'a pas l'appoint.

**Ce qui est livré** : le renvoi au chemin de secours (arbre d'échec §7.5-5,
« sans appoint »), sans lien.

**Pourquoi** : **PAY-03**, P1, tranche T3 (FR-050). Aucun fournisseur n'est
intégré, et la constitution III interdit tout chemin de paiement partiel.

### 1.5 Le nom d'usage du client et la distance inter-arrêts — absents en donnée

**Ce que la maquette demande** : « Awa K. » sur K4-1a, et « + 40 m » entre deux
arrêts sur K3.

**Ce qui est livré** : `client.nom_usage = null` et
`arret.distance_precedent_m = null` — les deux champs existent au contrat, ils
ne sont simplement jamais remplis.

**Pourquoi** : le cycle CPT 003 a tranché « un numéro vérifié, rien d'autre » —
aucun nom d'usage n'est collecté nulle part. La distance inter-arrêts, elle,
n'est pas décomposée par le devis figé (cycle 007), qui ne porte qu'une
distance totale ; la recalculer violerait FR-009.

**Conséquence** : K4-1a affiche le repère et l'heure d'arrivée, jamais un nom
fabriqué. Le même vide se retrouve dans l'**exposition admin**, où la colonne
`nom` est vide — l'exploitation identifie par identifiant.

**À décider par le produit** : collecter un nom d'usage (CPT), ou assumer.

### 1.6 K5-1c « L'agence vous rappelle avant 17 h » — sans l'heure

**Ce que la maquette demande** : un engagement de rappel horodaté.

**Ce qui est livré** : « Indemnisation demandée : {montant}. L'agence vous
rappelle. »

**Pourquoi** : aucun délai de traitement n'est tenu en base (AVI-04 n'existe
pas). Afficher « avant 17 h » serait une promesse que rien ne garantit — et
qu'aucun coursier ne pardonnerait deux fois.

---

## 2. Limites déférées à un module non construit

| Limite | Module | Ce que le cycle fait à la place |
|---|---|---|
| **Avance non soldée sur commande prépayée** (FR-117, R10) | PAY-01/02 | l'avance reste **ouverte** et est **annoncée** comme telle, en caisse comme dans l'historique. La masquer la ferait disparaître de l'écran dont c'est la seule raison d'être |
| Solde et mouvements du **fonds d'incidents** | ADM-07 | les indemnisations sont écrites et décidées par API ; aucun solde de fonds n'est tenu |
| **Seuil d'alerte** sur l'exposition cash | ADM-07 | l'exposition est servie ; l'écart au **plafond du jour** est signalé (FR-078), mais aucun seuil global n'existe |
| Écrans Nuxt d'exploitation | ADM-02/04/07 | les 8 endpoints admin sont exercés **par API** dans les tests, patron du cycle 009 |
| Rattachement d'un **litige** à une indemnisation | AVI-04 | port `LitigesOuverts` + double `AucunLitige` — et c'est **l'état exact du monde**, pas un bouchon : il n'existe aucun litige nulle part |
| Émission du **push** d'offre | NTF-01 | l'app se réveille elle-même (service continu, R12/R13) |

---

## 3. Décisions prises en cours d'implémentation

Celles qui ne contredisent aucune spec, mais que personne ne devinerait.

### 3.1 Session 2 — remise, dépôt et blocage

- **Le blocage du code ne ferme QUE la saisie** (FR-043). Le scan QR reste
  proposé sur K4-1d : le jeton est un aléa long, inattaquable par force brute,
  et fermer les deux voies enfermerait un coursier honnête devant une porte
  ouverte.
- **Migrations 0017 et 0018** créées plutôt que retouche des précédentes
  (constitution I) — une colonne découverte en branchant l'écran ne justifie
  jamais de réécrire une migration appliquée.
- **Deux clés `texte.*` de contact d'agence au niveau ville** : le numéro
  affiché sur K4-1d est un paramètre de zone, pas une constante d'app.
- **`commandes::exploitation`** : les lectures d'exploitation vivent dans leur
  propre module plutôt que d'épaissir `collecte`.
- **`reference_courte` est une fonction Rust**, pas une colonne : une seconde
  colonne à resynchroniser pour une chaîne d'affichage serait une seconde
  vérité.

### 3.2 Session 3 — les preuves

- **Migration 0019** (`coursier.preuves_reunies`) : la mémoire du basculement.
  Sans elle, `preuves_echec.reunies` serait réémis à chaque lecture.
- **`PgCommandes::avec_preuves`** — rebranchement du port **après**
  construction. `coursier` dépend de `commandes`, jamais l'inverse : le port ne
  peut donc pas être injecté au constructeur, et la composition se fait dans
  `api`, qui détient les deux.
- **Garde temporelle de la présence** : un relevé horodaté dans le futur par
  l'appareil ne compte pas (FR-010). Vérifié en T085.
- **Le « trou » de présence n'est PAS servi à l'app** : il n'a aucun usage
  d'affichage. L'app en tient un miroir local (`_trouMaxS = 120` dans
  `etat_preuves.dart`) ; le seul risque est un décompte local légèrement
  optimiste, que le serveur corrige.
- **Le plafond du jour est lu directement dans `dispatch.plafond_jour`**, sans
  port dédié : une arête permanente entre deux domaines pour un seul nombre
  serait un prix trop élevé.

### 3.3 Session 4 — caisse, journée, service continu

- **`GET /moi/journee` est composé DANS LE HANDLER** (contrat §2). Les gains et
  les avances viennent de `coursier`, le plafond retenu et le taux
  d'acceptation de `dispatch`. `dispatch::taux_acceptation_pourcent` devient
  `pub` pour cela — c'est un compteur réellement tenu, et K1 l'affiche
  (FR-093).
- **Le cache de caisse est une table drift à UNE ligne** (`caisse_cache`,
  schemaVersion 8), qui range la vue **telle que le serveur l'a rendue** (JSON).
  Éclater la caisse en colonnes locales créerait une seconde modélisation à
  resynchroniser à chaque évolution du contrat.
- **`EtatCaisse` est `autoDispose`, `EtatJournee` aussi.** Un `keepAlive`
  afficherait un solde périmé au retour sur l'écran, exactement là où la
  fraîcheur compte. Le hors-ligne est couvert par le cache, pas par la durée de
  vie du provider.
- **Le bandeau de gains est SILENCIEUX en cas de coupure** : il s'efface, il ne
  bloque pas K1. C'est l'écran depuis lequel Yao se met en ligne, et le bloquer
  sur un chargement de gains lui coûterait des courses. FR-076 (lecture
  hors-ligne annoncée) vaut pour **K5**, pas pour ce bandeau.
- **Le raccourci Caisse du tableau de bord n'apparaît que si de l'argent est
  engagé.** Une carte « 0 FCFA en main » ne pousserait que vers un écran vide ;
  la barre basse, elle, mène toujours à la caisse.
- **La barre basse suit la course, mais pas l'offre.** Une offre en vol garde
  l'écran entier (40 s pour décider — une barre d'onglets donnerait le moyen de
  la perdre) ; une course active garde la barre et ouvre sur la course.
- **« Passer en ligne » de K5-1b ramène à K1** au lieu de basculer sur place :
  passer en ligne exige un plafond déclaré (`capacite_non_declaree`, cycle
  009), et c'est sur K1 qu'il se règle.
- **Le service continu n'a PAS d'horloge de position.** `EmetteurPosition` est
  observé par l'espace coursier et sa cadence bat déjà à la période de zone. Ce
  qui l'arrêtait écran éteint, c'était la suspension du processus par Android —
  ce que le service empêche. Une seconde horloge doublerait le débit sans rien
  couvrir de plus.
- **Les textes du service sont résolus dans la portée**, pas au point d'appel :
  le service peut devoir notifier alors qu'aucun `BuildContext` n'existe. Les
  chaînes restent dans l'ARB fr ; seule leur résolution change de moment.
- **La garde de cadence de la présence vit dans `EtatPreuves`**, pas au point
  d'appel : deux sources l'appellent (l'écran au premier plan, le service écran
  éteint), et un appelant de plus l'oublierait.
- **`periodeOffreArrierePlan = 5 s` est un miroir local** de
  `coursier.offre_interrogation_arriere_plan_s`. Le paramètre n'est pas servi à
  l'app ; l'écart tolérable est celui d'un réveil, pas d'une décision.

### 3.4 Un défaut de production corrigé en passant

`ValeurInconnue` retombait dans le fourre-tout `500`. Une énumération mal
orthographiée par l'appelant (`?etat=peut-etre`) répondait donc « le serveur est
cassé » là où la demande était simplement invalide. Passée en **422** avec sa
clé i18n `valeur_inconnue`. Trouvé par
`admin_coursier::la_file_des_indemnisations_se_filtre_par_etat`.

---

## 4. Trois plugins natifs, pas deux

Le plan en annonçait **deux** (service de premier plan, notifications locales).
`url_launcher` s'y ajoute — c'est lui qui compose un numéro **sans l'afficher**
(FR-034) et ouvre l'itinéraire. Il était déjà au `pubspec` mais n'avait jamais
été compté comme dépendance native du cycle.

**Conséquence** : la règle du plan reste tenue — les plugins sont ajoutés en une
fois, tôt, et toute la logique reste en Dart. Le passage store était de toute
façon obligatoire.

---

## 5. Non validé visuellement

**T087 (validation sur appareil des six scénarios de `quickstart.md` §3) n'est
pas faite.** Elle exige un appareil ou un émulateur et une API joignable ;
aucun test automatisé ne voit une sonnerie, un écran en plein soleil, ou un
réseau qui tombe pour de vrai.

Ce qui reste donc **non observé** :

| Scénario | Ce qui n'est pas vérifié |
|---|---|
| §3.1 course en plein soleil | lisibilité réelle des montants, ergonomie de la coche |
| §3.2 note vocale hors ligne | lecture du fichier téléchargé en mode avion |
| §3.3 hors-ligne complet | les 2 s de validation locale, le drain à la reconnexion |
| §3.4 réveil écran éteint | **la sonnerie elle-même**, le maintien dans le pool 30 min |
| §3.5 preuves | l'échantillonnage écran éteint sur 10 minutes réelles |
| §3.6 caisse | le solde en conditions réelles |

Le §3.4 est le plus important : c'est la raison d'être d'US7, et le seul
scénario dont aucune partie n'est vérifiable en test. La réserve du cycle 009
sur la bascule K2 → course reste ouverte pour la même raison.
