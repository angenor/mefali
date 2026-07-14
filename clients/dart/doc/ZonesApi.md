# mefali_api_client.api.ZonesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**forcerCategorie**](ZonesApi.md#forcercategorie) | **PUT** /admin/zones/{zone_id}/categories/{categorie_slug}/forcage | Force l&#39;état d&#39;une catégorie dans une ville (ZON-02). Journalisé via outbox (categorie.forcage_change + categorie.activation_changee si bascule) dans la même transaction.


# **forcerCategorie**
> EtatCategorie forcerCategorie(zoneId, categorieSlug, corpsForcage)

Force l'état d'une catégorie dans une ville (ZON-02). Journalisé via outbox (categorie.forcage_change + categorie.activation_changee si bascule) dans la même transaction.

### Example
```dart
import 'package:mefali_api_client/api.dart';
// TODO Configure API key authorization: adminToken
//defaultApiClient.getAuthentication<ApiKeyAuth>('adminToken').apiKey = 'YOUR_API_KEY';
// uncomment below to setup prefix (e.g. Bearer) for API key, if needed
//defaultApiClient.getAuthentication<ApiKeyAuth>('adminToken').apiKeyPrefix = 'Bearer';

final api = MefaliApiClient().getZonesApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Ville dont on force la catégorie.
final String categorieSlug = categorieSlug_example; // String | Slug de la catégorie.
final CorpsForcage corpsForcage = ; // CorpsForcage | 

try {
    final response = api.forcerCategorie(zoneId, categorieSlug, corpsForcage);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ZonesApi->forcerCategorie: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Ville dont on force la catégorie. | 
 **categorieSlug** | **String**| Slug de la catégorie. | 
 **corpsForcage** | [**CorpsForcage**](CorpsForcage.md)|  | 

### Return type

[**EtatCategorie**](EtatCategorie.md)

### Authorization

[adminToken](../README.md#adminToken)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

