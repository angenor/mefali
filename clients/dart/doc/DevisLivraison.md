# mefali_api_client.model.DevisLivraison

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**composantes** | [**ComposantesDevis**](ComposantesDevis.md) | Détail des composantes. | 
**degraded** | **bool** | Vrai si la distance vient du repli vol d'oiseau (constitution IV). | 
**devise** | **String** | Devise ISO 4217. | 
**distanceM** | **int** | Distance routière totale (m). | 
**etaS** | **int** | Durée estimée (s). | 
**margeUnites** | **int** | Marge Mefali. | 
**ordreArrets** | **BuiltList&lt;int&gt;** | Ordre de passage retenu pour les retraits. | 
**partCoursierUnites** | **int** | Part reversée au coursier. | 
**prixClientUnites** | **int** | Prix payé par le client (unités mineures). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


