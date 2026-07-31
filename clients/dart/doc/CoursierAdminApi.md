# mefali_api_client.api.CoursierAdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**autoriserDepot**](CoursierAdminApi.md#autoriserdepot) | **POST** /admin/commandes/{commande_id}/depot | **FR-116** — ouvre (ou referme) la voie « dépôt convenu » sur une commande.
[**debloquerCode**](CoursierAdminApi.md#debloquercode) | **POST** /admin/commandes/{commande_id}/code/debloquer | **FR-055** — l&#39;exploitation lève le blocage du code, avec motif tracé.
[**remisesBloquees**](CoursierAdminApi.md#remisesbloquees) | **GET** /admin/remises/bloquees | **FR-044** — les remises dont le code est épuisé et le blocage non levé.


# **autoriserDepot**
> DecisionDepot autoriserDepot(commandeId, demandeDepot)

**FR-116** — ouvre (ou referme) la voie « dépôt convenu » sur une commande.

Le cadrage §7.4-5 dit « mode dépôt autorisé **par le client** ». Tant qu'aucune surface cliente ne le porte, c'est l'exploitation qui l'ouvre à sa demande, au téléphone, avec un motif tracé — le contrat ne changera pas quand l'app cliente reprendra la main.  **Fermé par défaut** : un défaut ouvert aurait rendu le dépôt possible partout sans que personne ne l'ait décidé.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String commandeId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande concernée.
final DemandeDepot demandeDepot = ; // DemandeDepot | 

try {
    final response = api.autoriserDepot(commandeId, demandeDepot);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->autoriserDepot: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commandeId** | **String**| Commande concernée. | 
 **demandeDepot** | [**DemandeDepot**](DemandeDepot.md)|  | 

### Return type

[**DecisionDepot**](DecisionDepot.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **debloquerCode**
> debloquerCode(commandeId, demandeDeblocage)

**FR-055** — l'exploitation lève le blocage du code, avec motif tracé.

Le compteur d'essais retombe à zéro : une levée qui laisserait le compteur au plafond serait inopérante — le premier essai suivant rebloquerait la commande, et l'exploitation croirait avoir agi.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String commandeId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande dont le code est bloqué.
final DemandeDeblocage demandeDeblocage = ; // DemandeDeblocage | 

try {
    api.debloquerCode(commandeId, demandeDeblocage);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->debloquerCode: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **commandeId** | **String**| Commande dont le code est bloqué. | 
 **demandeDeblocage** | [**DemandeDeblocage**](DemandeDeblocage.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remisesBloquees**
> RemisesBloquees remisesBloquees(zoneId)

**FR-044** — les remises dont le code est épuisé et le blocage non levé.

Le verrou du code protège un secret à quatre chiffres, mais il laisse une commande à la porte du client. Sans cette lecture, l'alerte `remise.code_epuise` partirait dans l'outbox sans que personne ne puisse répondre — et un humain ne s'abonne pas à un journal.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone dont on veut les blocages. Absente = toutes les zones.

try {
    final response = api.remisesBloquees(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->remisesBloquees: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Zone dont on veut les blocages. Absente = toutes les zones. | [optional] 

### Return type

[**RemisesBloquees**](RemisesBloquees.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

