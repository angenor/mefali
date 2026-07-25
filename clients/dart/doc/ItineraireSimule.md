# mefali_api_client.model.ItineraireSimule

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**degraded** | **bool** | Vrai si la distance vient du repli vol d'oiseau × facteur de zone. | 
**distanceM** | **int** | Distance routière totale (mètres). | 
**etaS** | **int** | Durée estimée (secondes). | 
**exhaustif** | **bool** | Vrai si l'ordre est le meilleur de TOUTES les permutations (≤ 4 arrêts) ; faux si l'heuristique bornée a tranché (FR-031). | 
**ordre** | **BuiltList&lt;int&gt;** | Indices des vendeurs dans l'ordre de passage. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


