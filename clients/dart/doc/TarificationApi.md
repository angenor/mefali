# mefali_api_client.api.TarificationApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**creerBrouillon**](TarificationApi.md#creerbrouillon) | **POST** /admin/tarification/zones/{zone_id}/brouillon | Crée (ou rend) le brouillon de la zone — **idempotent**.
[**ecrireRegle**](TarificationApi.md#ecrireregle) | **PUT** /admin/tarification/brouillon/{grille_id}/regles/{regle_id} | Crée ou met à jour une règle du brouillon — **réarme la simulation**.
[**grilleDeZone**](TarificationApi.md#grilledezone) | **GET** /admin/tarification/zones/{zone_id}/grille | Grille en vigueur ET brouillon d&#39;une zone.
[**publier**](TarificationApi.md#publier) | **POST** /admin/tarification/brouillon/{grille_id}/publier | Publie le brouillon — **gardé** par la simulation et les bornes.
[**simuler**](TarificationApi.md#simuler) | **POST** /admin/tarification/brouillon/{grille_id}/simuler | Simule une course sur le brouillon — **dry run**, aucun effet de bord.
[**supprimerRegle**](TarificationApi.md#supprimerregle) | **DELETE** /admin/tarification/brouillon/{grille_id}/regles/{regle_id} | Supprime une règle du brouillon — **réarme la simulation**.


# **creerBrouillon**
> Grille creerBrouillon(zoneId)

Crée (ou rend) le brouillon de la zone — **idempotent**.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone tarifée.

try {
    final response = api.creerBrouillon(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->creerBrouillon: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Zone tarifée. | 

### Return type

[**Grille**](Grille.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ecrireRegle**
> Regle ecrireRegle(grilleId, regleId, regleUpsert)

Crée ou met à jour une règle du brouillon — **réarme la simulation**.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String grilleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Brouillon.
final String regleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Règle (identifiant choisi par l'appelant).
final RegleUpsert regleUpsert = ; // RegleUpsert | 

try {
    final response = api.ecrireRegle(grilleId, regleId, regleUpsert);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->ecrireRegle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grilleId** | **String**| Brouillon. | 
 **regleId** | **String**| Règle (identifiant choisi par l'appelant). | 
 **regleUpsert** | [**RegleUpsert**](RegleUpsert.md)|  | 

### Return type

[**Regle**](Regle.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **grilleDeZone**
> GrillesZone grilleDeZone(zoneId)

Grille en vigueur ET brouillon d'une zone.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone tarifée.

try {
    final response = api.grilleDeZone(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->grilleDeZone: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Zone tarifée. | 

### Return type

[**GrillesZone**](GrillesZone.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publier**
> Grille publier(grilleId)

Publie le brouillon — **gardé** par la simulation et les bornes.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String grilleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Brouillon à publier.

try {
    final response = api.publier(grilleId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->publier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grilleId** | **String**| Brouillon à publier. | 

### Return type

[**Grille**](Grille.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **simuler**
> ResultatSimulation simuler(grilleId, demandeSimulation)

Simule une course sur le brouillon — **dry run**, aucun effet de bord.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String grilleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Brouillon à rejouer.
final DemandeSimulation demandeSimulation = ; // DemandeSimulation | 

try {
    final response = api.simuler(grilleId, demandeSimulation);
    print(response);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->simuler: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grilleId** | **String**| Brouillon à rejouer. | 
 **demandeSimulation** | [**DemandeSimulation**](DemandeSimulation.md)|  | 

### Return type

[**ResultatSimulation**](ResultatSimulation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **supprimerRegle**
> supprimerRegle(grilleId, regleId)

Supprime une règle du brouillon — **réarme la simulation**.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getTarificationApi();
final String grilleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Brouillon.
final String regleId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Règle à supprimer.

try {
    api.supprimerRegle(grilleId, regleId);
} on DioException catch (e) {
    print('Exception when calling TarificationApi->supprimerRegle: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **grilleId** | **String**| Brouillon. | 
 **regleId** | **String**| Règle à supprimer. | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

