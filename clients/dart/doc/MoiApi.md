# mefali_api_client.api.MoiApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**ecouterRepereVocal**](MoiApi.md#ecouterreperevocal) | **GET** /moi/adresses/{adresse_id}/repere-vocal | URL présignée de lecture du repère vocal (FR-020).
[**enregistrerAdresse**](MoiApi.md#enregistreradresse) | **POST** /moi/adresses | Enregistre une adresse — proposition post-livraison acceptée (FR-019).
[**mesAdresses**](MoiApi.md#mesadresses) | **GET** /moi/adresses | Adresses enregistrées du compte courant (FR-021).
[**mesSessions**](MoiApi.md#messessions) | **GET** /moi/sessions | Appareils/sessions actifs du compte (FR-008).
[**modifierAdresse**](MoiApi.md#modifieradresse) | **PATCH** /moi/adresses/{adresse_id} | Renomme l&#39;adresse ou met à jour son repère écrit (FR-021).
[**moi**](MoiApi.md#moi) | **GET** /moi | Compte courant et états de TOUS ses rôles.
[**monDossierCoursier**](MoiApi.md#mondossiercoursier) | **GET** /moi/dossier-coursier | État du dossier coursier du compte courant (FR-013 : l&#39;app Pro l&#39;affiche).
[**remplacerRepereVocal**](MoiApi.md#remplacerreperevocal) | **POST** /moi/adresses/{adresse_id}/repere-vocal | Enregistre un nouveau repère vocal — après purge, ou pour le refaire.
[**revoquerSession**](MoiApi.md#revoquersession) | **DELETE** /moi/sessions/{session_id} | Déconnexion à distance d&#39;un appareil (SC-004).
[**soumettreDossierCoursier**](MoiApi.md#soumettredossiercoursier) | **POST** /moi/dossier-coursier | Soumet (ou re-soumet après refus) le dossier coursier — crée la demande de rôle (FR-015).
[**supprimerAdresse**](MoiApi.md#supprimeradresse) | **DELETE** /moi/adresses/{adresse_id} | Supprime l&#39;adresse — soft (FR-021).


# **ecouterRepereVocal**
> UrlPresignee ecouterRepereVocal(adresseId)

URL présignée de lecture du repère vocal (FR-020).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String adresseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Adresse concernée.

try {
    final response = api.ecouterRepereVocal(adresseId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->ecouterRepereVocal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adresseId** | **String**| Adresse concernée. | 

### Return type

[**UrlPresignee**](UrlPresignee.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enregistrerAdresse**
> Adresse enregistrerAdresse(idempotencyKey, lat, libelle, lng, dureeS, livraisonOrigine, noteVocale, repereTexte)

Enregistre une adresse — proposition post-livraison acceptée (FR-019).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUIDv7 généré par le client — DEVIENT l'id de l'adresse (R14).
final double lat = 1.2; // double | Latitude du pin GPS.
final String libelle = libelle_example; // String | « Maison », « Bureau » ou libre.
final double lng = 1.2; // double | Longitude du pin GPS.
final int dureeS = 56; // int | Durée du repère parlé — bornée par le paramètre de zone `medias.note_vocale_duree_max_s`.
final String livraisonOrigine = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | PROVISION — posée par les cycles CMD/CRS ; aucune logique ne la lit.
final MultipartFile noteVocale = BINARY_DATA_HERE; // MultipartFile | Repère parlé — ≤ 1,5 Mo, m4a/aac.
final String repereTexte = repereTexte_example; // String | Repère écrit.

try {
    final response = api.enregistrerAdresse(idempotencyKey, lat, libelle, lng, dureeS, livraisonOrigine, noteVocale, repereTexte);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->enregistrerAdresse: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUIDv7 généré par le client — DEVIENT l'id de l'adresse (R14). | 
 **lat** | **double**| Latitude du pin GPS. | 
 **libelle** | **String**| « Maison », « Bureau » ou libre. | 
 **lng** | **double**| Longitude du pin GPS. | 
 **dureeS** | **int**| Durée du repère parlé — bornée par le paramètre de zone `medias.note_vocale_duree_max_s`. | [optional] 
 **livraisonOrigine** | **String**| PROVISION — posée par les cycles CMD/CRS ; aucune logique ne la lit. | [optional] 
 **noteVocale** | **MultipartFile**| Repère parlé — ≤ 1,5 Mo, m4a/aac. | [optional] 
 **repereTexte** | **String**| Repère écrit. | [optional] 

### Return type

[**Adresse**](Adresse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mesAdresses**
> BuiltList<Adresse> mesAdresses()

Adresses enregistrées du compte courant (FR-021).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();

try {
    final response = api.mesAdresses();
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->mesAdresses: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;Adresse&gt;**](Adresse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **modifierAdresse**
> Adresse modifierAdresse(adresseId, modifierAdresse)

Renomme l'adresse ou met à jour son repère écrit (FR-021).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String adresseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Adresse concernée.
final ModifierAdresse modifierAdresse = ; // ModifierAdresse | 

try {
    final response = api.modifierAdresse(adresseId, modifierAdresse);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->modifierAdresse: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adresseId** | **String**| Adresse concernée. | 
 **modifierAdresse** | [**ModifierAdresse**](ModifierAdresse.md)|  | 

### Return type

[**Adresse**](Adresse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
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

# **remplacerRepereVocal**
> Adresse remplacerRepereVocal(adresseId, dureeS, noteVocale)

Enregistre un nouveau repère vocal — après purge, ou pour le refaire.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String adresseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Adresse concernée.
final int dureeS = 56; // int | Durée — bornée par le paramètre de zone `medias.note_vocale_duree_max_s`.
final MultipartFile noteVocale = BINARY_DATA_HERE; // MultipartFile | Repère parlé — ≤ 1,5 Mo, m4a/aac.

try {
    final response = api.remplacerRepereVocal(adresseId, dureeS, noteVocale);
    print(response);
} on DioException catch (e) {
    print('Exception when calling MoiApi->remplacerRepereVocal: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adresseId** | **String**| Adresse concernée. | 
 **dureeS** | **int**| Durée — bornée par le paramètre de zone `medias.note_vocale_duree_max_s`. | 
 **noteVocale** | **MultipartFile**| Repère parlé — ≤ 1,5 Mo, m4a/aac. | 

### Return type

[**Adresse**](Adresse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
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

# **supprimerAdresse**
> supprimerAdresse(adresseId)

Supprime l'adresse — soft (FR-021).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getMoiApi();
final String adresseId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Adresse concernée.

try {
    api.supprimerAdresse(adresseId);
} on DioException catch (e) {
    print('Exception when calling MoiApi->supprimerAdresse: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **adresseId** | **String**| Adresse concernée. | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

