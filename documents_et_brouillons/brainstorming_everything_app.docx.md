

**DOCUMENT DE BRAINSTORMING**

**EVERYTHING APP**  
Super App Africaine

*Conception d’un écosystème d’applications intégrées pour le marché ivoirien et africain, combinant services de livraison, restauration, courses, et outils de gestion B2B avec intelligence artificielle.*

**Marché cible :** Côte d’Ivoire (Tiassalé en priorité)

**Langues :** Français / Anglais

**Stack technique :** Flutter \+ Actix Web (Rust) \+ FastAPI (Python)

**Date :** Mars 2026

# **1\. Vision & Positionnement Stratégique**

## **1.1 Vision du Projet**

L’Everything App est un écosystème d’applications tout-en-un, conçu spécifiquement pour le marché africain en commençant par la Côte d’Ivoire. L’objectif est de devenir la super app de référence en Afrique de l’Ouest, à l’image de ce que WeChat représente en Chine ou Gojek en Asie du Sud-Est, mais adaptée aux réalités locales.

Le projet repose sur trois piliers fondamentaux :

* **Simplicité absolue :** une interface intuitive accessible aux utilisateurs non techniques, avec des workflows courts et un onboarding guidé.

* **Intelligence artificielle omniprésente :** des agents IA capables d’effectuer toutes les actions utilisateur, de naviguer entre les pages, d’activer des onboarding guidé et d’assister les professionnels avec des modules spécialisés (comptabilité, marketing, commercial).

* **Extensibilité infinie :** une architecture modulaire permettant d’intégrer de nouveaux services à tout moment sans refonte.

## **1.2 Analyse Concurrentielle**

| Concurrent | Forces | Faiblesses | Notre avantage |
| :---- | :---- | :---- | :---- |
| **Glovo** | Présence établie, logistique rodée | App générique, pas d’IA, pas d’ERP B2B, aucune livraison inter-villes | IA intégrée, écosystème complet B2C+B2B |
| **Jumia Food** | Marque connue, catalogue large | UX complexe, focus uniquement food | Multi-services, UX simplifiée pour l’Afrique |
| **Yango** | Technologie russe solide, prix compétitifs | Peu de diversification, pas d’outils business, limité à Abidjan | Diversité de services \+ outils de gestion |

## **1.3 Différenciateurs Clés**

1. **Agents IA ultra-optimisés :** chatbot capable d’exécuter les actions du client (commander, réserver, suivre, annuler. Lorsqu’une action du user est effectuée par une IA, la trace enregistrée de le mentionner) et agents spécialisés pour l’ERP B2B avec système de versions/mises à jour.

2. **Diversité de services :** restaurant \+ coursier \+ livreur au lancement, puis expansion rapide vers d’autres verticales (gaz, pressing, artisans, santé, etc.).

3. **Double écosystème :** l’app B2C génère la demande, l’ERP B2B fidélise les prestataires qui deviennent dépendants de l’outil de gestion. Un client peut utiliser l’ERP B2B sans pour autant exposer ses service directement au client B2C. Le user peu choisir d’exposer ses services(exposés par défaut) c’est dans ce cas  qu’ils apparaisse dans l’app B2C.

4. **Pensé pour l’Afrique :** UX adaptée aux non-tech, paiement mobile natif (CinetPay, Orange Money, Wave), mode hors-ligne partiel possible, système innovant de commande par sms(lorsque le user n’a pas de connexion, un code constitué de sa commande est envoyé par sms à notre serveur qui déclenche la commande aussitôt). Par exemple \*id\_restaurant\*id\_plat\*quanté\*achat\*longitude\*latitude\*etc\#.

5. **Livraison inter-villes multi-tronçons :** aucun concurrent ne livre entre les villes en Côte d’Ivoire. Notre système décompose intelligemment une livraison en tronçons (livreur moto → car inter-urbain → livreur moto(ou camion pour les gros colis)) en exploitant le réseau de gares routières existant. Cela ouvre le marché de TOUT le pays, pas seulement Abidjan. Possible de commander aussi hors du pays.

# **2\. Architecture des Applications**

## **2.1 Vue d’ensemble de l’Écosystème**

L’écosystème se compose de quatre applications interconnectées, chacune avec un rôle distinct :

