# mefali_api_client.model.DevisPanier

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**devis** | [**DevisLivraison**](DevisLivraison.md) | Devis de livraison. | 
**devise** | **String** | Devise ISO 4217. | 
**groupes** | [**BuiltList&lt;GroupeVendeur&gt;**](GroupeVendeur.md) | Regroupement par vendeur. | 
**montantArticlesUnites** | **int** | Montant des ARTICLES seuls (unités mineures). | 
**paiement** | [**PaiementPanier**](PaiementPanier.md) | Décision d'encaissement. | 
**scission** | [**ScissionProposee**](ScissionProposee.md) | Proposition de scission, ou `null`. | [optional] 
**totalUnites** | **int** | Total à payer = articles + prix client du devis. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


