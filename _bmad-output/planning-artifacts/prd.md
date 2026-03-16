---
stepsCompleted: ['step-01-init', 'step-02-discovery', 'step-02b-vision', 'step-02c-executive-summary', 'step-03-success', 'step-04-journeys', 'step-05-domain', 'step-06-innovation', 'step-07-project-type', 'step-08-scoping', 'step-09-functional', 'step-10-nonfunctional', 'step-11-polish', 'step-12-complete']
workflow_completed: true
classification:
  projectType: 'mobile_app_multi'
  domain: 'marketplace_logistics'
  complexity: 'high'
  projectContext: 'greenfield'
  walletType: 'internal_balance'
  paymentProvider: 'CinetPay'
inputDocuments:
  - '_bmad-output/planning-artifacts/product-brief-mefali-2026-03-15.md'
  - '_bmad-output/planning-artifacts/research/market-everything-app-research-2026-03-15.md'
  - '_bmad-output/brainstorming/brainstorming-session-2026-03-14-1400.md'
workflowType: 'prd'
documentCounts:
  briefs: 1
  research: 1
  brainstorming: 1
  projectDocs: 0
  projectContext: 0
---

# Product Requirements Document - mefali

**Author:** Angenor
**Date:** 2026-03-15

## Executive Summary

mefali est un super app multi-plateforme (4 apps Flutter) destiné au marché ivoirien et ouest-africain. Il cible les 87% de l'économie informelle en combinant un ERP B2B freemium, une marketplace food/delivery à commissions de 1-15%, et une logistique inter-villes multi-tronçons tracée — le tout conçu nativement pour le contexte africain : offline-first, SMS fallback, paiements mobile money via CinetPay, optimisé smartphones Transsion.

**Problème :** Les commerçants ivoiriens sont coincés entre l'invisibilité (WhatsApp/Facebook sans outil de gestion) et l'exploitation par des plateformes étrangères (Glovo : 35-43% de commission + exclusivité forcée). Aucune solution n'offre des outils de gestion professionnels adaptés à leur réalité (offline, OHADA, mobile money).

**Utilisateurs MVP :** Commerçants alimentaires de villes intérieures (Bouaké), livreurs moto indépendants, consommateurs locaux commandant des repas.

**Stratégie d'entrée :** 1 ville (Bouaké) → validation break-even à M3 → expansion 2-3 villes intérieures → Abidjan (Phase 3).

### Ce qui rend mefali unique

1. **ERP Trojan Horse** — L'ERP B2B freemium est l'arme d'acquisition la moins contestée du marché. Aucun concurrent ne l'adresse. Le marchand adopte l'outil de gestion (valeur immédiate), puis rejoint naturellement la marketplace.

2. **Agents IA pragmatiques (Phase 2)** — Assistant conversationnel + analyses stratégiques à la demande. Positionnement : "comment devenir un géant" plutôt que "comment survivre". Token cost opt-in par le marchand.

3. **Architecture offline-native** — SMS-first pour livreurs (deep link + Base64), mode offline ERP, synchronisation opportuniste. Ce n'est pas un fallback — c'est l'architecture primaire pour un marché où 40% des utilisateurs ont une connectivité instable.

4. **Commission juste + zéro exclusivité** — 1-15% vs 35-43% Glovo. Paiement immédiat livreur (< 5 min). Escrow natif. Le marchand est un partenaire, pas une source de revenus captive.

5. **Wallet interne (non fintech)** — Solde app uniquement (modèle Yango), pas de licence BCEAO requise. CinetPay porte la réglementation paiements. Wallet reste facultatif — COD + mobile money comme options primaires.

## Project Classification

| Dimension | Valeur |
|-----------|--------|
| **Type** | Mobile App multi-plateforme (4 apps Flutter + backend Rust/Python) |
| **Domain** | Marketplace / Logistics + ERP B2B |
| **Complexity** | High (multi-app, offline-first, escrow, KYC physique, OHADA) |
| **Context** | Greenfield — construction complète from scratch |
| **Wallet** | Solde interne app (non réglementé BCEAO) |
| **Paiements** | CinetPay (Orange Money, MTN MoMo, Wave) |

## Success Criteria

### User Success

**Maman Adjoua (Commerçante B2B)**
- Inscription + catalogue opérationnel en < 30 min (assistée par agent terrain)
- Utilise l'ERP ≥ 3×/semaine dès M1 (sessions actives mesurées)
- Premier rapport de ventes consulté en < 14 jours (déclencheur du "aha moment")
- Réduction ruptures de stock > 30% en 60 jours (mesure par écarts catalogue/ventes)
- Rétention ERP à 90 jours : > 70%

**Koné (Livreur)**
- Paiement wallet crédité < 5 minutes après confirmation livraison
- 0 commande perdue à cause de la connectivité (SMS-first = zéro perte)
- Taux de complétion livraisons : > 90%
- Rétention livreurs actifs à J+90 : > 80% des inscrits

**Koffi (Client B2C)**
- Livraison dans la fenêtre annoncée : > 85% des commandes
- Retour spontané à J+30 : > 40% des primo-commandeurs
- Taux d'abandon panier : < 30% (vs 69% moyen observé en CI)
- Recommandation WhatsApp active : > 20% des clients actifs

### Business Success

**North Star : NPS > 50 à M3** — signal que le produit crée assez de valeur pour se propager organiquement.

