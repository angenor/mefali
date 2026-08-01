# mefali_api_client.model.PreuveAppels

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**espacementOk** | **bool** | Faux dès qu'un appel a été écarté pour cause d'espacement. | 
**faits** | **int** | Appels `client_absent` **retenus** (espacement respecté). | 
**horodatages** | [**BuiltList&lt;DateTime&gt;**](DateTime.md) | Horodatages **serveur** des appels retenus (affichage K4-1e). | 
**issues** | **BuiltList&lt;String&gt;** | Issues DÉCLARÉES par le coursier — affichées, jamais un critère (R19). | 
**motifCle** | **String** | Pourquoi elle ne l'est pas — clé i18n. | [optional] 
**ok** | **bool** | Preuve réunie. | 
**requis** | **int** | Appels exigés par la zone. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


