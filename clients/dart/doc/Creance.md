# mefali_api_client.model.Creance

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande d'origine. | 
**creeLe** | [**DateTime**](DateTime.md) | Naissance — automatique, à la livraison (FR-063). | 
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | `due` | `reglee`. | 
**id** | **String** | Identifiant. | 
**montantUnites** | **int** | Montant dû (unités mineures). | 
**nature** | **String** | `avance_prepayee` | `part_course`. | 
**regleLe** | [**DateTime**](DateTime.md) | Instant du règlement, `null` tant qu'elle est due. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