| Objectif | Cible M3 | Cible M9 |
|----------|----------|----------|
| Marchands ERP actifs | 50+ (1 ville) | 150+ (3 villes) |
| Livreurs actifs | 20+ | 60+ |
| Commandes/semaine | 300+ | 1 500+ |
| GMV mensuel | 10M FCFA | 50M FCFA |
| Commission revenue vs coûts ops | ≥ 100% à M3 | ≥ 200% à M9 |
| CAC marchand | < 15 000 FCFA | < 10 000 FCFA |
| Rétention marchands 6 mois | — | > 70% |

### Technical Success

> Voir la section **Non-Functional Requirements** pour les seuils techniques détaillés et mesurables (NFR1-NFR30).

**Résumé des guardrails critiques :**
- Uptime > 99%, latence API p95 < 500ms, APK < 30 MB
- Paiement livreur < 5 min, SMS fallback < 30s, sync offline < 60s
- Crash rate < 1% (tests obligatoires sur Transsion devices)

### Measurable Outcomes

**Go/No-Go Phase 2 (fin M3) :**

| Critère | Go | No-Go |
|---------|-----|-------|
| NPS global | ≥ 50 | < 40 |
| Break-even opérationnel | ≥ 100% | < 80% |
| Marchands ERP actifs | ≥ 50 | < 30 |
| Complétion livraisons | ≥ 90% | < 80% |
| Livreurs actifs J+90 | ≥ 80% inscrits | < 60% |

---

## Product Scope

> Voir la section **Project Scoping & Phased Development** pour le détail complet : MVP features par app, timeline de développement, répartition équipe (4 devs), et analyse de risques.

**Résumé MVP (Bouaké, M1-M3) :** 4 apps Flutter (B2C, B2B/ERP, Livreur, Admin) + backend Rust. Break-even opérationnel à M3.

**Phases :** MVP (1 ville) → Phase 2 (3 villes + IA + inter-villes) → Phase 3 (Abidjan + OHADA avancé) → Phase 4 (Afrique de l'Ouest)

## User Journeys

### Journey 1 — Maman Adjoua : La Première Semaine

**Persona :** Adjoua, 42 ans, tient un restaurant de garba et alloco à Bouaké depuis 8 ans. Gère tout de mémoire et sur un carnet quadrillé. Tecno Spark, WhatsApp, Orange Money.

**Opening Scene — Lundi matin**
Adjoua ouvre son restaurant à 6h. Elle ne sait pas combien d'attiéké il lui reste en stock. Hier, trois clients sont repartis parce que le garba était épuisé à 13h — elle ne l'avait pas anticipé. Elle vend bien, mais elle ne sait jamais *combien* elle vend, ni *quoi* exactement. Son carnet est illisible après 3 mois de sauce tomate et de billets froissés.

**Rising Action — L'agent terrain passe**
Mardi 10h, Fatou (agent terrain mefali) arrive avec son téléphone. "Je te montre un truc, ça prend 20 minutes." Fatou crée le compte d'Adjoua, prend en photo ses 12 plats, saisit les prix. Adjoua regarde par-dessus son épaule, méfiante. "C'est gratuit ? Vraiment ?" Fatou lui montre comment marquer une commande comme prête. Adjoua fait un test : elle "commande" elle-même son propre garba. Le téléphone sonne. Elle rit.

**Climax — Vendredi soir**
Adjoua ouvre l'app après la fermeture. Pour la première fois de sa vie, elle voit un écran qui lui dit : "Cette semaine : 47 commandes. Garba : 23 (49%). Alloco-poisson : 15 (32%). Attiéké : 9 (19%)." Elle comprend instantanément : le garba, c'est la moitié de son business. Demain samedi, elle doublera sa préparation de garba. Elle n'a jamais eu cette information en 8 ans de carnet.

**Resolution — Samedi suivant**
13h, le garba n'est pas épuisé. Aucun client reparti les mains vides. Adjoua a reçu 4 commandes via l'app — des gens qu'elle ne connaissait pas, qui l'ont trouvée sur mefali. Elle envoie un vocal WhatsApp à sa voisine commerçante : "Viens voir ce truc."

**Requirements Revealed :**
- Onboarding assisté par agent terrain (< 30 min)
- Saisie catalogue avec photo depuis le téléphone
- Dashboard ventes hebdomadaire simple et visuel
- Commandes entrantes avec notification sonore
- Marquage "commande prête" pour déclencher le livreur
- Fonctionnement sur Tecno Spark (résolution, RAM, stockage)

---

### Journey 2 — Koné : Le Premier Jour + Client Absent

**Persona :** Koné, 24 ans, moto Jakarta, fait de la livraison informelle sur WhatsApp depuis 6 mois. Parrainé par son ami Moussa, déjà livreur mefali. Itel A58, forfait data 500 FCFA/jour qu'il active quand il a de l'argent.

**Opening Scene — Lundi 8h**
Koné arrive au point de rendez-vous avec l'agent mefali. Il a sa CNI, son permis, et Moussa (son parrain). L'agent vérifie les documents, prend une photo, active son compte. "Moussa répond de toi — s'il y a un problème, c'est lui qu'on appelle d'abord." Koné hoche la tête. Il sait que Moussa ne le parrainerait pas s'il ne lui faisait pas confiance.

**Rising Action — Première commande, 11h30**
Son téléphone vibre : nouvelle commande. Restaurant de Maman Adjoua, garba + alloco, livraison à 800m. Il accepte. Il roule jusqu'au restaurant, Adjoua lui tend le paquet. Il appuie sur "Collecté". Le GPS lui montre le chemin. Il arrive chez le client en 7 minutes.

**Climax — Paiement instantané**
Le client inspecte la commande, paie 2 500 FCFA cash. Koné appuie sur "Livré". Son téléphone affiche : "+350 FCFA ajoutés à votre wallet." C'est là. Dans sa main. Pas dans 15 jours, pas bloqué sur un compte inaccessible. Maintenant.

**Edge Case — 14h : Client absent**
Deuxième commande : paiement COD. Koné arrive, personne. Il appuie sur "Client absent", un timer de 10 minutes se déclenche. Il appelle le client — pas de réponse. Le timer expire. L'app lui propose deux options : retourner le colis au restaurant, ou le déposer à la base mefali. Il choisit le restaurant (c'est plus près). Sa course est payée quand même — le protocole client absent protège le livreur.

