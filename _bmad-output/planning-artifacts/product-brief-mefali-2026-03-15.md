---
stepsCompleted: [1, 2, 3, 4, 5, 6]
workflow_completed: true
inputDocuments:
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-14-1400.md'
  - '_bmad-output/planning-artifacts/research/market-everything-app-research-2026-03-15.md'
  - 'documents_et_brouillons/brainstorming_everything_app.docx.md'
date: '2026-03-15'
author: 'Angenor'
---

# Product Brief: mefali

<!-- Content will be appended sequentially through collaborative workflow steps -->

## Executive Summary

mefali est un super app africain conçu pour la Côte d'Ivoire et l'Afrique de l'Ouest, qui donne aux commerçants et prestataires locaux les outils d'un grand groupe pour gérer professionnellement leur commerce, résister aux géants étrangers, et grandir à leur tour.

En combinant un ERP B2B freemium, une marketplace de livraison à commissions justes (1-15% vs 35-43% chez Glovo), une logistique inter-villes multi-tronçons tracée, et des agents IA qui dispensent des conseils pragmatiques personnalisés, mefali comble simultanément plusieurs vides que personne n'a encore adressés de façon intégrée dans l'économie informelle africaine.

Stratégie d'entrée : villes intérieures (Bouaké, Yamoussoukro, San-Pédro) via l'ERP comme tête de pont, avec marketplace food/delivery locale — puis Abidjan une fois les racines établies et le modèle consolidé dans plusieurs villes.

---

## Core Vision

### Problem Statement

