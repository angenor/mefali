# mefali_api_client.model.DemandeCollecte

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**code** | **String** | Code à 4 chiffres saisi (mode `code_secours`). | [optional] 
**horodatageLocal** | [**DateTime**](DateTime.md) | Horodatage local de l'action. | 
**jeton** | **String** | Jeton lu dans le QR (mode `scan_qr`). | [optional] 
**mode** | [**ModeCollecte**](ModeCollecte.md) | Scan du QR ou saisie du code de secours. | 
**positionLat** | **double** | Position capturée du coursier. | 
**positionLon** | **double** | Position capturée du coursier. | 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 client, V). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


