# mefali_api_client.model.CoursierDuPool

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ageS** | **int** | Âge de la dernière publication (secondes) — l'exploitation doit savoir si elle regarde une position fraîche ou un point figé. | 
**capacites** | **BuiltList&lt;String&gt;** | Capacités déclarées (slugs). | 
**courseActive** | **String** | Course en cours, s'il y en a une. | [optional] 
**coursierId** | **String** | Compte du coursier. | 
**devise** | **String** | Devise ISO 4217. | 
**lat** | **double** | Dernière latitude publiée. | 
**lon** | **double** | Dernière longitude publiée. | 
**plafondUnites** | **int** | Plafond d'avance RETENU du jour — `min(palier de la grille, déclaré)`. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


