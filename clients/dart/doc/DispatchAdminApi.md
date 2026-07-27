# mefali_api_client.api.DispatchAdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**alertesDispatch**](DispatchAdminApi.md#alertesdispatch) | **GET** /admin/dispatch/alertes | &#x60;GET /admin/dispatch/alertes&#x60; — ce qui demande un humain.
[**poolDispatch**](DispatchAdminApi.md#pooldispatch) | **GET** /admin/dispatch/pool | &#x60;GET /admin/dispatch/pool&#x60; — les coursiers en ligne d&#39;une zone.
[**reprendreCourseAdmin**](DispatchAdminApi.md#reprendrecourseadmin) | **POST** /admin/dispatch/courses/{livraison_id}/reprendre | &#x60;POST /admin/dispatch/courses/{livraison_id}/reprendre&#x60; — la seule voie de reprise d&#39;une course dont un arrêt est **déjà collecté**.


# **alertesDispatch**
> AlertesDispatch alertesDispatch()

`GET /admin/dispatch/alertes` — ce qui demande un humain.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchAdminApi();

try {
    final response = api.alertesDispatch();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchAdminApi->alertesDispatch: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**AlertesDispatch**](AlertesDispatch.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **poolDispatch**
> PoolDeZone poolDispatch(zoneId)

`GET /admin/dispatch/pool` — les coursiers en ligne d'une zone.

Matière de la « carte des coursiers » d'ADM-02. Le rôle `Admin` est la garde : c'est le seul endroit du cycle où une position sort du serveur.  **Une zone, rien d'autre** (contrat §2.2). L'exploitation demande « qui est en ligne », pas « qui est près d'ici » : elle n'a aucun centre à proposer, et l'approcher par un rayon très large écarterait en silence le coursier qui le dépasse. Le port [`dispatch::PoolCoursiers::membres`] répond exactement à cette question — l'index GEO de Redis est un zset, qui sait s'énumérer.  Les **fantômes** de l'index (membre survivant à son état, research R2) sont omis : la carte ne montre que ce dont on connaît la position et l'âge.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchAdminApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone dont on lit le pool.

try {
    final response = api.poolDispatch(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchAdminApi->poolDispatch: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Zone dont on lit le pool. | 

### Return type

[**PoolDeZone**](PoolDeZone.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reprendreCourseAdmin**
> RepriseFaite reprendreCourseAdmin(livraisonId, demandeReprise)

`POST /admin/dispatch/courses/{livraison_id}/reprendre` — la seule voie de reprise d'une course dont un arrêt est **déjà collecté**.

L'automatisme s'y refuse par construction (FR-075), parce que le coursier a engagé ses fonds propres. Cet endpoint n'annule aucune dette et n'écrit aucune caisse : il émet `dispatch.reassignation` avec `acteur: admin` et laisse la caisse (CRS-06) et le litige (AVI-04) à leurs cycles.  `422` si aucun arrêt n'est collecté — dans ce cas l'automatisme suffit, et une action manuelle masquerait un défaut de pipeline.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchAdminApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course à reprendre.
final DemandeReprise demandeReprise = ; // DemandeReprise | 

try {
    final response = api.reprendreCourseAdmin(livraisonId, demandeReprise);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchAdminApi->reprendreCourseAdmin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course à reprendre. | 
 **demandeReprise** | [**DemandeReprise**](DemandeReprise.md)|  | 

### Return type

[**RepriseFaite**](RepriseFaite.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

