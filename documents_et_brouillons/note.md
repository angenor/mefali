# App de Livraison — Solution SMS Hors Ligne

## Problème

Permettre au livreur de recevoir les détails d'une commande par SMS et de les consulter dans l'app, même sans connexion internet, sur iOS et Android.

## Solution retenue : Deep Link + Données encodées dans l'URL

Le serveur encode les infos de la commande (client, adresse, articles, montant) en **Base64** et les intègre dans un lien cliquable envoyé par SMS.

### Exemple de SMS envoyé

```
Nouvelle livraison !
https://livraison.app/cmd/S29uZS1Db2NvZHktMlBpenoxSnVzLTE1MDAw
Hors ligne : livraison://cmd/S29uZS1Db2NvZHktMlBpenoxSnVzLTE1MDAw
```

### Flux

1. **Serveur** → encode la commande en Base64 → envoie le SMS avec le lien
2. **Livreur** → clique sur le lien dans le SMS
3. **App** → s'ouvre, extrait les données de l'URL, les décode **localement** (sans internet)
4. **Écran** → affiche les détails de la commande

## Deux types de liens (à combiner)

- **Universal Links / App Links** (`https://livraison.app/cmd/...`) : propre et sécurisé, nécessite une première vérification internet.
- **Custom URL Scheme** (`livraison://cmd/...`) : fonctionne **toujours hors ligne**, aucune vérification serveur requise.

## Configuration requise

- **iOS** : fichier `apple-app-site-association` hébergé sur le domaine.
- **Android** : fichier `assetlinks.json` hébergé sur le domaine.
- **Custom URL Scheme** : déclaré dans le `Info.plist` (iOS) et `AndroidManifest.xml` (Android).

## Stack recommandée

- **Flutter** ou **React Native** (cross-platform iOS + Android)
- **Base64** pour l'encodage des commandes
- **SQLite / Hive** pour le cache local
- **Twilio / Firebase** pour l'envoi des SMS

## Limite

Un SMS est limité à 160 caractères. Pour les commandes longues, utiliser un format compressé ou pré-charger les données quand le réseau est disponible.