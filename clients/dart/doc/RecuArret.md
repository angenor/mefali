# mefali_api_client.model.RecuArret

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt collecté. | 
**collecteLe** | [**DateTime**](DateTime.md) | Instant du scan (horloge SERVEUR). | [optional] 
**devise** | **String** | Devise ISO 4217. | 
**lignes** | [**BuiltList&lt;LigneRecu&gt;**](LigneRecu.md) | Lignes de cet arrêt, retirées comprises. | 
**montantArticlesUnites** | **int** | Articles bruts, AVANT retenue. | 
**motifRetenueCle** | **String** | Clé i18n du motif de retenue, `null` s'il n'y en a pas. | [optional] 
**netVerseUnites** | **int** | Ce que le coursier a effectivement versé — `articles − retenue`. | 
**prestataireId** | **String** | Prestataire chez qui la collecte a eu lieu. | 
**retenueLivraisonOfferteUnites** | **int** | Retenue au titre de la livraison offerte. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