**Edge Case — 15h30 : Perte de réseau**
Koné est dans une zone mal couverte. Sa data est coupée. Un SMS arrive : "Nouvelle commande #127. Garba chez Adjoua → Quartier Commerce. Client: 07XXXXXXXX. COD 3000F." Le lien deep link contient toutes les infos encodées. Il n'a besoin de rien d'autre. Il livre, et quand la connexion revient, l'app se synchronise automatiquement.

**Resolution — 18h**
Koné a fait 8 livraisons. Son wallet affiche 2 800 FCFA de gains. Il retire 2 000 FCFA vers son Orange Money — l'argent arrive en 2 minutes. Son ancien "patron" WhatsApp lui devait encore 5 000 FCFA de la semaine dernière. Ici, il n'y a rien à devoir. Il envoie un message à son cousin : "Il y a un truc, viens je te parraine."

**Requirements Revealed :**
- KYC physique avec vérification agent + parrain
- Notification push + SMS fallback (deep link Base64)
- Confirmation collecte + livraison (2 étapes)
- Protocole client absent avec timer, appel, et routing
- Paiement wallet immédiat (< 5 min post-confirmation)
- Retrait wallet → mobile money
- Synchronisation offline → serveur automatique
- GPS navigation intégrée
- Parrainage livreur (max 3)

---

### Journey 3 — Koffi : La Première Commande

**Persona :** Koffi, 27 ans, fonctionnaire à Bouaké, rentre du bureau à 18h30 fatigué. Samsung A14, Orange Money actif.

**Opening Scene — Mercredi 18h45**
Koffi est dans son salon, crevé. Son collègue lui a envoyé un lien WhatsApp : "Teste ça, tu commandes à manger direct." Il clique. L'app se télécharge (< 30 MB). Il s'inscrit en 30 secondes : numéro de téléphone, code SMS, prénom. Pas de mail, pas de mot de passe compliqué.

**Rising Action — La commande**
Il voit les restaurants autour de lui. Maman Adjoua, 4.7 étoiles, "garba + alloco" à 1 500 FCFA. Il ajoute au panier. L'écran de confirmation affiche clairement : plat 1 500 + livraison 500 = **2 000 FCFA total**. Pas de surprise. Il choisit "Payer à la livraison (cash)".

**Climax — La livraison**
Il suit Koné sur la carte. Un point bleu qui avance. ETA : 15 min. Son téléphone vibre : "Votre livreur arrive dans 2 minutes." Il descend. Koné est là. Il ouvre le paquet, vérifie — c'est chaud, c'est complet. Il donne 2 000 FCFA. Koné confirme. Terminé. Tout s'est passé exactement comme promis. C'est la première fois que ça arrive sur une app de livraison locale.

**Resolution — Le lendemain**
L'app lui propose de noter Maman Adjoua et Koné. Il met 5 étoiles aux deux. Jeudi soir, il recommande sans hésiter. Vendredi, il envoie le lien à sa sœur à Yamoussoukro : "C'est pas encore chez vous, mais ça va venir."

**Requirements Revealed :**
- Inscription ultra-rapide (phone + SMS OTP uniquement)
- APK < 30 MB
- Catalogue avec photos, prix, notes
- Affichage prix total transparent avant confirmation
- COD comme option de paiement par défaut
- Suivi GPS temps réel du livreur
- Notifications push (ETA, arrivée)
- Notation double (marchand + livreur)
- Partage/recommandation facile (lien WhatsApp)

---

### Journey 4 — Fatou, Agent Terrain : Journée d'Onboarding

**Persona :** Fatou, 29 ans, recrutée comme agent terrain mefali à Bouaké. Smartphone milieu de gamme fourni par mefali, forfait data inclus. Objectif : onboarder 3-5 marchands/jour.

**Opening Scene — 8h**
Fatou consulte son dashboard agent dans l'app Admin. Elle a 4 rendez-vous aujourd'hui — deux restaurants confirmés, un vendeur de jus, et un "à convaincre" (la voisine d'un marchand déjà inscrit qui a vu l'app et est curieuse).

**Rising Action — Premier onboarding, 9h**
Elle arrive chez Dramane, restaurateur. Elle lui montre l'app B2B sur son propre téléphone d'abord : "Regarde, voilà comment tes commandes vont arriver." Elle installe l'app sur le téléphone de Dramane. Inscription : numéro, nom du commerce, adresse. Elle prend les photos des 8 plats de Dramane, saisit les prix. 25 minutes. Dramane est inscrit.

**Climax — Le KYC livreur, 14h**
Un nouveau livreur arrive avec son parrain. Fatou vérifie la CNI, le permis moto, prend les photos. Elle valide dans l'app Admin — le profil passe en "Vérification en cours." Le parrain confirme : "Je le connais, c'est mon voisin." Fatou active le compte. Elle explique le parrainage : "S'il fait n'importe quoi, c'est toi qu'on contacte d'abord."

**Resolution — 17h**
Fatou a onboardé 4 marchands et 1 livreur aujourd'hui. Son dashboard montre ses stats : 4/4 objectif marchands atteint. Elle voit aussi que 2 de ses marchands onboardés la semaine dernière ont déjà reçu leurs premières commandes.

