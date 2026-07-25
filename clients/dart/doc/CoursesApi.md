# mefali_api_client.api.CoursesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**arretArrive**](CoursesApi.md#arretarrive) | **POST** /courses/{livraison_id}/arrets/{arret_id}/arrive | CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.
[**arretEnRoute**](CoursesApi.md#arretenroute) | **POST** /courses/{livraison_id}/arrets/{arret_id}/en-route | CMD-04 — le coursier déclare partir vers un arrêt.
[**arretIndisponible**](CoursesApi.md#arretindisponible) | **POST** /courses/{livraison_id}/arrets/{arret_id}/indisponible | CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).


# **arretArrive**
> EtatArretCourse arretArrive(livraisonId, arretId, actionArret)

CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.

`arrive_le` est posé par le serveur : c'est la borne de départ de l'attente facturable (prime TRF-06). C'est pour cela que `en_route → collecte` n'existe pas — on ne saute pas une déclaration qui vaut de l'argent.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course, déjà EN ROUTE.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretArrive(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretArrive: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course, déjà EN ROUTE. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **arretEnRoute**
> EtatArretCourse arretEnRoute(livraisonId, arretId, actionArret)

CMD-04 — le coursier déclare partir vers un arrêt.

Le PREMIER départ d'une course la fait passer EN_COLLECTE (data-model §3.2).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretEnRoute(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretEnRoute: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **arretIndisponible**
> EtatArretCourse arretIndisponible(livraisonId, arretId, actionArret)

CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).

Vendeur fermé, ou plus une seule ligne à collecter. L'arrêt est compté **résolu** (la course continue), son montant avancé retombe à zéro, et ses lignes sont retirées de la commande — les frais de livraison, eux, ne bougent pas (FR-050).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretIndisponible(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretIndisponible: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

