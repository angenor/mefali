# mefali_api_client.model.Commande

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | État de très haut niveau. | 
**id** | **String** | Identifiant (= `Idempotency-Key`). | 
**livraison** | [**LivraisonCommande**](LivraisonCommande.md) | Livraison. | 
**montantArticlesUnites** | **int** | Montant des articles. | 
**paiement** | [**PaiementCommande**](PaiementCommande.md) | Paiement. | 
**remise** | [**SecretsRemise**](SecretsRemise.md) | Code et jeton de remise. | 
**totalUnites** | **int** | Total à payer. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


