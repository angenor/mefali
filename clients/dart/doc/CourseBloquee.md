# mefali_api_client.model.CourseBloquee

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande concernée. | 
**coursierId** | **String** | Coursier assigné. | [optional] 
**livraisonId** | **String** | Livraison concernée. | 
**motif** | **String** | Critère constaté : `sans_mouvement` | `sans_scan`. | 
**nbArretsCollectes** | **int** | Arrêts déjà collectés. **`> 0` ⇒ aucune reprise automatique possible.** | 
**repriseAutomatiquePossible** | **bool** | Faux quand un arrêt est collecté : seule une décision humaine motivée peut alors trancher, parce que le coursier a engagé ses fonds propres. | 
**stagnationS** | **int** | Durée de stagnation constatée (secondes). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