| Application | Cible | Rôle Principal | Technologie |
| :---- | :---- | :---- | :---- |
| **App Cliente (B2C)** | Utilisateurs finaux | Commander, réserver, suivre, payer | Flutter (iOS \+ Android) |
| **App Prestataire (B2B)** | Restaurants, coursiers, boutiques | Gérer commandes, stocks, comptabilité | Flutter (tablette \+ mobile) |
| **App Livreur** | Livreurs freelance/partenaires | Accepter/suivre/compléter livraisons | Flutter (mobile optimisé) |
| **App Admin** | Équipe interne | Monitoring, KPI, support, modération | Flutter Web / Dashboard |

## **2.2 Application Cliente B2C — Détail**

### **2.2.1 Page d’accueil**

La page d’accueil doit être aérée et immédiatement compréhensible. Structure proposée :

* **AppBar :** Localisation actuelle (cliquable pour modifier) | Barre de recherche globale | Icône notifications | Icône panier/wallet

* **Grille de services :** Icônes pour chaque service (Restaurant, Coursier, Livreur, etc.).

* **Section recommandations :** Plats/services recommandés basés sur l’historique et la localisation, promos en cours.

* **Bouton IA flottant :** Accès rapide au chatbot IA (phase 2+) pour effectuer toute action par conversation. L’IA pourrait accéder à toutes les données du user pour lui faire des recommandation ciblé selon ses demandes: plat diète, plat etc.

* **Pas de barre de navigation, plutôt un sideBar :** Accueil | Commandes | Wallet | Profil etc..

* lorsqu’il ya commande en cours, cela s'affiche à la page d’accueil sinon il faut voir l’historique dans le sideBar

### **2.2.2 Modules B2C au Lancement**

**Module Restaurant**

* Listing des restaurants avec filtres : distance, note, cuisine, budget, ouvert maintenant.

* Fiche restaurant : menu par catégories, photos, avis, horaires, option abonnement si proposé.

* Personnalisation de commande : quantité, extras, instructions spéciales, choix du mode de livraison.

* Modes de livraison : Express (livreur assigné immédiatement, estimation temps) ou Programmée (choix date/heure).

* Attribution automatique d’un livreur du pool si le restaurant n’a pas de livreur propre.

* Abonnement restaurant : formules définies par le prestataire (ex: 5 déjeuners/semaine pour X FCFA).

**Module Coursier**

* L’utilisateur crée une demande de course : liste d’articles ou description libre.

* Priorité donnée aux points agréés/partenaires pour les achats (meilleur contrôle qualité et prix).

* Si produit indisponible en point agréé, le coursier cherche ailleurs avec validation prix par le client.

* Suivi en temps réel du coursier sur la carte.

* Photo de confirmation des achats avant livraison(facultatif).

**Module Livraison**

* Service de livraison pure : l’utilisateur ou un vendeur en ligne envoie un colis d’un point A à un point B.

* Calcul automatique du tarif selon distance, poids/taille estimés.

* Disponible pour les restaurants sans livreur propre (intégration automatique dans le flux restaurant).

* Disponible pour les vendeurs en ligne (e-commerce informel, vendeurs facebook/WhatsApp).

**Livraison Inter-Villes Multi-Tronçons**

C’est l’un des différenciateurs majeurs du projet. En Côte d’Ivoire, il existe déjà un système logistique informel : les gens confient des colis aux chauffeurs de cars dans les gares routières. C’est rapide et pas cher, mais non tracé, non sécurisé, sans recours en cas de perte. Notre système digitalise et fiabilise cette infrastructure existante.

**Principe :** lorsqu’un client à Yamoussoukro commande un produit dans une boutique agréée à Abidjan, le système décompose automatiquement la livraison en plusieurs tronçons (legs) :

* **Leg 1 — Premier kilomètre :** un livreur moto local récupère le colis à la boutique et le dépose à la gare routière la plus proche (ex: Gare d’Adjamé).

* **Leg 2 — Transport inter-urbain :** le colis voyage par car avec une compagnie partenaire (UTB, TCV, etc.) jusqu’à la gare de la ville de destination.

* **Leg 3 — Dernier kilomètre :** un livreur moto local à Yamoussoukro récupère le colis à la gare et le livre au client. Le client peut aussi choisir de venir le chercher lui-même à la gare pour économiser ce tronçon.

**Réseau de Points de Relais :** le système s’appuie sur un graphe de points de relais interconnectés. Quatre types de points de relais sont prévus :

* **Gares routières :** hubs principaux inter-villes. Partenariats avec les compagnies de transport (UTB, TCV, STIF). Ex: Gare d’Adjamé, Gare de Yamoussoukro, Gare de Bouaké.

* **Points agréés :** boutiques partenaires qui servent de point de dépôt/retrait local. Déjà présents dans l’écosystème.

