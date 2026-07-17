# mefali_api_client.model.DossierCoursier

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**motif** | **String** | Motif de la dernière décision admin. | [optional] 
**referentNom** | **String** | Référent local (« caution morale », cadrage §7.1). | 
**referentTelephoneE164** | **String** | Téléphone du référent, normalisé E.164. | 
**soumisLe** | [**DateTime**](DateTime.md) | Dernier dépôt. | 
**statut** | **String** | Statut = celui de l'attribution `coursier` (R9). | 
**vehicules** | [**BuiltList&lt;VehiculeDeclare&gt;**](VehiculeDeclare.md) | Véhicules déclarés. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


