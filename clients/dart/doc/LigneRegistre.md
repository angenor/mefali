# mefali_api_client.model.LigneRegistre

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande rapprochée — le rapprochement se lit sans jointure manuelle. | 
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | État de la transaction. | 
**fournisseur** | **String** | Fournisseur qui a encaissé. | 
**id** | **String** | Transaction. | 
**issueLe** | [**DateTime**](DateTime.md) | Issue définitive. | [optional] 
**montantUnites** | **int** | Montant figé. | 
**moyen** | **String** | Moyen employé — `inconnu` tant que le fournisseur ne l'a pas dit. | 
**orpheline** | **bool** | De l'argent encaissé qu'aucune commande vivante n'attend (FR-082). | 
**ouverteLe** | [**DateTime**](DateTime.md) | Ouverture. | 
**referenceFournisseur** | **String** | Référence côté fournisseur — le rapprochement dans l'AUTRE sens. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


