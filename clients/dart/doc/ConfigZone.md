# mefali_api_client.model.ConfigZone

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categories** | [**BuiltList&lt;CategorieDto&gt;**](CategorieDto.md) | Catégories actives dans la zone. | 
**devise** | [**DeviseDto**](DeviseDto.md) | Devise résolue. | 
**drapeaux** | **BuiltMap&lt;String, bool&gt;** | Drapeaux (clés `drapeau.*` sans préfixe). | 
**parametres** | [**JsonObject**](.md) | Paramètres client (clés `client.*` sans préfixe). | 
**textes** | **BuiltMap&lt;String, String&gt;** | Textes (clés `texte.*` sans préfixe) — clés i18n fr. | 
**transportsActifs** | **BuiltList&lt;String&gt;** | Slugs des types de transport actifs. | 
**version** | **String** | Empreinte SHA-256 hex du document canonique (= ETag). | 
**zone** | **String** | Zone servie. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


