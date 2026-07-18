# mefali_api_client.api.AdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**agreerPrestataire**](AdminApi.md#agreerprestataire) | **POST** /admin/prestataires/{id}/agrement | Agrée un prospect : la fiche devient servie et commandable, l&#39;identité de plaque est créée au premier passage, l&#39;activation de catégorie recalculée.
[**ajouterPhoto**](AdminApi.md#ajouterphoto) | **POST** /admin/prestataires/{id}/photos | Ajoute une photo de fiche.
[**consulterDossierCoursier**](AdminApi.md#consulterdossiercoursier) | **GET** /admin/comptes/{compte_id}/dossier-coursier | Dossier complet d&#39;un coursier, pièce lisible comprise (FR-017 scénario 2).
[**consulterPrestataireAdmin**](AdminApi.md#consulterprestataireadmin) | **GET** /admin/prestataires/{id} | Fiche complète (contact, GPS, plaque, chartes présignées, rattachements).
[**creerPrestataire**](AdminApi.md#creerprestataire) | **POST** /admin/prestataires | Crée un prestataire (prospect) — ville de type &#x60;ville&#x60; uniquement.
[**deciderRole**](AdminApi.md#deciderrole) | **POST** /admin/comptes/{compte_id}/roles/{role} | Décision admin sur un rôle — machine à états de data-model §4, journalisée.
[**definirSite**](AdminApi.md#definirsite) | **PUT** /admin/prestataires/{id}/site | Crée ou met à jour LE site (position GPS, horaires, statut initial).
[**deposerCharte**](AdminApi.md#deposercharte) | **POST** /admin/prestataires/{id}/charte | Dépose la charte signée scannée — condition NÉCESSAIRE de l&#39;agrément.
[**detacherCompte**](AdminApi.md#detachercompte) | **DELETE** /admin/prestataires/{id}/rattachements/{compte_id} | Détache un compte — le rôle vendeur du compte ne bouge JAMAIS (FR-008).
[**listerDossiersCoursier**](AdminApi.md#listerdossierscoursier) | **GET** /admin/comptes/dossiers-coursier | Liste des dossiers coursier pour la revue admin (FR-017).
[**listerPrestataires**](AdminApi.md#listerprestataires) | **GET** /admin/prestataires | Liste les prestataires (filtres statut / ville / catégorie).
[**modifierPrestataire**](AdminApi.md#modifierprestataire) | **PUT** /admin/prestataires/{id} | Modifie la fiche (nom, contact, délai) — administrable à tout statut.
[**rattacherCompte**](AdminApi.md#rattachercompte) | **POST** /admin/prestataires/{id}/rattachements | Rattache un compte vérifié — attribue le rôle vendeur si absent, IDEMPOTENT (FR-007, research R11).
[**supprimerPhoto**](AdminApi.md#supprimerphoto) | **DELETE** /admin/prestataires/{id}/photos/{photo_id} | Supprime une photo de fiche (objet S3 purgé APRÈS commit — FR-026).


# **agreerPrestataire**
> PrestataireAdminDetail agreerPrestataire(id)

Agrée un prospect : la fiche devient servie et commandable, l'identité de plaque est créée au premier passage, l'activation de catégorie recalculée.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire (prospect).

try {
    final response = api.agreerPrestataire(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->agreerPrestataire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire (prospect). | 

### Return type

[**PrestataireAdminDetail**](PrestataireAdminDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ajouterPhoto**
> PhotoAdminDto ajouterPhoto(id, fichier)

Ajoute une photo de fiche.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final MultipartFile fichier = BINARY_DATA_HERE; // MultipartFile | La photo.

try {
    final response = api.ajouterPhoto(id, fichier);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->ajouterPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **fichier** | **MultipartFile**| La photo. | 

### Return type

[**PhotoAdminDto**](PhotoAdminDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **consulterDossierCoursier**
> DossierCoursierAdmin consulterDossierCoursier(compteId)

Dossier complet d'un coursier, pièce lisible comprise (FR-017 scénario 2).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String compteId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Coursier concerné.

try {
    final response = api.consulterDossierCoursier(compteId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->consulterDossierCoursier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **compteId** | **String**| Coursier concerné. | 

### Return type

[**DossierCoursierAdmin**](DossierCoursierAdmin.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **consulterPrestataireAdmin**
> PrestataireAdminDetail consulterPrestataireAdmin(id)

Fiche complète (contact, GPS, plaque, chartes présignées, rattachements).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.

try {
    final response = api.consulterPrestataireAdmin(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->consulterPrestataireAdmin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 

### Return type

[**PrestataireAdminDetail**](PrestataireAdminDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **creerPrestataire**
> PrestataireAdmin creerPrestataire(creerPrestataireDto)

Crée un prestataire (prospect) — ville de type `ville` uniquement.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final CreerPrestataireDto creerPrestataireDto = ; // CreerPrestataireDto | 

try {
    final response = api.creerPrestataire(creerPrestataireDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->creerPrestataire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **creerPrestataireDto** | [**CreerPrestataireDto**](CreerPrestataireDto.md)|  | 

### Return type

[**PrestataireAdmin**](PrestataireAdmin.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deciderRole**
> EtatRoleDto deciderRole(compteId, role, decisionRole)

Décision admin sur un rôle — machine à états de data-model §4, journalisée.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String compteId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Compte concerné.
final String role = role_example; // String | Rôle décidé (client exclu : immuable).
final DecisionRole decisionRole = ; // DecisionRole | 

try {
    final response = api.deciderRole(compteId, role, decisionRole);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->deciderRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **compteId** | **String**| Compte concerné. | 
 **role** | **String**| Rôle décidé (client exclu : immuable). | 
 **decisionRole** | [**DecisionRole**](DecisionRole.md)|  | 

### Return type

[**EtatRoleDto**](EtatRoleDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **definirSite**
> PrestataireAdminDetail definirSite(id, siteAdminDto)

Crée ou met à jour LE site (position GPS, horaires, statut initial).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final SiteAdminDto siteAdminDto = ; // SiteAdminDto | 

try {
    final response = api.definirSite(id, siteAdminDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->definirSite: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **siteAdminDto** | [**SiteAdminDto**](SiteAdminDto.md)|  | 

### Return type

[**PrestataireAdminDetail**](PrestataireAdminDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deposerCharte**
> CharteAdminDto deposerCharte(id, fichier, signeeLe, versionCharte)

Dépose la charte signée scannée — condition NÉCESSAIRE de l'agrément.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final MultipartFile fichier = BINARY_DATA_HERE; // MultipartFile | Le scan — ≤ 10 Mo, jpeg/png/webp/pdf.
final Date signeeLe = 2013-10-20; // Date | Date de signature (AAAA-MM-JJ).
final String versionCharte = versionCharte_example; // String | Version de charte en vigueur à la signature.

try {
    final response = api.deposerCharte(id, fichier, signeeLe, versionCharte);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->deposerCharte: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **fichier** | **MultipartFile**| Le scan — ≤ 10 Mo, jpeg/png/webp/pdf. | 
 **signeeLe** | **Date**| Date de signature (AAAA-MM-JJ). | 
 **versionCharte** | **String**| Version de charte en vigueur à la signature. | 

### Return type

[**CharteAdminDto**](CharteAdminDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **detacherCompte**
> detacherCompte(id, compteId)

Détache un compte — le rôle vendeur du compte ne bouge JAMAIS (FR-008).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final String compteId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Compte à détacher.

try {
    api.detacherCompte(id, compteId);
} on DioException catch (e) {
    print('Exception when calling AdminApi->detacherCompte: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **compteId** | **String**| Compte à détacher. | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listerDossiersCoursier**
> BuiltList<DossierCoursierAdmin> listerDossiersCoursier(statut)

Liste des dossiers coursier pour la revue admin (FR-017).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String statut = statut_example; // String | Filtre — tous les dossiers si absent.

try {
    final response = api.listerDossiersCoursier(statut);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->listerDossiersCoursier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **statut** | **String**| Filtre — tous les dossiers si absent. | [optional] 

### Return type

[**BuiltList&lt;DossierCoursierAdmin&gt;**](DossierCoursierAdmin.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **listerPrestataires**
> BuiltList<PrestataireAdmin> listerPrestataires(statut, ville, categorie)

Liste les prestataires (filtres statut / ville / catégorie).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String statut = statut_example; // String | prospect | agree | suspendu.
final String ville = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Ville de rattachement.
final String categorie = categorie_example; // String | Slug de catégorie.

try {
    final response = api.listerPrestataires(statut, ville, categorie);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->listerPrestataires: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **statut** | **String**| prospect | agree | suspendu. | [optional] 
 **ville** | **String**| Ville de rattachement. | [optional] 
 **categorie** | **String**| Slug de catégorie. | [optional] 

### Return type

[**BuiltList&lt;PrestataireAdmin&gt;**](PrestataireAdmin.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **modifierPrestataire**
> PrestataireAdmin modifierPrestataire(id, modifierPrestataireDto)

Modifie la fiche (nom, contact, délai) — administrable à tout statut.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final ModifierPrestataireDto modifierPrestataireDto = ; // ModifierPrestataireDto | 

try {
    final response = api.modifierPrestataire(id, modifierPrestataireDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->modifierPrestataire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **modifierPrestataireDto** | [**ModifierPrestataireDto**](ModifierPrestataireDto.md)|  | 

### Return type

[**PrestataireAdmin**](PrestataireAdmin.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rattacherCompte**
> PrestataireAdminDetail rattacherCompte(id, rattacherCompteDto)

Rattache un compte vérifié — attribue le rôle vendeur si absent, IDEMPOTENT (FR-007, research R11).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire AGRÉÉ.
final RattacherCompteDto rattacherCompteDto = ; // RattacherCompteDto | 

try {
    final response = api.rattacherCompte(id, rattacherCompteDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->rattacherCompte: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire AGRÉÉ. | 
 **rattacherCompteDto** | [**RattacherCompteDto**](RattacherCompteDto.md)|  | 

### Return type

[**PrestataireAdminDetail**](PrestataireAdminDetail.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **supprimerPhoto**
> supprimerPhoto(id, photoId)

Supprime une photo de fiche (objet S3 purgé APRÈS commit — FR-026).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Prestataire.
final String photoId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Photo à supprimer.

try {
    api.supprimerPhoto(id, photoId);
} on DioException catch (e) {
    print('Exception when calling AdminApi->supprimerPhoto: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Prestataire. | 
 **photoId** | **String**| Photo à supprimer. | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