* **Hubs logistiques (futur) :** mini-entrepôts propres dans les grandes villes pour regrouper et trier les colis à terme.

* (brouillon): lorsque le livreur est en train de livrer un colis, s’il y’a demande livraison pas loins de son itinéraire(distance à définir) et lieu de livraison pas loins ou dans la continuité de sa trajectoire, alors il peut récupérer

**Exemple concret Abidjan → Yamoussoukro :**

| Leg | Trajet | Transport | Durée | Coût estimé | Porteur |
| :---- | :---- | :---- | :---- | :---- | :---- |
| **1** | Boutique Cocody → Gare Adjamé | Moto | 25 min | 1 000 FCFA | Livreur moto |
| **2** | Gare Adjamé → Gare Yamoussoukro | Car UTB | 3h30 | 1 500 FCFA | UTB |
| **3** | Gare Yamoussoukro → Client | Moto | 15 min | 500 FCFA | Livreur moto |
|  | **TOTAL** |  | **\~4h10** | **2 900FCFA** |  |

**Algorithme de décomposition intelligente :** le système détecte automatiquement qu’une livraison est inter-villes (ville d’origine ≠ ville de destination), identifie les gares/points de relais disponibles dans chaque ville, calcule les routes candidates avec coût, durée et fiabilité, puis propose 2-3 options au client. Le client peut choisir entre un mode standard, express (prochain car disponible) ou économique (moins cher mais plus long).

**Système de Handoff sécurisé :** chaque passage de relais entre transporteurs est vérifié par un code unique à 6 caractères, une double confirmation (déposant \+ récepteur), une photo du colis, et un géofencing pour vérifier que le livreur est bien au bon endroit. Le client reçoit une notification push à chaque étape : dépôt en gare, départ du car, arrivée en gare, prise en charge dernier km, livraison.

**Option retrait en gare :** le client peut choisir de récupérer son colis directement à la gare de destination au lieu de payer le tronçon dernier kilomètre. Il économise le coût du leg 3 et reçoit un QR code de retrait. Un délai de 48h est accordé, au-delà des frais de stockage s’appliquent.

**Partenariats transport :** les compagnies de transport (UTB, TCV, etc.) sont traitées comme des prestataires B2B dans l’écosystème. Elles disposent d’un module dédié dans l’app B2B pour gérer les colis à transporter, confirmer les chargements/déchargements, et consulter leur facturation.

**Gestion des incidents :** le système gère automatiquement les cas problématiques : colis raté un départ (reprogrammation), car en retard (mise à jour estimation client), colis endommagé (comparaison photos départ/arrivée \+ assurance), colis perdu (enquête \+ remboursement), client absent (retour en gare \+ reprogrammation).

(brouillon): les assurances seront gérées avec un partenariat avec les structures d’assurance.

### **2.2.3 Fonctionnalités Transversales B2C**

* **Wallet intégré :** rechargement via CinetPay (Orange Money, MTN MoMo, Wave, carte bancaire). Solde affiché en permanence. Retrait possible sous conditions.

* **Suivi en temps réel :** map avec position du livreur/coursier, notifications push à chaque étape.

* **Système de notation :** double notation (client note le prestataire ET le livreur), avis textuels.

* **Historique complet :** toutes les commandes passées, re-commande en un clic.

* **Multilingue :** FR/EN avec détection automatique et switch facile.

* **Light/Dark mode :** respect des préférences système \+ switch manuel.

* **Notifications intelligentes :** promos personnalisées, rappels d’abonnement à un service, suivi de commande.

## **2.3 Application Prestataire B2B — Détail**

### **2.3.1 Deux modes d’utilisation**

L’application B2B doit s’adapter au profil du prestataire. Deux modes existent dès l’onboarding :

| Critère | Mode Solo / Freelance | Mode Entreprise |
| :---- | :---- | :---- |
| **Interface** | Épurée, essentiel uniquement | Complète, modulaire, personnalisable |
| **Gestion** | 1 seul compte, 1 seul point de vente(migration possible vers mode Entreprise) | Multi-sites, multi-employés, rôles |
| **Fonctionnalités** | Commandes, menu, horaires, stats de base(migration possible vers mode Entreprise) | \+ Comptabilité, CRM, marketing, RH, stocks |
| **Agents IA** | Assistant basique (aide commandes) | Agents spécialisés versionnables (comptabilité, commercial, marketing, etc.) |
| **Tarification** | Gratuit ou commission seule | Abonnement par module/agent \+ commission |

