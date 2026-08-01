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
[**expositionCash**](CoursierAdminApi.md#expositioncash) | **GET** /admin/coursiers/exposition | CRS-06 (exploitation) — le cash que la flotte porte en ce moment (FR-075).
[**fileIndemnisations**](CoursierAdminApi.md#fileindemnisations) | **GET** /admin/indemnisations | CRS-06 (exploitation) — la file des indemnisations (FR-071).
[**preuvesDeLivraison**](CoursierAdminApi.md#preuvesdelivraison) | **GET** /admin/livraisons/{livraison_id}/preuves | CRS-05 (exploitation) — le dossier de preuves d&#39;une livraison (FR-063).
[**refuserIndemnisation**](CoursierAdminApi.md#refuserindemnisation) | **POST** /admin/indemnisations/{indemnisation_id}/refuser | CRS-06 (exploitation) — refuse une indemnisation, **motif obligatoire**.
[**remisesBloquees**](CoursierAdminApi.md#remisesbloquees) | **GET** /admin/remises/bloquees | **FR-044** — les remises dont le code est épuisé et le blocage non levé.
[**validerIndemnisation**](CoursierAdminApi.md#validerindemnisation) | **POST** /admin/indemnisations/{indemnisation_id}/valider | CRS-06 (exploitation) — valide une indemnisation : l&#39;argent entre au livre.


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

# **expositionCash**
> ExpositionCash expositionCash()

CRS-06 (exploitation) — le cash que la flotte porte en ce moment (FR-075).

C'est le nombre qui dit combien d'argent de Mefali circule dans des poches. Sans lui, une dérive ne se verrait qu'au comptage du soir.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();

try {
    final response = api.expositionCash();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->expositionCash: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**ExpositionCash**](ExpositionCash.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **fileIndemnisations**
> FileIndemnisations fileIndemnisations(etat)

CRS-06 (exploitation) — la file des indemnisations (FR-071).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String etat = etat_example; // String | `demandee` | `validee` | `refusee`. Absent = toutes.

try {
    final response = api.fileIndemnisations(etat);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->fileIndemnisations: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **etat** | **String**| `demandee` | `validee` | `refusee`. Absent = toutes. | [optional] 

### Return type

[**FileIndemnisations**](FileIndemnisations.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **preuvesDeLivraison**
> PreuvesExploitation preuvesDeLivraison(livraisonId)

CRS-05 (exploitation) — le dossier de preuves d'une livraison (FR-063).

C'est ce qui rend les preuves **lisibles**. Sans cet endpoint, elles existeraient en base sans que personne ne puisse répondre à un client qui conteste un échec — et une preuve que personne ne lit ne protège personne.  ⚠ Aucun numéro de téléphone n'en sort : le serveur n'en a jamais journalisé.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Livraison dont on lit les preuves.

try {
    final response = api.preuvesDeLivraison(livraisonId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->preuvesDeLivraison: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Livraison dont on lit les preuves. | 

### Return type

[**PreuvesExploitation**](PreuvesExploitation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **refuserIndemnisation**
> IndemnisationDecidee refuserIndemnisation(indemnisationId, decisionIndemnisation)

CRS-06 (exploitation) — refuse une indemnisation, **motif obligatoire**.

Aucune écriture de caisse : rien n'entre, rien ne sort. Ce que Yao doit pouvoir lire, c'est la raison (FR-072).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String indemnisationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Indemnisation à refuser.
final DecisionIndemnisation decisionIndemnisation = ; // DecisionIndemnisation | 

try {
    final response = api.refuserIndemnisation(indemnisationId, decisionIndemnisation);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->refuserIndemnisation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **indemnisationId** | **String**| Indemnisation à refuser. | 
 **decisionIndemnisation** | [**DecisionIndemnisation**](DecisionIndemnisation.md)|  | 

### Return type

[**IndemnisationDecidee**](IndemnisationDecidee.md)

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

# **validerIndemnisation**
> IndemnisationDecidee validerIndemnisation(indemnisationId)

CRS-06 (exploitation) — valide une indemnisation : l'argent entre au livre.

L'écriture de caisse et l'événement partent dans la MÊME transaction que le changement d'état : une validation sans son écriture laisserait Yao avec une promesse et rien dans sa caisse.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursierAdminApi();
final String indemnisationId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Indemnisation à valider.

try {
    final response = api.validerIndemnisation(indemnisationId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursierAdminApi->validerIndemnisation: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **indemnisationId** | **String**| Indemnisation à valider. | 

### Return type

[**IndemnisationDecidee**](IndemnisationDecidee.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

