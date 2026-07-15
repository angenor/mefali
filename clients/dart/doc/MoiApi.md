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
[**monDossierCoursier**](MoiApi.md#mondossiercoursier) | **GET** /moi/dossier-coursier | État du dossier coursier du compte courant (FR-013 : l&#39;app Pro l&#39;affiche).
[**revoquerSession**](MoiApi.md#revoquersession) | **DELETE** /moi/sessions/{session_id} | Déconnexion à distance d&#39;un appareil (SC-004).
[**soumettreDossierCoursier**](MoiApi.md#soumettredossiercoursier) | **POST** /moi/dossier-coursier | Soumet (ou re-soumet après refus) le dossier coursier — crée la demande de rôle (FR-015).


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

# **monDossierCoursier**
> DossierCoursier monDossierCoursier()

État du dossier coursier du compte courant (FR-013 : l'app Pro l'affiche).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();

try {
    final response = api.monDossierCoursier();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->monDossierCoursier: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**DossierCoursier**](DossierCoursier.md)

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

# **soumettreDossierCoursier**
> DossierCoursier soumettreDossierCoursier(idempotencyKey, piece, referentNom, referentTelephone, vehicules)

Soumet (ou re-soumet après refus) le dossier coursier — crée la demande de rôle (FR-015).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUIDv7 généré par le client — rejeu réseau idempotent (R14).
final MultipartFile piece = BINARY_DATA_HERE; // MultipartFile | Pièce d'identité — ≤ 10 Mo, jpeg/png/webp/pdf.
final String referentNom = referentNom_example; // String | Nom du référent local.
final String referentTelephone = referentTelephone_example; // String | Téléphone du référent — normalisé E.164 comme celui du compte.
final BuiltList<String> vehicules = ; // BuiltList<String> | Slugs des types de transport, ACTIFS dans la zone (référentiel ZON-03).

try {
    final response = api.soumettreDossierCoursier(idempotencyKey, piece, referentNom, referentTelephone, vehicules);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->soumettreDossierCoursier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUIDv7 généré par le client — rejeu réseau idempotent (R14). | 
 **piece** | **MultipartFile**| Pièce d'identité — ≤ 10 Mo, jpeg/png/webp/pdf. | 
 **referentNom** | **String**| Nom du référent local. | 
 **referentTelephone** | **String**| Téléphone du référent — normalisé E.164 comme celui du compte. | 
 **vehicules** | [**BuiltList&lt;String&gt;**](String.md)| Slugs des types de transport, ACTIFS dans la zone (référentiel ZON-03). | 

### Return type

[**DossierCoursier**](DossierCoursier.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