**Requirements Revealed :**
- App Admin : vue agent terrain avec planning et objectifs
- Flux d'inscription marchand assisté (step-by-step)
- Prise de photo catalogue directe depuis l'app
- KYC livreur : capture CNI, permis, photo, lien parrain
- Validation KYC dans l'app Admin
- Dashboard agent : stats d'onboarding, suivi marchands activés
- Mode "démo" pour montrer l'app au marchand avant inscription

---

### Journey 5 — Awa, Admin : Résolution d'un Litige

**Persona :** Awa, 31 ans, membre de l'équipe mefali à Bouaké, responsable opérations. Gère les litiges et le monitoring quotidien via l'app Admin (web).

**Opening Scene — 10h**
Le dashboard affiche un litige signalé : un client dit que sa commande est arrivée incomplète (garba sans alloco). Le livreur a confirmé la livraison. Le marchand dit avoir tout mis dans le sac.

**Rising Action — Investigation**
Awa ouvre le litige. Elle voit la timeline complète : commande passée à 12h14, collectée à 12h28, livrée à 12h41. Le client a signalé le problème à 12h45. Elle consulte l'historique du marchand : 47 commandes, 2 litiges précédents (1 confirmé, 1 infondé). Le livreur : 83 livraisons, 0 litige avant.

**Climax — Décision**
Awa contacte le marchand par téléphone. Adjoua confirme qu'elle a bien mis l'alloco. Awa regarde les photos de la commande (si le livreur en a pris). Pas de photo cette fois. Elle applique le protocole : en l'absence de preuve, le client a raison pour un premier litige. Elle crédite un avoir de 500 FCFA sur le wallet du client et envoie un rappel au livreur de prendre des photos systématiquement.

**Resolution — 10h20**
Litige résolu en 20 minutes. Le client reçoit une notification : "Votre réclamation a été traitée. 500 FCFA crédités." Le livreur reçoit un rappel bienveillant. Aucun acteur n'est pénalisé abusivement. Awa passe au litige suivant.

