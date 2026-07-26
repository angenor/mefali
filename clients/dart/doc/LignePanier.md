# mefali_api_client.model.LignePanier

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**articleId** | **String** | Article demandé. | 
**preference** | **String** | Que faire si l'article manque : `remplacer` | `appeler` | `retirer`. Absent = `appeler`, le défaut produit (CMD-01). | [optional] 
**prestataireId** | **String** | Vendeur chez qui l'article est pris. | 
**quantite** | **int** | Quantité (> 0). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


