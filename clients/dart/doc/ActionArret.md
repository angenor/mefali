# mefali_api_client.model.ActionArret

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**horodatageLocal** | [**DateTime**](DateTime.md) | Horodatage de l'appareil. **Observation seulement** : le serveur écrit le sien, parce que `arrive_le` fonde une prime (TRF-06). | 
**motif** | **String** | Pour `indisponible` : `vendeur_ferme` (défaut) ou `toutes_lignes_retirees`. Ignoré par les autres actions. | [optional] 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 produit par l'app, constitution V). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


