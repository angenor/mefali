# mefali_api_client.model.AppelJournalise

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**id** | **String** | Appel. | 
**issue** | **String** | Issue DÉCLARÉE par le coursier — affichée, jamais un critère (R19). | 
**motif** | **String** | `suivi` | `substitution` | `client_absent`. | 
**passeLe** | [**DateTime**](DateTime.md) | Horodatage **serveur** — celui qui fonde l'espacement. | 
**passeLeLocal** | [**DateTime**](DateTime.md) | Horodatage de l'appareil — observation seulement. | 
**prestataireId** | **String** | Prestataire appelé (si `vers = vendeur`). | [optional] 
**vers** | **String** | `client` | `vendeur`. **Aucun numéro** — le serveur n'en a jamais vu. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


