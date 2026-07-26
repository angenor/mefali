# mefali_api_client.model.DemandeRupture

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**articleProposeId** | **String** | Article proposé — obligatoire pour `remplacer`, **du même vendeur**. | [optional] 
**ligneId** | **String** | Ligne de commande devenue indisponible. | 
**prixProposeUnites** | **int** | Prix unitaire proposé (unités mineures) — obligatoire pour `remplacer`. | [optional] 
**resolution** | **String** | `retirer` | `remplacer`. Absent = suivre la préférence du client, dont le défaut sûr est le retrait : on ne fait jamais payer par défaut. | [optional] 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 client, constitution V). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


