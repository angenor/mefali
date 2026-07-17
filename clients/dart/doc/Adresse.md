# mefali_api_client.model.Adresse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**aRepereVocal** | **bool** | `false` après purge (12 mois sans utilisation — FR-022). | 
**creeLe** | [**DateTime**](DateTime.md) | Enregistrement. | 
**derniereUtilisationLe** | [**DateTime**](DateTime.md) | Base de la purge. | 
**id** | **String** | Identifiant = `Idempotency-Key` du POST créateur (R14). | 
**lat** | **double** | Latitude du pin GPS. | 
**libelle** | **String** | « Maison », « Bureau » ou libre. | 
**lng** | **double** | Longitude du pin GPS. | 
**repereTexte** | **String** | Repère écrit. | [optional] 
**repereVocalDureeS** | **int** | Durée du repère vocal. | [optional] 
**zoneId** | **String** | Zone de l'adresse. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


