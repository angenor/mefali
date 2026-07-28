# mefali_api_client.api.CoursierApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**courseActive**](CoursierApi.md#courseactive) | **GET** /courses/active | CRS-03 — course active du coursier, **complète** et pré-provisionnée.
[**signalerRupture**](CoursierApi.md#signalerrupture) | **POST** /coursier/signalements-rupture | Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).


# **courseActive**
> CourseActiveComplete courseActive()

CRS-03 — course active du coursier, **complète** et pré-provisionnée.

Cet endpoint a déménagé de `qr_http` : son contenu n'a plus rien à faire dans un domaine dont l'objet est la plaque. Le chemin ne bouge pas, et les champs du cycle 006 restent là — l'app livrée continue de fonctionner pendant la transition.  `204` sans course : ce n'est pas une erreur, c'est une journée qui commence.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();

try {
    final response = api.courseActive();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->courseActive: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CourseActiveComplete**](CourseActiveComplete.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **signalerRupture**
> SignalementRecuDto signalerRupture(idempotencyKey, signalerRuptureDto)

Signale un article introuvable — REFUSÉ (et compté nulle part) sans commande active comportant un arrêt chez ce prestataire (FR-038).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUID généré CÔTÉ CLIENT — devient l'identifiant du signalement, rejeu réseau idempotent (FR-039).
final SignalerRuptureDto signalerRuptureDto = ; // SignalerRuptureDto | 

try {
    final response = api.signalerRupture(idempotencyKey, signalerRuptureDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->signalerRupture: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUID généré CÔTÉ CLIENT — devient l'identifiant du signalement, rejeu réseau idempotent (FR-039). | 
 **signalerRuptureDto** | [**SignalerRuptureDto**](SignalerRuptureDto.md)|  | 

### Return type

[**SignalementRecuDto**](SignalementRecuDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

