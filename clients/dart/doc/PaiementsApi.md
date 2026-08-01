# mefali_api_client.api.PaiementsApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**etatPaiement**](PaiementsApi.md#etatpaiement) | **GET** /commandes/{id}/paiement | État de la session de prépaiement d&#39;une commande.
[**ouvrirPaiement**](PaiementsApi.md#ouvrirpaiement) | **POST** /commandes/{id}/paiement | Ouvre — ou renvoie — la session de prépaiement d&#39;une commande.
[**recevoirNotification**](PaiementsApi.md#recevoirnotification) | **POST** /paiements/notifications/{fournisseur} | Notification signée d&#39;un fournisseur de paiement.


# **etatPaiement**
> SessionPaiement etatPaiement(id)

État de la session de prépaiement d'une commande.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant.

try {
    final response = api.etatPaiement(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsApi->etatPaiement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant. | 

### Return type

[**SessionPaiement**](SessionPaiement.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **ouvrirPaiement**
> SessionPaiement ouvrirPaiement(id)

Ouvre — ou renvoie — la session de prépaiement d'une commande.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant, en attente de paiement.

try {
    final response = api.ouvrirPaiement(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsApi->ouvrirPaiement: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant, en attente de paiement. | 

### Return type

[**SessionPaiement**](SessionPaiement.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **recevoirNotification**
> ReponseNotification recevoirNotification(fournisseur, body)

Notification signée d'un fournisseur de paiement.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getPaiementsApi();
final String fournisseur = fournisseur_example; // String | Identifiant stable de l'implémentation destinataire. Point d'accroche du routage par moyen (phase 2+) — sans règle aujourd'hui.
final String body = body_example; // String | Charge BRUTE du fournisseur, signée. Jamais désérialisée avant vérification de la signature.

try {
    final response = api.recevoirNotification(fournisseur, body);
    print(response);
} on DioException catch (e) {
    print('Exception when calling PaiementsApi->recevoirNotification: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **fournisseur** | **String**| Identifiant stable de l'implémentation destinataire. Point d'accroche du routage par moyen (phase 2+) — sans règle aujourd'hui. | 
 **body** | **String**| Charge BRUTE du fournisseur, signée. Jamais désérialisée avant vérification de la signature. | 

### Return type

[**ReponseNotification**](ReponseNotification.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

