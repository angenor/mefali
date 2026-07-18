# mefali_api_client.model.ArticleVendeur

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categorieInterne** | **String** | Étiquette libre de regroupement. | [optional] 
**devise** | **String** | Code ISO 4217 (posé par le serveur — R13). | 
**disponible** | **bool** | Faux = rupture. | 
**id** | **String** | Identifiant. | 
**nom** | **String** | Nom. | 
**photoUrl** | **String** | URL présignée de la photo (TTL 10 min). | [optional] 
**prixBarreUnites** | **int** | Prix barré (strictement supérieur — FR-023). | [optional] 
**prixUnites** | **int** | Prix courant, entier en unités mineures. | 
**retire** | **bool** | Retiré du catalogue — remise possible sans ressaisie (FR-055). | 
**ruptureAdmin** | **bool** | Rupture posée par l'Admin — la bascule vendeur sera refusée (FR-041). | 
**sourceDerniereBascule** | [**SourceBascule**](SourceBascule.md) | Source de la dernière bascule (FR-037). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


