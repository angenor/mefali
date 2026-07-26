# mefali_api_client.model.IssueRupture

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ecartPourcent** | **int** | Écart de prix en pourcent (signé). | [optional] 
**issue** | **String** | `ligne_retiree` | `proposition_ouverte`. | 
**montantArticlesUnites** | **int** | Montant des articles après révision. | [optional] 
**montantRetire** | **int** | Montant sorti du total (`null` si une proposition a été ouverte). | [optional] 
**resteS** | **int** | Secondes dont dispose le client pour décider. | [optional] 
**substitutionId** | **String** | Proposition créée (`null` si l'article a été retiré). | [optional] 
**totalUnites** | **int** | Total après révision — **le devis de livraison n'a pas bougé** (FR-050). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