### **2.3.2 Modules ERP B2B (débloquables)**

Chaque module est indépendant et activable. Cela permet une monétisation granulaire et une complexité progressive :

* **Gestion des commandes (inclus) :** réception, validation, préparation, suivi. Notifications sonores et visuelles pour nouvelles commandes.

* **Gestion du menu/catalogue (inclus) :** ajout/modification de produits, catégories, prix, disponibilité, photos.

* **Gestion des abonnements (inclus) :** création de formules d’abonnement, suivi des abonnés, renouvellements.

* **Tableau de bord / Analytics (inclus) :** ventes du jour/semaine/mois, commandes, revenus, produits populaires.

* **Gestion des stocks (inclus) :** inventaire, alertes de stock bas, historique des mouvements.

* **Comptabilité simplifiée (module payant) :** entrées/sorties, rapports financiers, export comptable.

* **CRM / Gestion clients (module payant) :** base clients, segmentation, historique des interactions.

* **Marketing (module payant) :** création de promos, push notifications ciblées, analyse de campagnes.

* **Gestion RH (module payant) :** employés, plannings, performances, paie simplifiée.

* **Multi-sites (module payant) :** gestion centralisée de plusieurs points de vente avec stats consolidées.

### **2.3.3 Système d’Agents IA B2B**

Les agents IA sont le cœur du différenciateur B2B. Chaque agent est spécialisé dans un domaine et peut évoluer indépendamment(Les agents sont doté de skills ultra sotiphisqués) :

* **Agent généraliste :** il fera le lien entre les autres agents lorsque l’utilisateur ne sais pas à qui s’adresser.

* **Agent Comptable :** analyse des flux financiers, détection d’anomalies, suggestions d’optimisation, génération de rapports.

* **Agent Commercial :** analyse des ventes, recommandations de pricing, identification des tendances, prévisions.

* **Agent Marketing et  Marketing digital:** suggestions de campagnes, analyse ROI, segmentation automatique, génération de contenu promo, génération de vidéo et post pour les réseaux sociaux etc…

* **Agent RH :** optimisation des plannings, analyse de performance, suggestions de formation.

Chaque agent a un système de versions. Le prestataire peut mettre à jour ses agents pour bénéficier de nouvelles capacités, skills(La mise à jour est gratuite).

(brouillon): fonctionnalité: le prestataire peut définir des objectif dans 1, 3, 6 (etc) mois, 

## **2.4 Application Livreur**

Application dédiée aux livreurs partenaires (freelances et entreprises de livraison partenaires) :

* **Dashboard livreur :** courses disponibles à proximité, revenus du jour, historique.

* **Acceptation de course :** notification push avec détails (distance, estimation gain), accepter/refuser.

* **Navigation intégrée :** itinéraire optimisé vers point de retrait puis point de livraison(tu me proposera des solutions existante).

* **Confirmation de livraison :** photo, signature numérique ou code de confirmation.

* **Wallet livreur :** gains accumulés, retrait vers mobile money, historique des transactions.

## **2.5 Application Admin**

Dashboard web pour l’équipe interne de gestion et monitoring :

* **KPIs en temps réel :** nombre de commandes, CA, taux de satisfaction, livreurs actifs.

* **Gestion des prestataires :** validation des inscriptions, modération, suspension, vérification documents.

* **Gestion des livreurs :** pool de livreurs, performances individuelles, zones de couverture.

* **Support client :** tickets, litiges, remboursements, chat support.

* **Gestion financière :** commissions, paiements aux prestataires, réconciliation.

* **Configuration :** ajout de nouveaux services, paramétrage des commissions, zones géographiques.

