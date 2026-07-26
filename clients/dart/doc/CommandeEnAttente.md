# mefali_api_client.model.CommandeEnAttente

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ageS** | **int** | Ancienneté dans la file, en secondes — **c'est elle qui ordonne**. | 
**commandeId** | **String** | Commande concernée. | 
**devise** | **String** | Devise ISO 4217. | 
**montantAAvancer** | **int** | Montant total que le coursier devra avancer (unités mineures). | 
**nbCollectes** | **int** | Nombre d'arrêts de collecte à desservir. | 
**premiereCollecteLat** | **double** | Latitude du premier site VENDEUR — donnée professionnelle. Aucune coordonnée du client n'est exposée ici (minimisation ARTCI). | [optional] 
**premiereCollecteLon** | **double** | Longitude du premier site vendeur. | [optional] 
**zoneId** | **String** | Zone de la commande. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


