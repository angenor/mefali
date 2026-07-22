# Revue Definition of Done — Phase 8, cycle 005 (VND-01 à VND-04)

Revue menée à T042 (`docs/user-stories-v2.md` §0.4), story par story, sur les six
critères de DoD. Bilan : ce qui est **corrigé** dans ce cycle et ce qui est
**consigné** comme dette assumée à traiter dans un cycle ultérieur.

## Défauts corrigés dans la phase 8

| # | Nature | Gravité | Correctif |
|---|---|---|---|
| 1 | `basculer_disponibilite` sur un article dont le prestataire n'a pas encore de site : l'`UPDATE` ne touchait aucune ligne, mais l'événement `article.mis_en_rupture` était émis quand même (200 mensonger, un événement de plus à chaque rejeu → indicateurs SC-009 empoisonnés). | **Fonctionnel bloquant** | Garde `rows_affected() == 0 → SiteInconnu` avant tout événement (`disponibilite.rs`) ; `definir_site` garnit les disponibilités des articles déjà saisis (`site.rs`) ; test de non-régression (`ruptures.rs::bascule_refusee_tant_que_le_site_manque`) ; 404 documenté sur les deux endpoints utoipa. |
| 2 | Carte horaires V1 : un jour sans plage affichait « Fermé aujourd'hui **aujourd'hui** » (suffixe doublé). | UI | `ecran_boutique.dart` : le cas vide prend sa propre clé ; test widget. |
| 3 | `BasculeStock` : les libellés « En stock » / « Rupture » étaient **rognés** (« En » / « Ruptur ») sur appareil. | UI | `FittedBox(scaleDown)` dans `composants.dart` (géométrie 84×44 de la maquette préservée). |
| 4 | Bascule de disponibilité refusée par le serveur (403 après suspension, 409 verrou admin) : l'échec était **avalé en silence**, la ligne gardait son ancien état sans rien dire. | UI | `try/catch` + SnackBar i18n `proArticleBasculeRefusee` (`ecran_articles.dart`) ; test widget « refus serveur : message, pas de silence ». |
| 5 | `mes_articles.g.dart` périmé (dérive du commit 94be055 VND-04) ; `clients/dart/.openapi-generator/FILES` portait 4 stubs de test périmés (commit 51d634a). | Contrat / codegen | `.g.dart` régénéré ; clients régénérés (déterministes sur 2 passes). |
| 6 | `backend/seeds/README.md` annonçait encore `30_vendeurs.sql` « à venir ». | Doc (DoD 3) | Lignes `30_prestataires.sql` / `35_articles.sql` à jour. |
| 7 | `docs/taxonomie-evenements.md` ne déclarait pas la clé `automatique` du payload `article.remis_en_vente` (émetteur mutualisé). | Doc (DoD 4, SC-011) | Ligne 176 alignée sur le code. |
| 8 | Compteur catalogue : « 1 **articles** » (pas de pluriel ICU) ; clé i18n morte `proInterfaceVendeurAide`. | i18n (DoD 5) | `plural` ICU (`1 article`) ; clé morte retirée. |

## Écarts consignés (dette assumée — hors périmètre de finition de ce cycle)

- **Couverture de tests HTTP automatisés** (DoD 1) : les 4 fichiers de routes du
  cycle (`admin_prestataires_http`, `prestataires_http`, `vendeur_http`,
  `signalements_http`) n'ont pas de test HTTP dédié ; les transitions sont
  couvertes au niveau **domaine** (crate `prestataires/tests/`) et le chemin HTTP
  de bout en bout a été **déroulé manuellement** au parcours curl §3 (T040). Un
  `mod http` de tests d'intégration `api` reste à écrire (tasks.md T015/T034 le
  mentionnait). Priorité : à planifier au prochain lot zéro-dette.
- **Assertion positive de commandabilité** (SC-001) : `commandable == true` est
  prouvé manuellement (curl) mais jamais asserté dans un test automatisé (le bac
  tourne hors horaires). Test à ajouter avec horloge injectée.
- **SC-013 sur la totalité des états** : preuve structurelle sur un seul état en
  test automatisé ; les autres états vérifiés manuellement (T040). Paramétrer le
  test sur tous les statuts.
- **DoD 6 — seed réel non testé** : aucun test ne vérifie que
  `10_zones_tiassale.sql` pose les 5 clés du cycle (le bac de test les repose de
  son côté). Ajouter un test qui lit le seed réel.
- **i18n mineurs restants** : tooltips des steppers de `fiche_article.dart` en
  dur, `proBoutiqueDuree` réduite au placeholder `{duree}` (unités « min »/« h »
  composées en Dart), séparateurs typographiques (`—`, `·`) en dur, devise `XOF`
  en repli Dart à la création d'article. Sans impact fonctionnel ; à externaliser
  au prochain passage i18n.

## Décisions assumées (non des écarts)

- **`changer_statut_boutique` sans garde de no-op** : rejouer « ouvrir » sur une
  boutique ouverte réécrit la ligne et émet un `site.statut_boutique_change`.
  Contrairement au défaut #1, l'événement **n'est pas mensonger** (la transition
  demandée a bien lieu, l'état final est correct) : c'est la traçabilité « un
  geste = un événement ». Conservé tel quel.
- **Ligne du plan `gratuit` posée par la migration 0004** (et non un seed) —
  argumenté dans le code (donnée de référence, pas de démo).
- **Durées de pause 30 min/1 h/2 h et pas de stepper (100)** : constantes MVP
  assumées (tasks.md T030).
- **TTL de présignature 10 min** : spécifié en dur par T014.

## Verdict

Les quatre stories produit **VND-01, VND-02, VND-03, VND-04** sont
indépendamment démontrables ; le seul défaut fonctionnel révélé par la phase 8 a
été corrigé et validé de bout en bout (curl + émulateur). Les portes
d'avant-commit sont vertes (§0.4 points 1-6 satisfaits, réserves de couverture
de test consignées ci-dessus).