* (brouillon): lorsqu’un client veut un produit qui n’est plus en stock chez la boutique par exemple, il peut voir la date du prochain réapprovisionnement(si disponible) et  cliquer sur un bouton de \`me notification lorsque le produit sera disponible\`, ainsi lorsque la boutique se réapprovisionnera, il recevra une notification push ou sms ou email.

# **3\. Modèle Économique**

## **3.1 Sources de Revenus**

| Source | Description | Cible | Estimation |
| :---- | :---- | :---- | :---- |
| **Commission par transaction** | Pourcentage sur chaque commande B2C | Tous les prestataires | 1-15% selon le service |
| **Frais de livraison** | Facturés au client, partagés avec le livreur | Clients B2C | Variable selon distance |
| **Abonnement ERP B2B** | Modules payants de l’ERP | Entreprises B2B | 0 \- 50 000 FCFA/mois par module |
| **Agents IA (versions)** | accès aux agents IA | B2B avancés | Mode 1: 5 000 \- 100 000 FCFA/mois par agent, Mode 2: paiement à l’usage |
| **Mise en avant / publicité** | Restaurant/boutique en position premium | Prestataires B2B | À définir |
| **Commission abonnements** | % sur les abonnements définis par le prestataire | Restaurants avec abonnements | 1-15% du montant |
| **Livraison inter-villes** | Marge sur chaque tronçon du transport multi-legs (premier km, car, dernier km) | Clients B2C inter-villes | 1-15% sur le coût total du transport |

## **3.2 Stratégie de Pricing**

La stratégie suit un modèle freemium progressif. Le prestataire freelance solo peut utiliser l’app gratuitement et ne paie qu’une commission par transaction. Dès qu’il a besoin de fonctionnalités avancées (comptabilité, multi-sites, agents IA), il passe sur des modules payants par abonnement mensuel. Cette approche permet d’attirer un maximum de prestataires puis de les convertir progressivement.

# **4\. Architecture Technique**

## **4.1 Stack Technologique**

| Couche | Technologie | Justification |
| :---- | :---- | :---- |
| **Frontend Mobile** | Flutter (Dart) | Cross-platform iOS/Android/Web, performances natives, écosystème riche |
| **Backend Principal** | Actix Web (Rust) | Ultra-performant, faible conso mémoire/CPU — critique avec contrainte serveur |
| **Services IA** | FastAPI (Python) | Accès natif à l’écosystème ML/IA (LangChain,LangGraph,  transformers, etc.) |
| **Base de données** | PostgreSQL \+ Redis | PostgreSQL pour la persistance, Redis pour le cache et les sessions temps réel |
| **Temps réel** | WebSockets (Actix) \+ Redis Pub/Sub | Suivi livreur en direct, notifications push, mises à jour commandes |
| **Paiement** | CinetPay (aggrégateur) | Phase 1 via aggrégateur, puis intégration directe opérateurs |
| **Conteneurisation** | Docker \+ Docker Compose (puis K8s) | Isolation des microservices, déploiement reproductible |
| **API Gateway** | Nginx / Traefik | Routage, rate limiting, SSL, load balancing |

## **4.2 Architecture Microservices**

L’utilisation intelligente de Rust (Actix) et Python (FastAPI) répond à la contrainte de ressources serveur. Le principe est simple : Rust pour tout ce qui est haute performance et haute fréquence, Python pour tout ce qui touche à l’IA.

**Services Actix Web (Rust) — haute performance :**

* Auth Service : inscription, connexion, JWT, gestion des sessions, permissions/rôles.

* Order Service : création, suivi, historique des commandes, logique métier commandes.

* Payment Service : wallet, transactions, intégration CinetPay, réconciliation.

* Delivery Service : matching livreur-commande, suivi GPS temps réel, estimation de temps, décomposition multi-tronçons pour les livraisons inter-villes, gestion du graphe de points de relais.

* Catalog Service : restaurants, menus, produits, recherche, recommandations basiques etc.

* Notification Service : push notifications, SMS, email, alertes temps réel.

* User Service : profils, préférences, adresses, historique.

**Services FastAPI (Python) — intelligence artificielle :**

* AI Chatbot Service : traitement du langage naturel, exécution d’actions, navigation contextuelle.

* AI Agents Service : agents spécialisés B2B (comptabilité, commercial, marketing), gestion des versions.

* Recommendation Engine : suggestions personnalisées, analyse comportementale.

* Analytics Service : traitement de données, génération de rapports, insights.

## **4.3 Stratégie d’Optimisation Ressources Serveur**

Avec une contrainte de ressources serveur, chaque décision architecturale doit être optimisée :

* **Rust par défaut :** Actix Web consomme 5 à 10x moins de RAM que Node.js/Django pour des charges équivalentes. Privilégier Rust pour tous les services à fort trafic.

* **Python uniquement pour l’IA :** FastAPI est léger mais Python reste gourmand. Limiter les instances Python aux seuls services IA, et les scaler indépendamment.

* **Redis agressif :** cacher toutes les requêtes fréquentes (menus, catalogues, configs). Réduit massivement la charge sur PostgreSQL.

* **CDN pour les assets :** images des plats, logos, etc. sur un MinIO (puis Amazone s3 plus tard).

* **Queue de messages :** utiliser Redis Streams pour les tâches asynchrones (envoi de notifications, génération de rapports, traitement IA).

## **4.4 Schéma de Base de Données (Entités Principales)**

Voici les entités fondamentales à structurer dès le départ. L’architecture multi-tenant permet à chaque prestataire B2B d’avoir ses données isolées :

* Users : id, type (client/prestataire/livreur/admin), email, téléphone, wallet\_id, langue, préférences.

* Businesses : id, owner\_id, type (restaurant/boutique/coursier), nom, adresse(s), mode (solo/entreprise), modules\_activés.

* Products : id, business\_id, nom, description, prix, catégorie, disponibilité, images.

* Orders : id, client\_id, business\_id, livreur\_id, statut, type (express/programmé/réservation), montant, commission.

* Subscriptions : id, client\_id, business\_id, formule\_id, début, fin, statut, renouvellement\_auto.

* Wallets : id, user\_id, solde, devise (XOF), statut.

* Transactions : id, wallet\_id, type (crédit/débit), montant, référence, source, statut.

* Deliveries : id, order\_id, livreur\_id, statut, pickup\_location, delivery\_location, positions\_gps\[\].

* Delivery\_Plans : id, order\_id, mode (standard/express/économique), legs\[\], coût\_total, durée\_estimée, statut. Utilisé pour les livraisons inter-villes multi-tronçons.

* Delivery\_Legs : id, plan\_id, numéro\_leg, type\_transport (moto/bus), origin\_relay, dest\_relay, livreur\_id, code\_handoff, statut.

* Relay\_Points : id, nom, ville, type (gare/point\_agréé/hub), coordonnées GPS, horaires, capacité, partenaire\_id.

* Relay\_Routes : id, origin\_id, destination\_id, type\_transport, compagnie\_partenaire, durée\_moyenne, coût, horaires\_départs.

* Tracking\_Events : id, plan\_id, leg\_id, type\_événement, position GPS, photo, acteur, horodatage.

* Parcels : id, order\_id, description, poids, dimensions, fragile, valeur\_déclarée, assurance.

* Reviews : id, order\_id, author\_id, target\_id, target\_type, note, commentaire.

* AI\_Agents : id, business\_id, type, version, config, statut.

# **5\. User Flows Détaillés**

## **5.1 Flow Client — Commande Restaurant**

1. Le client ouvre l’app et voit la page d’accueil avec la grille de services.

2. Il clique sur l’icône « Restaurant » et accède au listing avec filtres.

3. Il sélectionne un restaurant et consulte le menu par catégories.

4. Il ajoute des plats au panier avec personnalisation (quantité, extras, instructions).

5. Il choisit le mode : livraison express, livraison programmée, ou retrait sur place.

6. Il confirme l’adresse de livraison (pré-remplie via géolocalisation ou adresse enregistrée).

7. Il choisit le mode de paiement : wallet, mobile money, ou carte.

8. Il confirme la commande et reçoit un récapitulatif.

9. Il suit la préparation en temps réel (accepté → en préparation → prêt → en livraison → livré), livraison en temps réel aussi sur map.

10. Livraison reçue, il note le restaurant et le livreur.

## **5.2 Flow Client — Course avec Coursier**

1. Le client clique sur « Coursier » depuis la page d’accueil.

2. Il crée une demande : il sélectionne les produits dans la liste de produits disponibles dans la rubrique \`Magasin/Marché\`, lorsqu’il ne trouve pas dans la recherche, un bouton lui permet d’écrire manuellement ce dont il a besoins, .

3. Le système affiche une estimation de prix.

4. Un coursier est assigné (ou le client choisit un horaire programmé).

5. Le coursier se rend au point agréé et, prend les articles trouvés.

6. Si articles indisponibles, le coursier propose des alternatives avec prix — le client valide dans un délais précis pour ne pas que le livreur soit bloqué par des livreurs .

7. Le coursier finalise les achats, prend une photo du ticket(facultatif, certain vendeurs informel n’en disposent pas), et livre.

8. Le client reçoit la livraison, vérifie, et note le coursier.

(brouillon): il faut réfléchir à une solution de paiement à la livraison beaucoup appréciée et répandue chez mes concurrents en plus du paiement par mobile money. Il existe aussi des livreurs malhonnête qui peuvent acheter des quantités inférieures et empocher le surplus surtout chez les vendeurs informelle où il n’y a pas de prix/quantité fix, il faut trouver une solution pour ca.

## **5.3 Flow Prestataire B2B — Réception de Commande**

1. Le prestataire reçoit une notification sonore et visuelle de nouvelle commande.

2. Il voit le détail de la commande : articles, instructions spéciales, mode de livraison.

3. Il accepte ou refuse la commande (refus avec motif).

4. Il prépare la commande et met à jour le statut (« en préparation » → « prêt »).

5. Si le restaurant a un livreur propre, il assigne la livraison. Sinon, un livreur du pool est automatiquement assigné.

6. La commande est livrée, le montant (moins commission) est crédité sur le wallet du prestataire. (brouillon): Ou paiement à la livraison.

## **5.4 Flow Livreur — Course de Livraison**

1. Le livreur est en ligne et reçoit une notification de course disponible.

2. Il voit les détails : point de retrait, point de livraison, estimation de gain.

3. Il accepte la course et se rend au point de retrait (navigation intégrée).

4. Il confirme le retrait (scan ou photo).

5. Il se dirige vers le client avec suivi GPS en temps réel.

6. Il confirme la livraison (code, photo ou signature).

7. Le gain est crédité sur son wallet.(brouillon): ou paiement en main propre(il faut analyser comment mes concurren, yango et glovo procèdent)

## **5.5 Flow Client — Livraison Inter-Villes Multi-Tronçons**

Exemple : un client à Yamoussoukro commande un produit dans une boutique agréée à Abidjan.

1. Le client passe sa commande normalement. Le système détecte automatiquement que la ville de la boutique (Abidjan) est différente de la ville du client (Yamoussoukro).

2. Le système calcule les itinéraires multi-tronçons possibles et propose 2-3 options : standard (\~4h, 5 500 FCFA), express (prochain car, plus rapide) ou économique (moins cher, plus long).

3. Le client choisit son option et décide s’il veut la livraison dernier km ou un retrait en gare (économise le coût du dernier tronçon).

4. Un livreur moto à Abidjan est assigné. Il récupère le colis à la boutique et le dépose à la gare routière définie par le système (ex: Gare d’Adjamé). Handoff sécurisé par code \+ photo \+ géofencing.

5. L’agent de la gare confirme la réception. Le client est notifié : « Votre colis est en gare, prochain départ vers Yamoussoukro à 10h00 ».

6. Le colis voyage par car (UTB/TCV partenaire). Le système connaît les horaires de départ et l’heure d’arrivée estimée.

7. À l’arrivée à la gare de Yamoussoukro, l’agent confirme le déchargement. Le client est notifié immédiatement.

8. **Option livraison :** un livreur moto local à Yamoussoukro est automatiquement assigné pour le dernier kilomètre. Il récupère le colis en gare (handoff sécurisé) et livre le client chez lui.

9. **Option retrait :** le client se rend à la gare avec son QR code de retrait, l’agent remet le colis après vérification. Délai de 48h, frais de stockage au-delà.

10. Le client reçoit une notification push à chaque changement d’étape et peut suivre l’ensemble du parcours via une timeline visuelle dans l’app.

# **6\. Roadmap de Développement**

## **6.1 Phase 1 — MVP (Mois 1-4)**

**Objectif :** valider le modèle sur Tiassalé avec le service Restaurant uniquement.

* App B2C : onboarding, accueil, module restaurant (commande \+ livraison express), wallet, paiement CinetPay.

* App B2B : mode solo uniquement, gestion des commandes, menu, horaires, stats de base, stock.

* App Livreur : inscription, acceptation de courses, navigation, confirmation livraison.

* Backend : Auth, Order, Payment, Delivery, Catalog, Notification services (Rust).

* Pas d’IA à cette phase. Focus sur la fiabilité et la simplicité.

## **6.2 Phase 2 — Expansion Services (Mois 5-8)**

**Objectif :** ajouter les services Coursier et Livraison (dont inter-villes), enrichir le B2B.

* B2C : ajout modules Coursier et Livraison, livraison programmée, abonnements restaurant.

* Livraison multi-tronçons : déploiement du réseau de points de relais sur 2-3 axes (Abidjan ↔ Yamoussoukro, Abidjan ↔ Bouaké), partenariats UTB/TCV, recrutement de livreurs moto locaux dans les villes cibles.

* B2B : mode Entreprise (multi-sites, rôles), modules Stocks et Comptabilité simplifiée. Module dédié pour les compagnies de transport partenaires.

* Chatbot IA B2C basique : prise de commande par conversation, navigation assistée.

* Premiers agents IA B2B : assistant généraliste pour le prestataire.

## **6.3 Phase 3 — IA & ERP Complet (Mois 9-14)**

**Objectif :** déployer l’intelligence artificielle avancée et l’ERP complet.

* Chatbot IA B2C complet : exécution de toutes les actions utilisateur, confirmation pour actions critiques, navigation inter-pages.

* Agents IA B2B spécialisés : comptabilité, commercial, marketing, RH avec système de versions.

* Modules ERP complémentaires : CRM, Marketing, RH.

* Moteur de recommandation avancé côté B2C.

## **6.4 Phase 4 — Scaling & Nouveaux Services (Mois 15+)**

**Objectif :** expansion géographique et ajout de nouvelles verticales.

* Nouveaux services : gaz, pressing, artisans, santé, localisation gratuite, E-ticket voyage(avec des guichet d’impression qu’on aura placé), service de mécanicien, lavage à domicile, pièce de voiture, Groupage d’abonnement(vpn, netflix etc…), Groupage maritime,  etc.

* Expansion du réseau multi-tronçons : toutes les villes ivoiriennes, puis routes inter-pays UEMOA (Abidjan → Accra, Ouagadougou, Bamako).

* Hubs logistiques propres : mini-entrepôts dans les grandes villes pour regrouper et trier les colis \+ e-entrepot.

* IA d’optimisation logistique : regroupement intelligent de colis par destination, prédiction de demande.

* Intégration directe avec les opérateurs de paiement (sans aggrégateur).

* App Admin complète avec analytics avancés et outils de monitoring.

# **7\. Points de Vigilance & Risques**

## **7.1 Risques Identifiés**

| Risque | Probabilité | Impact | Mitigation |
| :---- | :---- | :---- | :---- |
| **Complexité technique excessive** | Élevée | Retards, bugs, dette technique | Architecture modulaire stricte, MVP minimaliste, tests automatisés |
| **Contrainte ressources serveur** | Élevée | Lenteurs, indisponibilité | Rust par défaut, cache Redis agressif, CDN, optimisation requêtes |
| **Acquisition prestataires** | Moyenne | Pas de contenu, pas de clients | Onboarding gratuit, démarchage terrain, commission compétitive |
| **Fiabilité des livreurs** | Moyenne | Mauvaise expérience client | Système de notation, bonus performance, partenariats entreprises livraison |
| **Réglementation wallet** | Moyenne | Problèmes juridiques | Le wallet est un solde interne, pas un e-money. Intégrer via CinetPay qui gère la conformité |
| **Concurrence (Glovo, Yango)** | Élevée | Difficulté d’acquisition | Différenciation IA, focus local, ERP B2B unique, meilleure UX |

## **7.2 Recommandations Structurantes**

* **Monorepo Flutter :** utiliser un monorepo avec packages partagés entre les 4 apps (modèles, thème, widgets communs, client API). Cela évite la duplication et facilite la cohérence.

* **API-first design :** définir les contrats API (OpenAPI/Swagger) avant de coder. Cela permet de travailler en parallèle front/back.

* **Feature flags :** utiliser des feature flags pour activer/désactiver des fonctionnalités sans redéploiement. Crucial pour le rollout progressif de nouveaux services.

* **Tests automatisés :** tests unitaires sur les services Rust (cargo test), tests d’intégration sur les workflows critiques, tests E2E Flutter.

* **CI/CD dès le jour 1 :** pipeline de déploiement automatisé avec GitHub Actions ou similaire. Chaque merge déclenche build \+ tests \+ déploiement staging.

* **Observabilité :** logging structuré (tracing en Rust), métriques (Prometheus), alerting. Indispensable pour détecter les problèmes avant les utilisateurs.

* **Sécurité dès le départ :** chiffrement des données sensibles, HTTPS partout, validation stricte des entrées, rate limiting, audit trail sur les transactions financières.

# **8\. Prochaines Étapes Immédiates**

Pour transformer ce brainstorming en action, voici les étapes prioritaires :

6. **Finaliser le Product Requirements Document (PRD) :** transformer ce brainstorming en spécifications détaillées pour le MVP (Phase 1), avec wireframes et critères d’acceptation.

7. **Définir les contrats API :** documenter chaque endpoint pour les services Rust du MVP (Auth, Order, Payment, Delivery, Catalog, Notification).

8. **Configurer l’infrastructure de développement :** monorepo Flutter, Docker Compose pour les microservices( CI/CD pipeline, environnement staging plutard).

9. **Démarcher les premiers prestataires :** identifier 10-20 restaurants à Tiassalé pour le pilote, leur présenter le projet et sécuriser leur participation.

*Ce document est vivant et sera mis à jour au fur et à mesure de l’avancement du projet.*