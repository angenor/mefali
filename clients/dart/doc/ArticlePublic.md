# mefali_api_client.model.ArticlePublic

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categorieInterne** | **String** | Étiquette libre de regroupement. | [optional] 
**devise** | **String** | Code ISO 4217 de la zone. | 
**disponible** | **bool** | Faux = rupture (servi seulement si le mode de la catégorie est `grise`). | 
**id** | **String** | Identifiant. | 
**nom** | **String** | Nom. | 
**photoUrl** | **String** | URL présignée de la photo (TTL 10 min). | [optional] 
**prixBarreUnites** | **int** | Prix barré (présent ⇒ promotion, strictement supérieur — FR-023). | [optional] 
**prixUnites** | **int** | Prix courant — ENTIER en unités mineures (constitution III). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