En Côte d'Ivoire, les commerçants informels (87% de l'économie) sont coincés entre deux mauvaises options : rester invisibles sur WhatsApp/Facebook sans outil de gestion professionnel, ou rejoindre des plateformes étrangères qui captent 35-43% de leurs revenus tout en leur interdisant de travailler avec d'autres acteurs. Il n'existe aucune solution qui leur donne les outils des géants à leur portée, adaptée à leur réalité (offline, mobile money, OHADA, smartphones d'entrée de gamme).

### Problem Impact

- **87%** de l'économie ivoirienne est informelle — le marché cible est la norme, pas l'exception
- Les commissions Glovo (35-43%) absorbent les marges des petits restaurants, les rendant dépendants sans jamais leur permettre de croître
- Jumia Food a fermé en décembre 2023 après 5 ans — preuve que le food delivery seul sans ancrage local ne tient pas
- 80% des acheteurs préfèrent le paiement à la livraison : la confiance dans le digital n'a pas encore été méritée
- La livraison inter-villes repose encore majoritairement sur des systèmes informels (confier à un chauffeur de car) : rapide mais zéro traçabilité, zéro recours

### Why Existing Solutions Fall Short

| Solution | Limite critique |
|----------|----------------|
| **Glovo** | 35-43% commission + clauses d'exclusivité abusives |
| **Yango Deli** | 0% temporaire, pas d'ERP, pas d'inter-villes, acteur étranger |
| **Jumia Food** | Fermé — modèle non viable sans différenciation locale |
| **ERPs africains** | Trop complexes, non intégrés au mobile money CI, ignorent OHADA pour les petites structures |
| **Nundi / Wigo** | Logistique colis sans ERP, sans food, sans IA, sans handoff tracé |

Aucun acteur n'adresse la combinaison ERP + marketplace + inter-villes + IA dans un seul écosystème adapté au contexte ivoirien.

### Proposed Solution

mefali — **l'outil du géant, pour le petit commerçant.**

Un super app africain nativement conçu pour le contexte ivoirien, qui combine quatre piliers complémentaires :

1. **ERP B2B freemium** — gestion stock, commandes, comptabilité OHADA, prévisions ML on-device (sans internet)
2. **Marketplace food/delivery** — commissions 1-15%, zéro exclusivité, escrow natif, paiement immédiat au livreur
3. **Logistique inter-villes multi-tronçons** — moto → bus intercité → moto, avec handoff tracé et assurance micro-colis
4. **Agents IA pragmatiques** — assistant conversationnel toujours actif + analyses stratégiques approfondies activées à la demande par le marchand (modèle économique tokens respecté)

### Key Differentiators

1. **ERP Trojan Horse :** L'ERP gratuit est l'angle d'acquisition sans résistance — aucun concurrent ne l'adresse. Le marchand adopte l'outil, puis rejoint naturellement la marketplace.
2. **Agents IA comme allié de croissance :** "Comment devenir un géant" plutôt que "comment survivre à demain" — positionne mefali comme partenaire de long terme, pas simple plateforme de commande.
3. **Offline-first / SMS-first :** Architecture native pour la réalité africaine — connexions instables, smartphones Transsion, livreurs sans data permanente.
4. **Commission juste + zéro exclusivité :** Le contrat que Glovo refuse d'offrir et que les marchands attendent.
5. **Logistique inter-villes multi-tronçons :** Vide technologique réel — Blue Ocean non contesté.
6. **Ancrage communautaire africain :** Tontine digitale, parrainage de livreurs, mécanismes de confiance physique-vers-digital — impossible à répliquer rapidement par un acteur étranger.

---

## Target Users

### Primary Users (MVP)

---

#### Persona 1 — Maman Adjoua, La Commerçante (App B2B/ERP)

**Profil**
- Femme, 35-50 ans, gère un restaurant ou une boutique alimentaire dans une ville de l'intérieur (Bouaké, Yamoussoukro, San-Pédro)
- Téléphone : Tecno ou Infinix, connexion instable, WhatsApp Business comme outil de gestion principal actuel
- Gestion actuelle : carnet papier pour le stock, mobile money pour encaisser, mémorisation des recettes

**Objectifs**
- Ne plus manquer de stock sur ses produits qui se vendent le mieux
- Attirer de nouveaux clients sans payer 35-43% à une plateforme
- Comprendre ses chiffres sans avoir besoin d'un comptable

**Frustrations actuelles**
- Perd de l'argent en stock périmé ou en rupture imprévue
- Ne sait jamais ce qu'elle va vendre le lendemain
- Les plateformes existantes (si elle y est) lui imposent des conditions qu'elle ne peut pas refuser

**"Aha moment"**
Fin de semaine, elle ouvre mefali et voit pour la première fois un rapport automatique : le thiéboudienne du vendredi se vend 3× plus que les autres jours. Elle ajuste son stock. Elle n'a jamais eu cette information avant.

---

#### Persona 2 — Koné, Le Livreur (App Livreur)

**Profil**
- Homme, 22-30 ans, possède une moto, cherche à compléter ses revenus ou fait de la livraison à temps plein
- Téléphone d'entrée de gamme (Itel/Tecno), data instable
- A vécu ou connu la fermeture de Jumia Food : méfiant envers les plateformes étrangères qui disparaissent du jour au lendemain

**Objectifs**
- Être payé rapidement et sans friction après chaque livraison
- Avoir des commandes régulières et prévisibles
- Travailler avec une plateforme qui ne disparaîtra pas du jour au lendemain

**Frustrations actuelles**
- Incertitude totale sur ses revenus d'une semaine à l'autre
- Aucune protection : pas de contrat, pas d'assurance, pas de recours en cas de litige
- Apps qui tombent en panne hors connexion, GPS qui décroche

**"Aha moment"**
Il complète sa première livraison mefali. Moins de 5 minutes après, il reçoit une notification : son wallet est crédité. Ce n'est pas une promesse de virement dans 15 jours — c'est maintenant, concret, dans sa main.

---

#### Persona 3 — Koffi, Le Client (App B2C)

**Profil**
- Homme ou femme, 20-35 ans, résident d'une ville de l'intérieur
- Smartphone milieu/entrée de gamme, mobile money actif
- Habitué à commander via WhatsApp à des restaurants ou livreurs informels — mais sans garantie de délai ni de qualité

**Objectifs**
- Manger bien sans se déplacer, être livré dans les délais annoncés
- Payer à la livraison (vérifier avant de payer)
- Pouvoir se plaindre et être entendu si quelque chose va mal

**Frustrations actuelles**
- Délais imprévisibles, commandes annulées sans raison
- Pas de suivi en temps réel
- Aucun recours si le plat arrive froid ou manquant

**"Aha moment"**
Il suit sa commande en temps réel sur la carte. Le livreur arrive dans la fenêtre annoncée. Il inspecte la commande, confirme, paie à la livraison. Tout s'est passé exactement comme promis — une première pour lui sur une app de livraison locale.

---

### Secondary Users

**Équipe mefali — Admin interne**
- Gère les marchands, livreurs, litiges, promotions et KPIs via le dashboard admin
- Profil MVP : équipe réduite (2-5 personnes terrain + tech)
- Besoins clés : vue globale des opérations, validation KYC, gestion des litiges, monitoring des performances

---

### Future Users (Phase 2+ — hors MVP)

| Persona | Phase | Description |
|---------|-------|-------------|
| **Expéditeur inter-villes** | Phase 2 | Commerçant ou particulier envoyant un colis entre deux villes (ex: Bouaké → Abidjan) |
| **Prestataire de services** | Phase 2 | Coiffeur, couturier, plombier — gestion RDV + ERP + mise en relation clients |

---

### User Journeys (MVP)

#### Maman Adjoua — Onboarding et usage quotidien

```
DÉCOUVERTE
  └─ Agent terrain mefali vient la voir en boutique, démo sur place
       ↓
ONBOARDING (< 30 min avec l'agent)
  └─ Inscription ERP gratuit → saisie catalogue → première commande test
       ↓
USAGE QUOTIDIEN
  └─ Commandes entrent → prépare → marque "prête" → Koné récupère
       ↓
VALEUR RÉALISÉE (semaine 1-2)
  └─ Premier rapport de ventes → ajustement stock → moins de pertes
       ↓
LONG TERME
  └─ Module comptabilité OHADA → micro-crédit Baobab → croissance
```

#### Koné — Premier jour actif

```
DÉCOUVERTE
  └─ Parrainé par un ami livreur (système parrainage mefali)
       ↓
ONBOARDING (KYC physique avec agent mefali)
  └─ Validation identité + moto → compte activé
       ↓
PREMIÈRE COURSE
  └─ Reçoit commande (app ou SMS si offline) → récupère → livre
       ↓
"AHA MOMENT"
  └─ Paiement wallet < 5 min après confirmation livraison
       ↓
LONG TERME
  └─ Parraine ses propres livreurs (max 3) → revenus passifs
```

#### Koffi — Première commande

```
DÉCOUVERTE
  └─ Ami envoie lien mefali sur WhatsApp / pub Facebook locale
       ↓
PREMIER ACHAT
  └─ Choisit restaurant du quartier → commande → sélectionne COD
       ↓
SUIVI EN TEMPS RÉEL
  └─ Voit Koné sur la carte → livraison dans les délais annoncés
       ↓
"AHA MOMENT"
  └─ Inspecte commande → confirme → paie cash → tout est conforme
       ↓
RÉTENTION
  └─ Revient spontanément → recommande sur WhatsApp
```

---

## Success Metrics

### North Star Metric

**NPS (Net Promoter Score) — signal primaire à 3 mois**

Le NPS est le premier indicateur de santé de mefali. Un commerçant qui recommande la plateforme à ses voisins, un livreur qui parraine ses amis, un client qui envoie le lien sur WhatsApp — c'est la preuve que le produit crée assez de valeur pour se propager sans publicité payante.

**Cible :** NPS > 50 à M3 (niveau "excellent" — à titre de comparaison, Apple iPhone score ~72, Glovo CI est estimé négatif chez les marchands)

---

### User Success Metrics

#### Maman Adjoua (Commerçante B2B/ERP)

| Métrique | Cible | Pourquoi ça compte |
|----------|-------|--------------------|
| Utilisation ERP (sessions/semaine) | ≥ 3× après M1 | Signe d'adoption réelle, pas juste inscription |
| Réduction ruptures de stock | > 30% en 60 jours | La promesse de valeur centrale de l'ERP |
| Rétention ERP à 3 mois | > 70% | Un outil qu'on n'utilise plus ne vaut rien |
| "Aha moment" atteint | < 14 jours | Premier rapport utilisé pour une décision de stock |

#### Koné (Livreur)

| Métrique | Cible | Pourquoi ça compte |
|----------|-------|--------------------|
| Délai paiement wallet post-livraison | < 5 minutes | Le différenciateur #1 vs tous les concurrents |
| Taux de complétion livraison | > 90% | Fiabilité opérationnelle — qualité perçue par Koffi |
| Livreurs actifs à J+30 | > 80% des inscrits | Rétention livreur = backbone opérationnel |
| Commandes reçues hors connexion | 0 perte | Validation du SMS-first workflow |

#### Koffi (Client B2C)

| Métrique | Cible | Pourquoi ça compte |
|----------|-------|--------------------|
| Livraisons dans la fenêtre annoncée | > 85% | La promesse de fiabilité — briser le pattern actuel |
| Retour à J+30 | > 40% des primo-commandeurs | Premier signal de rétention long terme |
| Recommandations WhatsApp actives | > 20% des actifs | Mesure de la propagation organique |

---

### Business Objectives

#### Phase MVP — Validation (M1-M3, 1 ville : Bouaké)

**Objectif fondateur :** Couvrir les coûts opérationnels avec les commissions marketplace dès le mois 3.

| Objectif | Cible M3 |
|----------|----------|
| Marchands ERP actifs | 50+ |
| Livreurs actifs | 20+ |
| Commandes/semaine | 300+ |
| NPS global | > 50 |
| Couverture coûts opérationnels | 100% via commissions marketplace |

> **Logique :** Si 50 marchands génèrent en moyenne 200 000 FCFA de GMV/mois chacun → 10M FCFA GMV × 10% commission = 1M FCFA/mois. L'objectif de break-even M3 contraint à une équipe lean de ≤ 3 personnes et à des coûts infra minimaux.

#### Phase Expansion (M4-M9, 2-3 villes intérieures)

| Objectif | Cible M9 |
|----------|----------|
| Villes actives | 3 |
| Marchands ERP actifs (total) | 150+ |
| GMV total | 50M FCFA/mois |
| Rétention marchands 6 mois | > 70% |
| Livreurs actifs (total) | 60+ |

---

### Key Performance Indicators

**Indicateurs avancés (signaux précoces)**

| KPI | Fréquence de mesure | Seuil d'alerte |
|-----|-------------------|----------------|
| Sessions ERP/marchand/semaine | Hebdomadaire | < 2 = marchand à risque de churn |
| Taux d'acceptation commandes (livreurs) | Quotidien | < 80% = pénurie livreurs |
| Temps moyen de livraison | Quotidien | > 45 min = problème opérationnel |
| Taux d'annulation client | Hebdomadaire | > 10% = friction UX ou délais |

**Indicateurs de résultat (santé business)**

| KPI | Fréquence | Cible Phase 1 |
|-----|-----------|---------------|
| GMV mensuel | Mensuel | 10M FCFA à M3 |
| Commission revenue | Mensuel | = coûts opérationnels à M3 |
| NPS (par segment) | Mensuel | > 50 global |
| CAC (coût acquisition marchand) | Par cohorte | < 15 000 FCFA |

**Indicateurs de guardrail (à ne jamais dégrader)**

| Guardrail | Seuil minimum absolu |
|-----------|---------------------|
| Délai paiement livreur | < 5 minutes après confirmation |
| Résolution litige | < 24 heures |
| Uptime app | > 99% |
| Commandes perdues hors connexion | 0 (SMS-first comme fallback) |

---

## MVP Scope

**Périmètre :** 1 ville (Bouaké) — M1 à M3
**Objectif :** Valider le modèle avant expansion

---

### Core Features

#### App B2C — Koffi commande son repas

| Feature | Priorité | Justification |
|---------|---------|---------------|
| Inscription rapide (numéro de téléphone) | 🔴 Must | Frictionless — pas de formulaire long |
| Recherche et découverte de restaurants | 🔴 Must | Core du parcours client |
| Catalogue produits (photos, prix, stock) | 🔴 Must | Sans ça, pas de commande |
| Panier + passage de commande | 🔴 Must | Flux central |
| Paiement COD (cash à la livraison) | 🔴 Must | 80% du marché — non négociable |
| Paiement mobile money (CinetPay) | 🔴 Must | Orange Money, MTN MoMo, Wave |
| Suivi livraison temps réel (GPS) | 🔴 Must | Élimine l'anxiété — différenciateur clé |
| Notation post-livraison (resto + livreur) | 🟠 Should | Nécessaire pour la confiance |
| Historique de commandes | 🟡 Nice | Rétention, mais pas bloquant M1 |

#### App B2B/ERP — Maman Adjoua gère son restaurant

| Feature | Priorité | Justification |
|---------|---------|---------------|
| Inscription avec KYC simplifié (via agent terrain) | 🔴 Must | Onboarding physique — clé de la confiance |
| Gestion catalogue (produits, prix, photos, stocks) | 🔴 Must | Cœur de l'ERP |
| Gestion commandes entrantes (accepter / refuser / préparer) | 🔴 Must | Inopérationnel sans cette feature |
| Système 4 états de disponibilité | 🔴 Must | Évite les commandes refusées = satisfaction client |
| Dashboard ventes hebdomadaire (rapport simple) | 🔴 Must | Le "aha moment" de Maman Adjoua |
| Paiement escrow (libéré à réception confirmée) | 🔴 Must | Confiance marchands + protection clients |
| Wallet marchand + retrait mobile money | 🔴 Must | Paiement sans friction |
| Gestion des horaires d'ouverture | 🟠 Should | Évite les déceptions clients |
| Alertes rupture de stock automatiques | 🟡 Nice | Phase 1b — ML non nécessaire au MVP |

#### App Livreur — Koné fait ses courses

| Feature | Priorité | Justification |
|---------|---------|---------------|
| Inscription avec KYC physique + parrainage | 🔴 Must | Sécurité et confiance fondamentale |
| Réception commandes via notification app | 🔴 Must | Flux principal |
| Réception commandes via SMS (fallback offline) | 🔴 Must | SMS-first — non négociable pour la CI |
| Navigation GPS intégrée | 🔴 Must | Efficacité opérationnelle |
| Confirmation collecte + livraison | 🔴 Must | Déclencheur du paiement escrow |
| Protocole client absent (COD vs prépayé) | 🔴 Must | Cas d'usage fréquent — doit être géré |
| Paiement immédiat wallet post-livraison (< 5 min) | 🔴 Must | Différenciateur #1 pour la rétention livreur |
| Statut de disponibilité (actif / pause) | 🟠 Should | Évite les commandes fantômes |

#### App Admin — Équipe mefali

| Feature | Priorité | Justification |
|---------|---------|---------------|
| Dashboard opérationnel (commandes, marchands, livreurs) | 🔴 Must | Visibilité temps réel opérations |
| Validation KYC marchands et livreurs | 🔴 Must | Sécurité plateforme |
| Gestion des litiges | 🔴 Must | Maintien de la confiance utilisateurs |
| Configuration zones de livraison Bouaké | 🔴 Must | Périmètre opérationnel MVP |

---

### Out of Scope pour le MVP

| Feature | Phase | Raison du report |
|---------|-------|-----------------|
| **Logistique inter-villes multi-tronçons** | Phase 2 | Infrastructure complexe — hors Bouaké |
| **Agents IA** (conversationnel + analyses) | Phase 2 | Coûts LLM incompatibles avec break-even M3 |
| **Tontine digitale** | Phase 2 | Mécanisme viral — utile à l'échelle, pas au lancement |
| **Micro-crédit Baobab** | Phase 2 | Nécessite historique de transactions minimal |
| **Micro-assurance AXA** | Phase 2 | Liée à l'inter-villes |
| **Prestataires services non-food** (coiffeur, couturier...) | Phase 2 | Focus food pour valider le modèle |
| **Module comptabilité OHADA avancé** | Phase 2 | ERP simplifié suffit au MVP |
| **Prévisions ML stock (on-device)** | Phase 2 | Nécessite données historiques suffisantes |
| **Wallet obligatoire** | Jamais MVP | Reste optionnel — décision stratégique définitive |
| **Abidjan** | Phase 3 | Après consolidation villes intérieures |
| **Expansion Afrique de l'Ouest** | Phase 4 | Modèle validé CI d'abord |

---

### MVP Success Criteria — Go/No-Go Phase 2

À la fin du mois 3, mefali passe en mode expansion si et seulement si :

| Critère | Seuil Go | Seuil No-Go |
|---------|---------|------------|
| NPS global | ≥ 50 | < 40 |
| Coûts opérationnels couverts | 100% par commissions | < 80% |
| Marchands ERP actifs | ≥ 50 | < 30 |
| Taux de complétion livraisons | ≥ 90% | < 80% |
| Livreurs actifs à J+90 | ≥ 80% des inscrits | < 60% |

> **Si No-Go :** Itération sur les points de friction identifiés avant toute expansion géographique.

---

### Future Vision (Post-MVP)

**Phase 2 (M4-M9) — Expansion + Services Financiers**
- Déploiement dans 2 villes supplémentaires (Yamoussoukro, San-Pédro)
- Agent IA conversationnel (assistant marchand toujours actif)
- Analyses IA stratégiques à la demande (token cost opt-in)
- Tontine digitale comme mécanisme d'acquisition viral
- Partenariat Baobab micro-crédit (basé sur historique transactions)
- Logistique inter-villes multi-tronçons (moto → bus → moto)

**Phase 3 (M19-M30) — Abidjan + ERP Avancé**
- Entrée Abidjan via réseau marchands ERP déjà établi
- Module comptabilité OHADA complet
- Prévisions ML stock on-device (TensorFlow Lite)
- Prestataires de services non-food (coiffeur, couturier...)
- Partenariat AXA micro-assurance colis inter-villes

**Phase 4 (M31+) — Afrique de l'Ouest**
- Sénégal, Mali, Burkina Faso, Togo
- Marchés OHADA/francophones = réplication directe du modèle CI
