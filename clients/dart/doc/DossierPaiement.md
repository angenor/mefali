# mefali_api_client.model.DossierPaiement

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt concerné (retenue écrêtée). | [optional] 
**closLe** | [**DateTime**](DateTime.md) | Clôture. | [optional] 
**closMotifCle** | **String** | Motif de clôture — clé i18n également. | [optional] 
**commandeId** | **String** | Commande concernée. | [optional] 
**devise** | **String** | Devise ISO 4217. | [optional] 
**etat** | **String** | `ouvert` | `clos`. | 
**id** | **String** | Dossier. | 
**montantAttendu** | **int** | Montant attendu. | [optional] 
**montantConstate** | **int** | Montant constaté. | [optional] 
**motifCle** | **String** | Motif — **clé i18n**, jamais un texte libre. | 
**ouvertLe** | [**DateTime**](DateTime.md) | Ouverture. | 
**transactionId** | **String** | Transaction concernée. | [optional] 
**type** | **String** | Famille d'anomalie. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


