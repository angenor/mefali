# mefali_api_client.api.ZonesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**config**](ZonesApi.md#config) | **GET** /config | Configuration produit publique d&#39;une zone (ZON-04). PUBLIC en lecture seule (clarification Q1), liste blanche de namespaces (R4), versionnée par ETag (304 sur If-None-Match — polling horaire économe).
[**forcerCategorie**](ZonesApi.md#forcercategorie) | **PUT** /admin/zones/{zone_id}/categories/{categorie_slug}/forcage | Force l&#39;état d&#39;une catégorie dans une ville (ZON-02). Journalisé via outbox (categorie.forcage_change + categorie.activation_changee si bascule) dans la même transaction.


# **config**
> ConfigZone config(zone)

Configuration produit publique d'une zone (ZON-04). PUBLIC en lecture seule (clarification Q1), liste blanche de namespaces (R4), versionnée par ETag (304 sur If-None-Match — polling horaire économe).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getZonesApi();
final String zone = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone dont on veut la configuration effective.

try {
    final response = api.config(zone);
    print(response);
} on DioException catch (e) {
    print('Exception when calling ZonesApi->config: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zone** | **String**| Zone dont on veut la configuration effective. | 

### Return type

[**ConfigZone**](ConfigZone.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **forcerCategorie**
> EtatCategorie forcerCategorie(zoneId, categorieSlug, corpsForcage)

Force l'état d'une catégorie dans une ville (ZON-02). Journalisé via outbox (categorie.forcage_change + categorie.activation_changee si bascule) dans la même transaction.

### Example
```dart
import 'package:mefali_api_client/api.dart';

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

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

