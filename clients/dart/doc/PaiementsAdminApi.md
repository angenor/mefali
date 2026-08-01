# mefali_api_client.api.PaiementsAdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**cloreDossier**](PaiementsAdminApi.md#cloredossier) | **POST** /admin/paiements/dossiers/{id}/clore | Clôt un dossier, avec motif (FR-082).
[**fileCreances**](PaiementsAdminApi.md#filecreances) | **GET** /admin/creances | File des créances de coursiers (FR-083).
[**fileDossiers**](PaiementsAdminApi.md#filedossiers) | **GET** /admin/paiements/dossiers | File des anomalies d&#39;argent (FR-082).
[**registreTransactions**](PaiementsAdminApi.md#registretransactions) | **GET** /admin/paiements/transactions | Registre filtrable des transactions de paiement (FR-080, FR-081).
[**reglerCreance**](PaiementsAdminApi.md#reglercreance) | **POST** /admin/creances/{id}/regler | Marque une créance réglée et écrit son mouvement de caisse (FR-067).


# **cloreDossier**
> DossierPaiement cloreDossier(id, cloreDossierDto)

Clôt un dossier, avec motif (FR-082).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Dossier ouvert.
final CloreDossierDto cloreDossierDto = ; // CloreDossierDto | 

try {
    final response = api.cloreDossier(id, cloreDossierDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsAdminApi->cloreDossier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Dossier ouvert. | 
 **cloreDossierDto** | [**CloreDossierDto**](CloreDossierDto.md)|  | 

### Return type

[**DossierPaiement**](DossierPaiement.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **fileCreances**
> FileCreances fileCreances(etat, coursierId)

File des créances de coursiers (FR-083).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsAdminApi();
final String etat = etat_example; // String | `due` | `reglee`. Absent = toutes.
final String coursierId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Créances d'un coursier donné.

try {
    final response = api.fileCreances(etat, coursierId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsAdminApi->fileCreances: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **etat** | **String**| `due` | `reglee`. Absent = toutes. | [optional] 
 **coursierId** | **String**| Créances d'un coursier donné. | [optional] 

### Return type

[**FileCreances**](FileCreances.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **fileDossiers**
> FileDossiers fileDossiers(etat, type)

File des anomalies d'argent (FR-082).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsAdminApi();
final String etat = etat_example; // String | `ouvert` | `clos`. Absent = tous.
final String type = type_example; // String | Type de dossier (`montant_divergent`, `retenue_ecretee`, …).

try {
    final response = api.fileDossiers(etat, type);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsAdminApi->fileDossiers: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **etat** | **String**| `ouvert` | `clos`. Absent = tous. | [optional] 
 **type** | **String**| Type de dossier (`montant_divergent`, `retenue_ecretee`, …). | [optional] 

### Return type

[**FileDossiers**](FileDossiers.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **registreTransactions**
> RegistreTransactions registreTransactions(etat, moyen, commandeId, depuis, jusquA)

Registre filtrable des transactions de paiement (FR-080, FR-081).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsAdminApi();
final String etat = etat_example; // String | `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`.
final String moyen = moyen_example; // String | Moyen employé (`wave`, `orange_money`, …).
final String commandeId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Rapprochement par commande — l'autre sens de FR-081.
final DateTime depuis = 2013-10-20T19:20:30+01:00; // DateTime | Borne basse d'ouverture (incluse).
final DateTime jusquA = 2013-10-20T19:20:30+01:00; // DateTime | Borne haute d'ouverture (incluse).

try {
    final response = api.registreTransactions(etat, moyen, commandeId, depuis, jusquA);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsAdminApi->registreTransactions: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **etat** | **String**| `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`. | [optional] 
 **moyen** | **String**| Moyen employé (`wave`, `orange_money`, …). | [optional] 
 **commandeId** | **String**| Rapprochement par commande — l'autre sens de FR-081. | [optional] 
 **depuis** | **DateTime**| Borne basse d'ouverture (incluse). | [optional] 
 **jusquA** | **DateTime**| Borne haute d'ouverture (incluse). | [optional] 

### Return type

[**RegistreTransactions**](RegistreTransactions.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **reglerCreance**
> Creance reglerCreance(id, reglerCreanceDto)

Marque une créance réglée et écrit son mouvement de caisse (FR-067).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Créance due.
final ReglerCreanceDto reglerCreanceDto = ; // ReglerCreanceDto | 

try {
    final response = api.reglerCreance(id, reglerCreanceDto);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsAdminApi->reglerCreance: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Créance due. | 
 **reglerCreanceDto** | [**ReglerCreanceDto**](ReglerCreanceDto.md)|  | 

### Return type

[**Creance**](Creance.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

