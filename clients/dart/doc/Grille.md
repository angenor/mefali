# mefali_api_client.model.Grille

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**effetLe** | [**DateTime**](DateTime.md) | Entrée en vigueur (posée à la publication). | [optional] 
**etat** | **String** | `brouillon` | `en_vigueur` | `historique`. | 
**id** | **String** | Identifiant. | 
**regles** | [**BuiltList&lt;Regle&gt;**](Regle.md) | Règles, triées par identifiant (ordre stable). | 
**simulee** | **bool** | **Publiable** : la simulation porte sur le contenu EXACT du brouillon. Repasse à `false` dès qu'une règle est éditée (FR-021). | 
**simuleeLe** | [**DateTime**](DateTime.md) | Dernière simulation réussie. | [optional] 
**version** | **int** | Version. | 
**zoneId** | **String** | Zone tarifée. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


