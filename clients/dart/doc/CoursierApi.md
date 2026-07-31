# mefali_api_client.api.CoursierApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**courseActive**](CoursierApi.md#courseactive) | **GET** /courses/active | CRS-03 — course active du coursier, **complète** et pré-provisionnée.
[**declarerIssueAppel**](CoursierApi.md#declarerissueappel) | **PATCH** /courses/{livraison_id}/appels | CRS-03 — déclare (ou corrige) l&#39;issue d&#39;un appel (FR-036, R19).
[**deposerPhotoPreuve**](CoursierApi.md#deposerphotopreuve) | **POST** /courses/{livraison_id}/preuves/photo | CRS-05 — dépose une photo de preuve d&#39;échec (FR-056, FR-064).
[**enregistrerPresence**](CoursierApi.md#enregistrerpresence) | **POST** /courses/{livraison_id}/presence | CRS-05 — enregistre un lot de relevés de présence (FR-061, FR-064).
[**etatPreuves**](CoursierApi.md#etatpreuves) | **GET** /courses/{livraison_id}/preuves | CRS-05 — état des trois preuves et **ce qui manque** (FR-058, FR-062).
[**journaliserAppel**](CoursierApi.md#journaliserappel) | **POST** /courses/{livraison_id}/appels | CRS-03 — journalise un appel passé **via l&#39;app** (FR-030, FR-031, FR-033).
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

# **declarerIssueAppel**
> AppelEnregistre declarerIssueAppel(livraisonId, issueAppelDeclaree)

CRS-03 — déclare (ou corrige) l'issue d'un appel (FR-036, R19).

Le serveur ne peut pas l'observer : l'appel part du téléphone. Cette issue sert l'affichage de K4-1e et **n'est jamais un critère de preuve** — un coursier qui déclarerait « sans réponse » à tort ne gagne rien.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison de la course active du coursier.
final IssueAppelDeclaree issueAppelDeclaree = ; // IssueAppelDeclaree | 

try {
    final response = api.declarerIssueAppel(livraisonId, issueAppelDeclaree);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->declarerIssueAppel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison de la course active du coursier. | 
 **issueAppelDeclaree** | [**IssueAppelDeclaree**](IssueAppelDeclaree.md)|  | 

### Return type

[**AppelEnregistre**](AppelEnregistre.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deposerPhotoPreuve**
> PhotoPreuveDeposee deposerPhotoPreuve(livraisonId, demande, photo)

CRS-05 — dépose une photo de preuve d'échec (FR-056, FR-064).

**Multipart** pour la même raison que la remise (R18) : la photo voyage AVEC la demande, donc dans la file hors-ligne. Une preuve qui exigerait du réseau au moment de la prise serait une preuve qu'on ne peut pas réunir là où elle sert — devant une porte close, dans un quartier sans couverture.  Idempotent par `uuid_client` : le rejeu ne redépose rien et ne compte pas une seconde photo.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison de la course active du coursier.
final DemandePhotoPreuve demande = ; // DemandePhotoPreuve | Partie JSON `demande`.
final MultipartFile photo = BINARY_DATA_HERE; // MultipartFile | Photo de la porte close.

try {
    final response = api.deposerPhotoPreuve(livraisonId, demande, photo);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->deposerPhotoPreuve: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison de la course active du coursier. | 
 **demande** | [**DemandePhotoPreuve**](DemandePhotoPreuve.md)| Partie JSON `demande`. | 
 **photo** | **MultipartFile**| Photo de la porte close. | 

### Return type

[**PhotoPreuveDeposee**](PhotoPreuveDeposee.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enregistrerPresence**
> PresenceEnregistree enregistrerPresence(livraisonId, lotDePresence)

CRS-05 — enregistre un lot de relevés de présence (FR-061, FR-064).

L'app envoie des **échantillons**, jamais une durée : c'est le serveur qui compte, en ignorant tout intervalle supérieur au « trou » de la zone. Sans cette règle, deux relevés espacés de dix minutes vaudraient dix minutes de présence, et un aller-retour vaudrait une attente (R8).  Idempotent par `uuid_client` : un lot rejoué par la file rend le même corps.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison de la course active du coursier.
final LotDePresence lotDePresence = ; // LotDePresence | 

try {
    final response = api.enregistrerPresence(livraisonId, lotDePresence);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->enregistrerPresence: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison de la course active du coursier. | 
 **lotDePresence** | [**LotDePresence**](LotDePresence.md)|  | 

### Return type

[**PresenceEnregistree**](PresenceEnregistree.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **etatPreuves**
> EtatPreuves etatPreuves(livraisonId)

CRS-05 — état des trois preuves et **ce qui manque** (FR-058, FR-062).

C'est la **même fonction** que celle qui garde `POST /courses/{id}/echec` : l'écran et le serveur ne peuvent pas diverger (FR-059, FR-060). Un bouton actif dont la déclaration serait refusée serait pire qu'un bouton inactif.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison de la course active du coursier.

try {
    final response = api.etatPreuves(livraisonId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->etatPreuves: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison de la course active du coursier. | 

### Return type

[**EtatPreuves**](EtatPreuves.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **journaliserAppel**
> AppelEnregistre journaliserAppel(livraisonId, demandeAppel)

CRS-03 — journalise un appel passé **via l'app** (FR-030, FR-031, FR-033).

⚠ **Aucun numéro** n'est transmis ni journalisé : le serveur ne voit pas l'appel, il part du téléphone. Il en garde l'intention, la direction, le motif et l'issue déclarée.  Idempotent par `uuid_client` : le rejeu rend `200` et le même corps, sans seconde ligne ni second événement.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison de la course active du coursier.
final DemandeAppel demandeAppel = ; // DemandeAppel | 

try {
    final response = api.journaliserAppel(livraisonId, demandeAppel);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierApi->journaliserAppel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison de la course active du coursier. | 
 **demandeAppel** | [**DemandeAppel**](DemandeAppel.md)|  | 

### Return type

[**AppelEnregistre**](AppelEnregistre.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
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

