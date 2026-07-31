# mefali_api_client.model.ReleveDePresence

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**distanceM** | **int** | Éloignement du point de livraison, en mètres **arrondis**.  ⚠ Une distance, **jamais une position** : le serveur ne stocke aucune coordonnée, donc n'en fuite aucune (R8, patron ARTCI du cycle 006). | 
**releveLeLocal** | [**DateTime**](DateTime.md) | Horodatage de l'échantillon sur l'appareil. | 
**uuidClient** | **String** | Clé d'idempotence du relevé (UUIDv7 client, constitution V). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


