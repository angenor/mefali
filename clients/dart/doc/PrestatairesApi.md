# mefali_api_client.api.PrestatairesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**consulterPrestataire**](PrestatairesApi.md#consulterprestataire) | **GET** /prestataires/{id} | Fiche + catalogue, lecture seule, SANS authentification — la plaque est un canal d&#39;acquisition (FR-027 ; exception VIII documentée au plan, R9).
[**resoudrePlaque**](PrestatairesApi.md#resoudreplaque) | **GET** /prestataires/plaque/{jeton} | Résout un jeton de plaque — sous SESSION valide, AUCUN rôle particulier (analyse C1 : seule la consultation de la fiche échappe au principe VIII).


# **consulterPrestataire**
> FichePublique consulterPrestataire(id)

Fiche + catalogue, lecture seule, SANS authentification — la plaque est un canal d'acquisition (FR-027 ; exception VIII documentée au plan, R9).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPrestatairesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire consulté.

try {
    final response = api.consulterPrestataire(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrestatairesApi->consulterPrestataire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire consulté. | 

### Return type

[**FichePublique**](FichePublique.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **resoudrePlaque**
> ResolutionPlaque resoudrePlaque(jeton)

Résout un jeton de plaque — sous SESSION valide, AUCUN rôle particulier (analyse C1 : seule la consultation de la fiche échappe au principe VIII).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPrestatairesApi();
final String jeton = jeton_example; // String | Jeton signé porté par la plaque.

try {
    final response = api.resoudrePlaque(jeton);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PrestatairesApi->resoudrePlaque: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **jeton** | **String**| Jeton signé porté par la plaque. | 

### Return type

[**ResolutionPlaque**](ResolutionPlaque.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

