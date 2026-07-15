# mefali_api_client.api.MoiApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**mesSessions**](MoiApi.md#messessions) | **GET** /moi/sessions | Appareils/sessions actifs du compte (FR-008).
[**moi**](MoiApi.md#moi) | **GET** /moi | Compte courant et états de TOUS ses rôles.
[**revoquerSession**](MoiApi.md#revoquersession) | **DELETE** /moi/sessions/{session_id} | Déconnexion à distance d&#39;un appareil (SC-004).


# **mesSessions**
> BuiltList<SessionAppareil> mesSessions()

Appareils/sessions actifs du compte (FR-008).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();

try {
    final response = api.mesSessions();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->mesSessions: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;SessionAppareil&gt;**](SessionAppareil.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **moi**
> CompteMoi moi()

Compte courant et états de TOUS ses rôles.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();

try {
    final response = api.moi();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->moi: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**CompteMoi**](CompteMoi.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **revoquerSession**
> revoquerSession(sessionId)

Déconnexion à distance d'un appareil (SC-004).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String sessionId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Appareil à déconnecter.

try {
    api.revoquerSession(sessionId);
} on DioException catch (e) {
    print('Exception when calling MoiApi->revoquerSession: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **sessionId** | **String**| Appareil à déconnecter. | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

