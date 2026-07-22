# mefali_api_client.model.ModifierArticleDto

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categorieInterne** | **String** | Nouvelle étiquette — `null` l'efface. | [optional] 
**nom** | **String** | Nouveau nom. | [optional] 
**prixBarreUnites** | **int** | Nouveau prix barré — `null` retire la promotion EXPLICITEMENT (jamais en silence : un prix barré devenu ≤ prix fait échouer l'opération). | [optional] 
**prixUnites** | **int** | Nouveau prix courant. | [optional] 
**retirerPrixBarre** | **bool** | Retire la promotion — équivalent de `prix_barre_unites: null` pour les clients générés qui ne savent pas sérialiser un `null` EXPLICITE (built_value omet les champs nuls). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


