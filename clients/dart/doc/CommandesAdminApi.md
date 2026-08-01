# mefali_api_client.api.CommandesAdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**annulerCommandeAdmin**](CommandesAdminApi.md#annulercommandeadmin) | **POST** /admin/commandes/{id}/annuler | CMD-07 — un administrateur annule une commande, **motif obligatoire**.
[**enregistrerIssue**](CommandesAdminApi.md#enregistrerissue) | **POST** /admin/commandes/{id}/issues | CMD-08 — un administrateur enregistre une issue de l&#39;arbre §7.5.
[**fileAttente**](CommandesAdminApi.md#fileattente) | **GET** /admin/commandes/attente | CMD-10 — file FIFO des commandes sans coursier d&#39;une zone.


# **annulerCommandeAdmin**
> ResultatAnnulation annulerCommandeAdmin(id, demandeAnnulation)

CMD-07 — un administrateur annule une commande, **motif obligatoire**.

Le motif n'est pas une formalité : il est journalisé, il part dans l'événement, et c'est lui que le client lira. C'est une **clé i18n**, jamais du texte libre — un motif écrit à la main serait illisible pour la moitié des clients et impossible à agréger pour l'exploitation.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande à annuler.
final DemandeAnnulation demandeAnnulation = ; // DemandeAnnulation | 

try {
    final response = api.annulerCommandeAdmin(id, demandeAnnulation);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesAdminApi->annulerCommandeAdmin: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande à annuler. | 
 **demandeAnnulation** | [**DemandeAnnulation**](DemandeAnnulation.md)|  | 

### Return type

[**ResultatAnnulation**](ResultatAnnulation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **enregistrerIssue**
> IssueEchec enregistrerIssue(id, demandeIssueAdmin)

CMD-08 — un administrateur enregistre une issue de l'arbre §7.5.

La même table de décision que la surface coursier, par une autre porte : ce que le support tranche au téléphone doit produire exactement les mêmes deux détenteurs, le même litige et la même sanction qu'une déclaration terrain. Deux chemins qui divergeraient seraient deux vérités sur le même incident.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesAdminApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande concernée.
final DemandeIssueAdmin demandeIssueAdmin = ; // DemandeIssueAdmin | 

try {
    final response = api.enregistrerIssue(id, demandeIssueAdmin);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesAdminApi->enregistrerIssue: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande concernée. | 
 **demandeIssueAdmin** | [**DemandeIssueAdmin**](DemandeIssueAdmin.md)|  | 

### Return type

[**IssueEchec**](IssueEchec.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **fileAttente**
> FileAttenteCoursier fileAttente(zoneId)

CMD-10 — file FIFO des commandes sans coursier d'une zone.

L'ordre est l'âge, du plus ancien au plus récent : c'est la promesse produite au client qui attend (« la plus ancienne repart en premier »), et c'est le contrat que **DSP** consommera tel quel.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesAdminApi();
final String zoneId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Zone (ville) dont on veut la file d'attente.

try {
    final response = api.fileAttente(zoneId);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesAdminApi->fileAttente: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **zoneId** | **String**| Zone (ville) dont on veut la file d'attente. | 

### Return type

[**FileAttenteCoursier**](FileAttenteCoursier.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

