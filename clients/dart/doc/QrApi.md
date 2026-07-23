# mefali_api_client.api.QrApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**collecter**](QrApi.md#collecter) | **POST** /courses/arrets/{arret_id}/collecte | QRC-02/03/04 — collecte un arrêt (multipart : &#x60;demande&#x60; JSON + &#x60;photo&#x60;).
[**courseActive**](QrApi.md#courseactive) | **GET** /courses/active | QRC-02 — course active du coursier + pré-provisionnement hors-ligne.
[**telechargerPlaque**](QrApi.md#telechargerplaque) | **GET** /admin/prestataires/{id}/plaque | QRC-01 — télécharge (génère au besoin) le PDF de plaque d&#39;un prestataire.


# **collecter**
> ResultatCollecte collecter(arretId, demandeCollecte)

QRC-02/03/04 — collecte un arrêt (multipart : `demande` JSON + `photo`).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getQrApi();
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt à collecter de la course active.
final DemandeCollecte demandeCollecte = ; // DemandeCollecte | Partie `demande` d'un multipart, avec `photo` facultative.

try {
    final response = api.collecter(arretId, demandeCollecte);
    print(response);
} on DioException catch (e) {
    print('Exception when calling QrApi->collecter: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **arretId** | **String**| Arrêt à collecter de la course active. | 
 **demandeCollecte** | [**DemandeCollecte**](DemandeCollecte.md)| Partie `demande` d'un multipart, avec `photo` facultative. | 

### Return type

[**ResultatCollecte**](ResultatCollecte.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **courseActive**
> CourseActive courseActive()

QRC-02 — course active du coursier + pré-provisionnement hors-ligne.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getQrApi();

try {
    final response = api.courseActive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling QrApi->courseActive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CourseActive**](CourseActive.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **telechargerPlaque**
> PlaqueUrl telechargerPlaque(id)

QRC-01 — télécharge (génère au besoin) le PDF de plaque d'un prestataire.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getQrApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire agréé porteur d'une identité de plaque.

try {
    final response = api.telechargerPlaque(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling QrApi->telechargerPlaque: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire agréé porteur d'une identité de plaque. | 

### Return type

[**PlaqueUrl**](PlaqueUrl.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

