# mefali_api_client.model.RemisePreprovisionnee

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretRemiseId** | **String** | Arrêt de REMISE — la cible de « je suis arrivé chez le client » (FR-053). Il n'est PAS dans `arrets`, qui ne porte que les collectes. | [optional] 
**arretRemiseStatut** | **String** | Statut de l'arrêt de remise (`a_collecter` | `en_route` | `arrive`). | [optional] 
**arriveChezClientLe** | [**DateTime**](DateTime.md) | Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052). | [optional] 
**codeBloque** | **bool** | Saisie du code bloquée (K4-1d). | 
**empreinteCode** | **String** | Empreinte salée du code à 4 chiffres — **jamais le code** (FR-037). | 
**empreinteJeton** | **String** | Empreinte du jeton de réception — **jamais le jeton**. | 
**essaisConsommes** | **int** | Essais faux déjà comptés côté serveur. | 
**essaisMax** | **int** | Seuil de zone `commande.essais_code_livraison` (cycle 008, réutilisé). | 
**modePaiement** | **String** | `cash` | `mobile_money`. | 
**montantAEncaisserUnites** | **int** | Total à encaisser chez le client (unités mineures). | 
**preuves** | [**SeuilsPreuves**](SeuilsPreuves.md) | Seuils de preuve de la zone. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