**Requirements Revealed :**
- Dashboard admin web avec vue litiges en temps réel
- Timeline complète d'une commande (horodatage chaque étape)
- Historique marchand et livreur (nombre de commandes, litiges)
- Système de signalement litige côté client (dans l'app B2C)
- Protocole de résolution avec règles d'arbitrage
- Crédit avoir / remboursement wallet client
- Notification push livreur (rappels procédure)
- Photo de commande optionnelle par le livreur (preuve)

---

### Journey Requirements Summary

| Capability | Journeys qui la révèlent |
|-----------|------------------------|
| **Onboarding assisté agent terrain** | Adjoua, Fatou |
| **Catalogue produits avec photos** | Adjoua, Koffi, Fatou |
| **Dashboard ventes / rapports** | Adjoua |
| **4 états de disponibilité** | Adjoua (implicite) |
| **SMS fallback offline** | Koné |
| **Protocole client absent** | Koné |
| **Paiement wallet immédiat** | Koné |
| **Retrait mobile money** | Koné |
| **Inscription rapide (phone OTP)** | Koffi |
| **Suivi GPS temps réel** | Koffi, Koné |
| **COD + mobile money** | Koffi |
| **Notation double** | Koffi |
| **KYC physique + parrainage** | Koné, Fatou |
| **Dashboard agent terrain** | Fatou |
| **Système de litiges** | Awa |
| **Timeline commande complète** | Awa |
| **Historiques et métriques** | Awa, Fatou |
| **Escrow** | Koné, Koffi (implicite) |
| **Partage WhatsApp** | Koffi |
| **Synchronisation offline** | Koné |

## Domain-Specific Requirements

### Conformité & Réglementation

**OHADA (Organisation pour l'Harmonisation en Afrique du Droit des Affaires)**
- Le module ERP doit respecter le plan comptable OHADA pour les rapports de ventes (Phase 2 avancé, mais la structure de données MVP doit être compatible)
- Les reçus de transaction doivent être conformes aux exigences fiscales CI

**CinetPay — Intégration Paiements**
- CinetPay porte la licence BCEAO — mefali n'a pas besoin de sa propre licence
- API CinetPay : respect des protocoles d'intégration (webhook callbacks, idempotency, réconciliation)
- Le wallet interne n'est pas un instrument de paiement réglementé — c'est un solde app (modèle Yango)

**Protection des Données Personnelles**
- APDP (Autorité de Protection des Données Personnelles de Côte d'Ivoire) — loi n°2013-450
- Données sensibles : localisation GPS des livreurs, CNI/permis (KYC), historique commandes
- Consentement explicite requis pour le tracking GPS
- Stockage sécurisé des documents KYC (chiffrement at rest)

### Contraintes Techniques Domaine

**SMS Gateway**
- Réglementation ARTCI (Autorité de Régulation des Télécommunications CI) pour l'envoi de SMS en masse
- Partenariat SMS gateway nécessaire (Twilio, Infobip, ou opérateur local)
- Limite 160 caractères par SMS — commandes encodées en Base64 dans deep link

**Mobile Money — Flux de Fonds**
- Flux : Client → CinetPay escrow → wallet marchand (à confirmation) → retrait mobile money
- Le délai de retrait wallet → mobile money dépend de CinetPay (SLA à négocier)
- Réconciliation quotidienne obligatoire entre wallet interne et CinetPay

### Exigences d'Intégration

| Système | Type | Criticité MVP |
|---------|------|---------------|
| CinetPay API | Paiements (Orange/MTN/Wave) | 🔴 Bloquant |
| SMS Gateway | SMS fallback livreurs | 🔴 Bloquant |
| Google Maps API | Navigation + estimation temps | 🔴 Bloquant |
| Firebase Cloud Messaging | Push notifications | 🔴 Bloquant |
| Stockage cloud (S3/GCS) | Photos catalogue + KYC | 🟠 Important |

### Risques Domaine & Mitigations

| Risque | Impact | Mitigation |
|--------|--------|-----------|
| CinetPay down/latent | Paiements bloqués | File d'attente côté serveur + retry automatique + notification marchand |
| SMS gateway down | Livreurs sans commandes | Double gateway (fallback) + push comme primaire |
| Fraude wallet (crédit fictif) | Pertes financières | Réconciliation CinetPay obligatoire, aucun crédit wallet sans transaction CinetPay confirmée |
| Fuite données KYC | Perte de confiance + APDP | Chiffrement at rest + accès restreint + audit logs |
| Google Maps indisponible | Navigation livreurs cassée | Cache offline des zones de livraison Bouaké |

## Innovation & Novel Patterns

### Detected Innovation Areas

**1. ERP Trojan Horse — Acquisition par l'outil**
Aucune marketplace food/delivery en Afrique n'offre un ERP B2B freemium comme outil d'acquisition. Les concurrents (Glovo, Yango) acquièrent les marchands par des commissions basses (temporaires). mefali les acquiert par un outil qui crée de la valeur indépendamment de la marketplace. Le marchand devient dépendant de l'ERP avant de rejoindre la marketplace — inversion complète du funnel classique.

**2. Architecture SMS-first / offline-native**
Les apps de livraison traitent l'offline comme un edge case. mefali le traite comme l'architecture primaire. Le système SMS avec deep link Base64 permet à un livreur de recevoir, comprendre et exécuter une commande complète sans aucune connexion data — une première dans le food delivery africain.

**3. Parrainage livreur avec responsabilité partagée**
Au lieu d'un score de fiabilité algorithmique (comme Uber/Glovo), mefali utilise un mécanisme social : le parrain (max 3 filleuls) engage sa réputation. En cas de problème, c'est le parrain qui est contacté en premier. Ce système reproduit le mécanisme de confiance traditionnel africain (le garant) dans un contexte digital.

**4. Système 4 états de disponibilité vendeur**
Les plateformes existantes ont un binaire ouvert/fermé. mefali ajoute "débordé" (accepte mais prévient du délai) et "auto-pausé" (après N non-réponses). Cela réduit les commandes annulées et protège l'expérience client sans punir le marchand.

**5. Protocole client absent — double flux**
Deux protocoles distincts selon le type de paiement :
- COD : timer → appel → retour marchand ou base → livreur payé quand même
- Prépayé : timer → appel → livraison alternative ou remboursement escrow
Aucun concurrent n'a un protocole documenté pour ce cas d'usage fréquent.

### Validation Approach

| Innovation | Comment valider | Signal de succès |
|-----------|----------------|-----------------|
| ERP Trojan Horse | Taux de conversion ERP-only → marketplace | > 50% en 90 jours |
| SMS-first | 0 commande perdue hors connexion | 100% delivery rate SMS |
| Parrainage livreur | Taux de litiges des parrainés vs non-parrainés | Litiges < 2% |
| 4 états disponibilité | Réduction commandes annulées par vendeur | < 5% annulation vendeur |
| Protocole client absent | Satisfaction livreur sur le protocole | NPS livreur > 60 |

### Risk Mitigation

| Innovation | Risque | Fallback |
|-----------|--------|---------|
| ERP Trojan Horse | Le marchand utilise l'ERP mais ne rejoint jamais la marketplace | L'ERP a de la valeur seul — le marchand est quand même monétisable via services financiers (Phase 2) |
| SMS-first | Les SMS sont bloqués/filtrés par l'opérateur | Double gateway + USSD comme second fallback |
| Parrainage | Le parrain ne prend pas la responsabilité au sérieux | Pénalité progressive : perte du droit de parrainer, puis révision du statut du parrain lui-même |
| 4 états | Les marchands n'utilisent pas le mode "débordé" | Auto-pause après N non-réponses — le système se protège automatiquement |

## Mobile App — Specific Requirements

### Project-Type Overview

mefali est un ensemble de 4 apps Flutter (Dart) cross-platform ciblant iOS et Android, avec un focus particulier sur les smartphones d'entrée de gamme Transsion (Tecno, Infinix, Itel) qui représentent ~60% du marché ivoirien.

### Platform Requirements

| Requirement | Spécification |
|------------|---------------|
| Framework | Flutter (Dart) — codebase unique iOS + Android |
| Android min | API 21 (Android 5.0) — couvre 99%+ du parc CI |
| iOS min | iOS 13 — couvre iPhone 6s+ |
| APK size | < 30 MB (contrainte stockage smartphones entrée de gamme) |
| RAM cible | Fonctionne sur 2 GB RAM (Tecno Spark, Itel A58) |
| Résolutions | 720p → 1080p (pas de 2K/4K nécessaire) |
| Langues | Français (unique au MVP) |

**Optimisation Transsion :**
- Test systématique sur Tecno Spark, Infinix Hot, Itel A58
- Animations réduites si RAM < 3 GB détectée
- Images catalogue compressées (WebP, max 200 KB)
- Pas de background services lourds

### Device Permissions

| Permission | App(s) | Justification |
|-----------|--------|---------------|
| **Localisation (GPS)** | Livreur, B2C | Navigation livreur + suivi temps réel client |
| **Caméra** | B2B, Admin | Photos catalogue, KYC (CNI/permis) |
| **SMS (lecture)** | Livreur, B2C | Auto-fill OTP inscription + réception commandes SMS |
| **Stockage** | Toutes | Cache offline, photos, données ERP |
| **Notifications push** | Toutes | Commandes, suivi, alertes |
| **Réseau** | Toutes | API calls, synchronisation |
| **Téléphone** | Livreur | Appel client absent directement depuis l'app |

### Offline Mode Architecture

**Principe : offline-first, pas offline-fallback**

**App Livreur (criticité maximale)**
- Réception commandes via SMS si push échoue (deep link Base64)
- Cache local des commandes actives (SQLite/Hive)
- File d'attente de synchronisation : confirmations collecte/livraison stockées localement, envoyées dès reconnexion
- GPS en mode offline : cache tuiles de carte pour la zone Bouaké

**App B2B/ERP (criticité haute)**
- Catalogue et stock consultables offline
- Saisie de commandes manuelles offline (sync au retour connexion)
- Dashboard ventes calculé localement à partir des données cachées
- Conflit de sync : last-write-wins avec timestamp serveur

**App B2C (criticité moyenne)**
- Catalogue consultable offline (dernière version cachée)
- Commande nécessite connexion (paiement CinetPay online)
- Suivi GPS nécessite connexion (temps réel)
- Historique commandes en cache local

### Push Notification Strategy

**Stack :** Firebase Cloud Messaging (FCM) pour toutes les apps

| Événement | App cible | Fallback si push échoue |
|-----------|----------|------------------------|
| Nouvelle commande | Livreur + B2B | **SMS avec deep link Base64** |
| Commande collectée | B2C | Aucun (client vérifie l'app) |
| Livreur en approche (ETA 2 min) | B2C | Aucun |
| Paiement wallet crédité | Livreur | SMS simple |
| Litige résolu | B2C | SMS simple |
| Rappel KYC / procédure | Livreur | SMS |

**Règle critique :** Les notifications livreur de nouvelle commande ont TOUJOURS un fallback SMS. C'est le cœur du SMS-first.

### Store Compliance

**Google Play Store**
- Politique de permissions : justification GPS (livraison), caméra (catalogue/KYC), SMS (OTP + commandes offline)
- Politique de paiements : CinetPay (externe) est autorisé car c'est un paiement de biens physiques, pas de biens numériques
- APK < 150 MB (limite Play Store) — largement respecté avec < 30 MB
- Rating cible : 16+ (paiements in-app)

**Apple App Store**
- App Review : justifier l'usage de SMS reading (OTP auto-fill)
- In-App Purchases : non applicable (paiements de biens physiques via CinetPay)
- Privacy Nutrition Label : déclarer GPS, caméra, contacts (optionnel)

### Implementation Considerations

**4 apps = monorepo Flutter avec packages partagés**
- Core packages : auth, API client, offline sync, push, analytics
- Packages spécifiques par app : UI B2C, UI B2B, UI Livreur, UI Admin
- Avantage : maintenance unifiée, tests partagés, déploiement indépendant

**Backend API**
- Actix Web (Rust) : API principale (commandes, marchands, livreurs)
- FastAPI (Python) : services IA (Phase 2), analytics
- PostgreSQL : base principale
- Redis : cache, queues, sessions, rate limiting

## Project Scoping & Phased Development

### MVP Strategy & Philosophy

**Approche : Problem-Solving MVP — prouver le modèle en 3 mois**

mefali est développé par une équipe de 4 développeurs. Cette taille permet de paralléliser les 4 apps Flutter et le backend, tout en maintenant le lean MVP nécessaire au break-even M3.

### Resource Requirements

| Rôle | Personnes | Phase |
|------|----------|-------|
| Développeurs full-stack | 4 (Flutter + Rust/Python + infra) | MVP |
| Agent(s) terrain (onboarding + KYC) | 1-2 à recruter | Pré-lancement |
| Ops / support litiges | Agent terrain (cumul initial) | MVP |

**Répartition dev suggérée :**

| Dev | Focus principal | Focus secondaire |
|-----|----------------|-----------------|
| Dev 1 (lead) | Backend API Actix Web (Rust) + PostgreSQL | Architecture, CinetPay integration |
| Dev 2 | App B2B/ERP (Flutter) | Packages partagés monorepo |
| Dev 3 | App B2C + App Livreur (Flutter) | SMS fallback, offline sync |
| Dev 4 | App Admin (Flutter Web) + DevOps | CI/CD, infra, monitoring |

### MVP Feature Set (Phase 1 — Bouaké, M1-M3)

**Ordre de développement :**

```
Semaines 1-2 : Setup monorepo + packages core + backend API skeleton + CinetPay integration
Semaines 3-6 : 4 apps en parallèle (chaque dev sur son app)
Semaines 7-9 : Intégration cross-app + SMS fallback + tests terrain
Semaines 10-12 : Lancement Bouaké + polish + monitoring
```

**Core journeys maintenus sans compromis :**
- Adjoua reçoit une commande et la prépare ✅
- Koné livre et est payé en < 5 min ✅
- Koffi commande, suit, paie COD ✅
- Fatou onboarde marchands et livreurs via Admin ✅
- Awa résout les litiges via Admin ✅
- SMS fallback si Koné perd la connexion ✅
- Escrow CinetPay fonctionnel ✅

### Post-MVP Features

**Phase 2 (M4-M9) — Expansion**
- Extension 2-3 villes (Yamoussoukro, San-Pédro)
- Agent IA conversationnel
- Tontine digitale
- Micro-crédit Baobab
- Logistique inter-villes multi-tronçons

**Phase 3 (M19-M30) — Abidjan + Scale**
- Entrée Abidjan via réseau marchands ERP
- ERP OHADA avancé
- ML on-device (prévisions stock)
- Prestataires services non-food
- Micro-assurance AXA

### Risk Mitigation Strategy

**Risques techniques**

| Risque | Impact | Mitigation |
|--------|--------|-----------|
| Intégration CinetPay complexe | Paiements bloqués | Dev 1 démarre CinetPay dès semaine 1 — chemin critique |
| Sync offline fragile | Données incohérentes | Tests offline dédiés dès semaine 5, protocole de résolution de conflits |
| 4 apps Flutter = overhead monorepo | Dépendances cassées | CI/CD stricte (Dev 4), packages versionnés, tests d'intégration |
| Performance smartphones Transsion | UX dégradée | Tests sur vrais devices (Tecno Spark, Itel A58) dès semaine 4 |

**Risques marché**

| Risque | Impact | Mitigation |
|--------|--------|-----------|
| Marchands de Bouaké n'adoptent pas | Pas de break-even | Agent terrain recruté AVANT lancement — 50 marchands pré-signés |
| Pas assez de livreurs | Commandes non livrées | 10 livreurs parrainés au lancement, croissance organique |
| Yango Deli arrive à Bouaké | Concurrence directe | Improbable court terme (Yango focus Abidjan). ERP non copiable |

**Risques ressources**

| Risque | Impact | Mitigation |
|--------|--------|-----------|
| Un dev quitte pendant le MVP | -25% vélocité | Monorepo + packages partagés = n'importe quel dev peut reprendre |
| Coûts infra | Budget | Stack lean : VPS Hetzner (~30€/mois), PostgreSQL managé, FCM gratuit |
| Budget agent terrain | Pas d'onboarding | Commission variable sur marchands onboardés — pas de fixe |

## Functional Requirements

### Gestion de Compte & Authentification

- FR1: Client B2C peut créer un compte via numéro de téléphone + SMS OTP
- FR2: Client B2C peut consulter et modifier son profil (nom, téléphone)
- FR3: Marchand peut créer un compte B2B assisté par un agent terrain
- FR4: Marchand peut consulter et modifier son profil commerce (nom, adresse, horaires, photos)
- FR5: Livreur peut créer un compte via KYC physique + parrain
- FR6: Agent terrain peut créer et valider les comptes marchands et livreurs
- FR7: Admin peut désactiver ou suspendre tout compte utilisateur

### Catalogue & Commerce

- FR8: Marchand peut gérer son catalogue produits (ajouter, modifier, supprimer avec photos et prix)
- FR9: Marchand peut gérer les niveaux de stock par produit
- FR10: Marchand peut définir son état de disponibilité (ouvert / débordé / auto-pausé / fermé)
- FR11: Client B2C peut parcourir les restaurants et marchands à proximité
- FR12: Client B2C peut consulter le catalogue d'un marchand avec photos, prix et notes
- FR13: Client B2C peut ajouter des produits au panier et passer commande
- FR14: Client B2C peut voir le prix total transparent avant confirmation (articles + frais de livraison)
- FR15: Marchand peut recevoir, accepter ou refuser les commandes entrantes
- FR16: Marchand peut marquer une commande comme "prête pour collecte"
- FR17: Système auto-pause un marchand après 3 non-réponses consécutives

### Livraison & Logistique

- FR18: Livreur peut recevoir des missions de livraison via notification push
- FR19: Livreur peut recevoir des missions via SMS avec données de commande encodées quand hors connexion
- FR20: Livreur peut accepter ou refuser une mission
- FR21: Livreur peut confirmer la collecte chez le marchand
- FR22: Livreur peut naviguer vers l'adresse de livraison via GPS intégré
- FR23: Livreur peut confirmer la livraison complétée
- FR24: Livreur peut déclencher le protocole "client absent" (timer + appel + routing)
- FR25: Client B2C peut suivre sa livraison en temps réel sur une carte
- FR26: Livreur peut définir son statut de disponibilité (actif / en pause)
- FR27: Système peut assigner les livraisons aux livreurs disponibles les plus proches
- FR28: Système peut mettre en file d'attente les confirmations offline et synchroniser au retour de connexion

### Paiements & Wallet

- FR29: Client B2C peut payer en cash à la livraison (COD)
- FR30: Client B2C peut payer via mobile money (Orange Money, MTN MoMo, Wave) via CinetPay
- FR31: Système retient le paiement en escrow jusqu'à confirmation de livraison
- FR32: Livreur reçoit le paiement sur son wallet < 5 min après confirmation de livraison
- FR33: Livreur peut retirer son solde wallet vers mobile money
- FR34: Marchand reçoit le paiement sur son wallet après libération escrow
- FR35: Marchand peut retirer son solde wallet vers mobile money
- FR36: Système peut réconcilier les soldes wallet internes avec CinetPay quotidiennement
- FR37: Admin peut créditer un avoir sur le wallet client (résolution litige)

### Communication & Notifications

- FR38: Système envoie des notifications push pour commandes, statuts livraison, paiements
- FR39: Système bascule en SMS quand la notification push échoue (événements critiques livraison)
- FR40: Livreur peut appeler le client directement depuis l'app (scénario client absent)
- FR41: Client B2C peut noter le marchand et le livreur après livraison (double notation)
- FR42: Client B2C peut partager un marchand ou l'app via lien WhatsApp

### Gestion B2B / ERP

- FR43: Marchand peut consulter un dashboard de ventes hebdomadaire (total ventes, répartition par produit)
- FR44: Marchand peut recevoir des alertes quand le stock d'un produit descend sous 20% du stock initial
- FR45: Marchand peut gérer ses horaires d'ouverture et fermetures exceptionnelles
- FR46: Marchand peut consulter son historique de commandes et détails des transactions

### Administration & Opérations

- FR47: Agent terrain peut onboarder un marchand via flux guidé étape par étape
- FR48: Agent terrain peut capturer les documents KYC (CNI, permis) via caméra
- FR49: Agent terrain peut valider le KYC livreur avec confirmation du parrain
- FR50: Agent terrain peut consulter son dashboard de performance d'onboarding
- FR51: Admin peut consulter le dashboard opérationnel temps réel (commandes, marchands, livreurs)
- FR52: Admin peut gérer et résoudre les litiges avec timeline complète de la commande
- FR53: Admin peut configurer les zones de livraison pour une ville
- FR54: Client B2C peut signaler un litige (commande incomplète, problème qualité)
- FR55: Admin peut consulter l'historique marchand et livreur (commandes, litiges, notes)

### Parrainage Livreurs

- FR56: Livreur peut parrainer de nouveaux livreurs (max 3 filleuls actifs)
- FR57: Système contacte le parrain en premier quand un filleul a un problème
- FR58: Système retire le droit de parrainage si les filleuls accumulent des problèmes
- FR59: Agent terrain peut montrer une démo interactive de l'app au marchand avant inscription

## Non-Functional Requirements

### Performance

| NFR | Mesure | Justification |
|-----|--------|---------------|
| NFR1: Latence API (p95) | < 500ms | Réseau 3G CI — l'UX doit rester fluide |
| NFR2: Temps d'ouverture app | < 3s cold start | Smartphones 2 GB RAM — au-delà, l'utilisateur ferme |
| NFR3: Taille APK | < 30 MB | Contrainte stockage Tecno/Itel entrée de gamme |
| NFR4: Consommation data session type | < 5 MB/heure d'usage actif | Forfaits data chers (500 FCFA/jour) |
| NFR5: Sync offline → serveur | < 60s après reconnexion | Cohérence données ERP et confirmations livraison |
| NFR6: Chargement catalogue marchand | < 2s (images comprises) | Images WebP < 200 KB, lazy loading |
| NFR7: Mise à jour position GPS livreur | Toutes les 10s en livraison active | Compromis entre précision suivi et batterie/data |

### Security

| NFR | Mesure | Justification |
|-----|--------|---------------|
| NFR8: Chiffrement données en transit | TLS 1.2+ sur toutes les API | Standard minimum — données de paiement |
| NFR9: Chiffrement documents KYC at rest | AES-256 | CNI/permis = données personnelles sensibles (APDP) |
| NFR10: Tokens d'authentification | Expiration < 24h avec rotation automatique | Protection contre vol de session |
| NFR11: Aucun crédit wallet sans transaction CinetPay confirmée | 100% des crédits tracés | Anti-fraude wallet — réconciliation obligatoire |
| NFR12: Accès aux données KYC | Restreint aux rôles Admin + Agent terrain uniquement | Principe du moindre privilège |
| NFR13: Logs d'audit | Toute action admin/agent terrain loguée avec timestamp et acteur | Traçabilité conformité APDP |
| NFR14: Consentement GPS explicite | Opt-in avec explication claire avant activation | Conformité APDP — localisation = donnée sensible |

### Scalability

| NFR | Mesure | Justification |
|-----|--------|---------------|
| NFR15: Utilisateurs concurrents MVP | 500 simultanés (50 marchands + 20 livreurs + clients) | Dimensionnement Bouaké M3 |
| NFR16: Croissance Phase 2 | 5 000 simultanés sans dégradation > 10% | 3 villes, 150+ marchands, 60+ livreurs |
| NFR17: Base de données | Partitionnement géographique par ville préparé | Évite la migration douloureuse à l'expansion |
| NFR18: Stockage photos | CDN avec compression automatique WebP | Le catalogue photos grossit linéairement avec les marchands |
| NFR19: SMS gateway | 1 000 SMS/heure en pic | Dimensionné pour 500 commandes/jour avec fallback SMS |

### Reliability

| NFR | Mesure | Justification |
|-----|--------|---------------|
| NFR20: Uptime global | > 99% (< 7h downtime/mois) | Chaque heure down = commandes perdues |
| NFR21: Paiement livreur post-confirmation | < 5 min dans 99.5% des cas | Promesse produit — 0 exception tolérée |
| NFR22: SMS fallback delivery | < 30s après échec push | La commande ne doit jamais être perdue |
| NFR23: Zéro perte de données offline | 100% des actions offline synchronisées | File d'attente persistante côté client |
| NFR24: Crash rate app | < 1% des sessions | Test obligatoire sur Transsion devices |
| NFR25: Backup base de données | Quotidien, rétention 30 jours | Récupération possible en cas de sinistre |

### Integration

| NFR | Mesure | Justification |
|-----|--------|---------------|
| NFR26: CinetPay API latence | < 3s pour une transaction paiement | Au-delà, timeout + retry automatique |
| NFR27: CinetPay disponibilité | Gestion des indisponibilités avec queue + retry | File d'attente si CinetPay down |
| NFR28: SMS gateway dual provider | Basculement automatique si provider 1 échoue | Zéro commande perdue |
| NFR29: Google Maps API | Cache offline des zones de livraison actives | Fonctionnement même si API indisponible |
| NFR30: Push notification delivery rate | > 95% des push livrées en < 5s | Le reste couvert par SMS fallback |
