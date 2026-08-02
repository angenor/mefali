# Crate `paiements` — brancher, et débrancher, un agrégateur

Cycle PAY 011. Ce document répond à une seule question : **que faut-il changer
le jour où l'agrégateur est choisi — et le jour où il change ?**

Le cadrage §10.7 dit le choix non fait. Ce crate est construit pour que ce choix
puisse se faire tard, et se défaire, sans rouvrir la chaîne d'argent.

---

## 1. Ce qu'il faut changer

### 1.1 Trois variables d'environnement

| Variable | Valeur | Effet |
|---|---|---|
| `PAIEMENT_FOURNISSEUR` | `agregateur` | câble `AgregateurHttp` au lieu du double |
| `PAIEMENT_BASE_URL` | l'URL d'API de l'agrégateur | racine des appels sortants |
| `PAIEMENT_CLE_API` | la clé marchande | envoyée en `Authorization: Bearer` |
| `PAIEMENT_WEBHOOK_SECRET` | ≥ **32 octets** | vérifie la signature des notifications |

⚠ `socle::Config::valider` **refuse le démarrage** si `PAIEMENT_FOURNISSEUR`
vaut `agregateur` et qu'une de ces valeurs manque, ou si le secret fait moins de
32 octets (FR-045). C'est délibéré : une API qui démarre à moitié encaisse dans
le vide, et personne ne s'en aperçoit avant le rapprochement de fin de mois.

### 1.2 Deux fonctions de traduction, si le vocabulaire diffère

Dans `src/fournisseur/agregateur.rs` :

- `traduire_issue` — les statuts de l'agrégateur vers `IssuePaiement` ;
- `traduire_moyen` — ses libellés de canal vers `MoyenPaiement`.

Les listes actuelles couvrent les conventions les plus répandues (`SUCCESS`,
`paid`, `FAILED`, `PENDING`…). Un agrégateur qui dirait `04` ou `TXN_OK` ajoute
sa ligne **ici, et nulle part ailleurs**.

⚠ Un statut **inconnu** rend `ChargeIllisible`, il n'est pas deviné. Le traduire
en `EnCours` par défaut ferait traiter un succès comme une attente, donc annuler
une commande payée à l'expiration. Le refus bruyant ouvre un dossier ; le
silence coûte de l'argent.

### 1.3 Une constante, si l'en-tête de signature diffère

`ENTETE_SIGNATURE_AGREGATEUR` dans `backend/api/src/lib.rs` (`"x-signature"`).
Le jour où l'agrégateur est retenu, cette constante devient une quatrième
variable d'environnement — c'est un changement d'une ligne.

### 1.4 Le format de signature, s'il diffère

`SignatureHmac` (dans `src/fournisseur/signature.rs`) implémente
`t=<horodatage unix>,v1=<hex(HMAC-SHA256(secret, "t.corps"))>`, la convention la
plus courante. Un agrégateur qui signerait autrement ajoute son variant **dans
ce module**, que le double et le client de production partagent — deux
vérificateurs auraient divergé, et la suite de tests aurait alors validé la
sécurité du double plutôt que celle du chemin réel.

---

## 2. Ce qu'il ne faut **jamais** toucher

| Ce qui est intouchable | Pourquoi |
|---|---|
| `src/session.rs`, `src/webhook.rs`, `src/expiration.rs`, `src/dossier.rs` | c'est le **domaine**. Aucune de ces lignes ne sait qu'un fournisseur existe, et c'est ce qui rend la bascule possible. |
| Les types de `src/fournisseur/mod.rs` | ils sont **à nous**. Y faire entrer un champ propre à un agrégateur rouvrirait la frontière que tout ce crate existe pour tenir. |
| `paiements.transaction.fournisseur` | une colonne de **rapprochement**, jamais une branche de règle. Aucun `if fournisseur == …` n'existe dans le produit, et aucun ne doit apparaître. |
| Le nom rendu par `PaymentProvider::nom()` | il vaut `"agregateur"`, générique. Le remplacer par le nom du prestataire le ferait entrer dans la base **et** dans une URL publique. |
| Les migrations `0020` / `0021` | constitution I. Un besoin de colonne crée une migration `0022_…`. |

