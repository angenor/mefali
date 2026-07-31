# mefali_api_client.model.LigneHistoriqueCaisse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**avanceUnites** | **int** | Ce que le coursier a avancé (positif). | 
**commandeId** | **String** | Commande concernée. | 
**enAttenteReglement** | **bool** | Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117). | 
**gainUnites** | **int** | Sa part sur cette course (devis figé du cycle 007). | 
**heure** | [**DateTime**](DateTime.md) | Heure de la première écriture (horodatage serveur). | 
**livraisonId** | **String** | Livraison concernée. | [optional] 
**reference** | **String** | Référence lisible (`#418`) — de quoi se parler au téléphone. | 
**rembourseUnites** | **int** | Ce qu'il a récupéré (positif). | 
**terminee** | **bool** | La course est-elle terminée ? | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


