# mefali_api_client.model.DemandeEchec

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt concerné — absent = à la remise. | [optional] 
**motifCle** | **String** | Clé i18n du motif — jamais du texte libre. | 
**typeIssue** | **String** | Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…). | 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : un échec déclaré sans réseau se rejoue jusqu'à acquittement, et sans elle l'arbre §7.5 se déroulait deux fois — deux sanctions, deux indemnisations, deux litiges (R4). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