`scripts/verifier-frontiere-paiement.sh` vérifie mécaniquement, en CI, qu'aucun
nom d'agrégateur ni aucun moyen propriétaire n'apparaît hors de
`src/fournisseur/` (T079, SC-010, FR-003) — la liste des noms surveillés vit
dans le script, pas ici. Une frontière qu'on se contente d'affirmer se franchit
au premier correctif pressé.

⚠ **Ce fichier est lui-même soumis au contrôle.** Il ne nomme donc aucun
agrégateur, y compris à titre d'exemple — et c'est le contrôle qui l'a rappelé
en refusant une première version de ce paragraphe.

---

## 3. Comment savoir que la bascule tient

`tests/fournisseur_alternatif.rs` monte un **second** double, incompatible avec
le premier en tout point — en-tête de signature, secret, vocabulaire de statut,
nom des champs, forme de référence, et une échéance annoncée que le premier
n'annonce pas. Il vérifie que ce que le **domaine** reçoit est identique.

C'est la mesure de SC-010. Le jour d'une bascule réelle, la même suite doit
passer avec `AgregateurHttp` pointé sur le sandbox du nouveau prestataire.

⚠ **Réserve ouverte.** Ni `simule.rs` ni `FournisseurAlternatif` n'ont parlé à
un agrégateur réel : ils valident la **forme** de l'abstraction, pas son contact
avec le monde. Aucun sandbox n'est disponible tant que le choix n'est pas fait.
La leçon du cycle 010 vaut mot pour mot ici : neuf défauts invisibles de 758
tests attendaient la première exécution réelle.

---

## 4. Le point d'accroche du routage par moyen (phase 2+)

`POST /paiements/notifications/{fournisseur}` porte un segment de chemin qui
désigne l'implémentation à laquelle déléguer la vérification.

**Il ne porte aucune règle aujourd'hui** (FR-043, FR-113) : un seul fournisseur
est câblé, et un segment inconnu rend `404`. C'est volontairement le strict
minimum — le jour où plusieurs agrégateurs coexisteront (par moyen de paiement,
par zone, ou pour une bascule progressive), la sélection se fera là, et
**seulement là**.

Ce qui existe déjà pour le rendre possible :

- `transaction.fournisseur` porte le nom de celui qui a encaissé, donc une
  notification sait toujours à quel vérificateur elle appartient ;
- `Arc<dyn PaymentProvider>` est injecté par la racine : en faire une carte
  `nom → fournisseur` est un changement local à `api::run`.

Ce qui n'existe **pas**, et qu'il ne faut pas improviser : aucune règle de choix
par moyen, par zone ou par montant. Ce sera une décision produit, pas une
inférence technique.

---

## 5. Ordre des opérations d'une bascule

1. obtenir un accès **sandbox** chez le nouveau prestataire ;
2. ajuster `traduire_issue` / `traduire_moyen` / l'en-tête de signature ;
3. rejouer `cargo test -p paiements` **et** `backend/api/tests/paiements_*.rs`
   avec `PAIEMENT_FOURNISSEUR=agregateur` pointé sur le sandbox ;
4. vérifier que `scripts/verifier-frontiere-paiement.sh` reste vert ;
5. basculer les variables d'environnement en production ;
6. surveiller `GET /admin/paiements/dossiers` — les divergences de montant et
   les notifications orphelines y apparaissent en premier, et c'est là que se
   voit une traduction incomplète.

**Aucune migration, aucun redéploiement d'app.** L'app cliente ouvre une URL que
le serveur lui donne ; elle ne sait rien de qui l'a produite.
