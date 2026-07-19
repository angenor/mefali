# mefali_api_client.api.VendeurApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**actionBoutique**](VendeurApi.md#actionboutique) | **POST** /vendeur/prestataires/{id}/boutique/action | Geste V1 : ouvrir, fermer, pause, prolonger, fermer pour la journée.
[**basculerDisponibilite**](VendeurApi.md#basculerdisponibilite) | **POST** /vendeur/prestataires/{id}/articles/{article_id}/disponibilite | Bascule la disponibilité en UN geste (source vendeur — FR-037).
[**creerArticle**](VendeurApi.md#creerarticle) | **POST** /vendeur/prestataires/{id}/articles | Ajoute un article au catalogue (V2 — « + Ajouter un article »).
[**maBoutique**](VendeurApi.md#maboutique) | **GET** /vendeur/prestataires/{id}/boutique | Statut, échéance, horaires du jour et rappel de l&#39;écran V1.
[**mesArticles**](VendeurApi.md#mesarticles) | **GET** /vendeur/prestataires/{id}/articles | Catalogue COMPLET du prestataire piloté (ruptures, retirés, verrou admin).
[**mesPrestataires**](VendeurApi.md#mesprestataires) | **GET** /vendeur/prestataires | Prestataires que ce compte pilote (rattachements du cycle VND).
[**modifierArticle**](VendeurApi.md#modifierarticle) | **PUT** /vendeur/prestataires/{id}/articles/{article_id} | Modifie nom / prix / prix barré / étiquette (fiche article V2).
[**modifierHoraires**](VendeurApi.md#modifierhoraires) | **PUT** /vendeur/prestataires/{id}/horaires | Remplace les horaires hebdomadaires (FR-034) — effet IMMÉDIAT.
[**photoArticle**](VendeurApi.md#photoarticle) | **POST** /vendeur/prestataires/{id}/articles/{article_id}/photo | Dépose/remplace la photo de l&#39;article (multipart, ≤ 5 Mo).
[**remettreArticle**](VendeurApi.md#remettrearticle) | **POST** /vendeur/prestataires/{id}/articles/{article_id}/remise | Remet un article retiré au catalogue, sans ressaisie (FR-055).
[**retirerArticle**](VendeurApi.md#retirerarticle) | **POST** /vendeur/prestataires/{id}/articles/{article_id}/retrait | Retire l&#39;article du catalogue — RÉVERSIBLE (FR-055).


# **actionBoutique**
> BoutiqueVendeur actionBoutique(id, corpsActionBoutique)

Geste V1 : ouvrir, fermer, pause, prolonger, fermer pour la journée.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final CorpsActionBoutique corpsActionBoutique = ; // CorpsActionBoutique | 

try {
    final response = api.actionBoutique(id, corpsActionBoutique);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->actionBoutique: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **corpsActionBoutique** | [**CorpsActionBoutique**](CorpsActionBoutique.md)|  | 

### Return type

[**BoutiqueVendeur**](BoutiqueVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **basculerDisponibilite**
> ArticleVendeur basculerDisponibilite(id, articleId, basculeDisponibiliteDto)

Bascule la disponibilité en UN geste (source vendeur — FR-037).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final String articleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Article.
final BasculeDisponibiliteDto basculeDisponibiliteDto = ; // BasculeDisponibiliteDto | 

try {
    final response = api.basculerDisponibilite(id, articleId, basculeDisponibiliteDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->basculerDisponibilite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **articleId** | **String**| Article. | 
 **basculeDisponibiliteDto** | [**BasculeDisponibiliteDto**](BasculeDisponibiliteDto.md)|  | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **creerArticle**
> ArticleVendeur creerArticle(id, creerArticleDto)

Ajoute un article au catalogue (V2 — « + Ajouter un article »).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final CreerArticleDto creerArticleDto = ; // CreerArticleDto | 

try {
    final response = api.creerArticle(id, creerArticleDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->creerArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **creerArticleDto** | [**CreerArticleDto**](CreerArticleDto.md)|  | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **maBoutique**
> BoutiqueVendeur maBoutique(id)

Statut, échéance, horaires du jour et rappel de l'écran V1.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.

try {
    final response = api.maBoutique(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->maBoutique: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 

### Return type

[**BoutiqueVendeur**](BoutiqueVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mesArticles**
> BuiltList<ArticleVendeur> mesArticles(id)

Catalogue COMPLET du prestataire piloté (ruptures, retirés, verrou admin).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.

try {
    final response = api.mesArticles(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->mesArticles: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 

### Return type

[**BuiltList&lt;ArticleVendeur&gt;**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mesPrestataires**
> BuiltList<PrestatairePilotable> mesPrestataires()

Prestataires que ce compte pilote (rattachements du cycle VND).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();

try {
    final response = api.mesPrestataires();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->mesPrestataires: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;PrestatairePilotable&gt;**](PrestatairePilotable.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **modifierArticle**
> ArticleVendeur modifierArticle(id, articleId, modifierArticleDto)

Modifie nom / prix / prix barré / étiquette (fiche article V2).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final String articleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Article.
final ModifierArticleDto modifierArticleDto = ; // ModifierArticleDto | 

try {
    final response = api.modifierArticle(id, articleId, modifierArticleDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->modifierArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **articleId** | **String**| Article. | 
 **modifierArticleDto** | [**ModifierArticleDto**](ModifierArticleDto.md)|  | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **modifierHoraires**
> BoutiqueVendeur modifierHoraires(id, horairesSemaineDto)

Remplace les horaires hebdomadaires (FR-034) — effet IMMÉDIAT.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final HorairesSemaineDto horairesSemaineDto = ; // HorairesSemaineDto | 

try {
    final response = api.modifierHoraires(id, horairesSemaineDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->modifierHoraires: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **horairesSemaineDto** | [**HorairesSemaineDto**](HorairesSemaineDto.md)|  | 

### Return type

[**BoutiqueVendeur**](BoutiqueVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **photoArticle**
> ArticleVendeur photoArticle(id, articleId, fichier)

Dépose/remplace la photo de l'article (multipart, ≤ 5 Mo).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final String articleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Article.
final MultipartFile fichier = BINARY_DATA_HERE; // MultipartFile | La photo.

try {
    final response = api.photoArticle(id, articleId, fichier);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->photoArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **articleId** | **String**| Article. | 
 **fichier** | **MultipartFile**| La photo. | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remettreArticle**
> ArticleVendeur remettreArticle(id, articleId)

Remet un article retiré au catalogue, sans ressaisie (FR-055).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final String articleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Article.

try {
    final response = api.remettreArticle(id, articleId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->remettreArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **articleId** | **String**| Article. | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **retirerArticle**
> ArticleVendeur retirerArticle(id, articleId)

Retire l'article du catalogue — RÉVERSIBLE (FR-055).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire piloté.
final String articleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Article.

try {
    final response = api.retirerArticle(id, articleId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->retirerArticle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire piloté. | 
 **articleId** | **String**| Article. | 

### Return type

[**ArticleVendeur**](ArticleVendeur.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

