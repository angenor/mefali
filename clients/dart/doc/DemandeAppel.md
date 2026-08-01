# mefali_api_client.model.DemandeAppel

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**issue** | **String** | Issue DÉCLARÉE : `inconnue` | `sans_reponse` | `repondu`. Facultative — le serveur ne voit pas l'appel, il ne peut que la recevoir (R19). | [optional] 
**motif** | **String** | `suivi` | `substitution` | `client_absent`. **Seul `client_absent` compte** pour la preuve d'échec (FR-035). | 
**passeLeLocal** | [**DateTime**](DateTime.md) | Horodatage de l'appareil — observation seulement. | 
**prestataireId** | **String** | Prestataire appelé — obligatoire si `vers = vendeur`. | [optional] 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 client, constitution V). | 
**vers** | **String** | `client` | `vendeur`. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


