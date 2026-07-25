# mefali_api_client.api.CommandesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**devisPanier**](CommandesApi.md#devispanier) | **POST** /paniers/devis | Devis d&#39;un panier multi-vendeurs — **sans aucun effet de bord** (CMD-01).


# **devisPanier**
> DevisPanier devisPanier(demandeDevisPanier)

Devis d'un panier multi-vendeurs — **sans aucun effet de bord** (CMD-01).

Regroupe par vendeur, chiffre les frais via le moteur tarifaire, et renvoie les deux déclencheurs de proposition de scission en UNE seule surface. Aucune ligne n'est écrite, aucune commande n'est créée : rien n'est engagé tant que le client n'a pas confirmé (FR-010, research R8).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final DemandeDevisPanier demandeDevisPanier = ; // DemandeDevisPanier | 

try {
    final response = api.devisPanier(demandeDevisPanier);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->devisPanier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **demandeDevisPanier** | [**DemandeDevisPanier**](DemandeDevisPanier.md)|  | 

### Return type

[**DevisPanier**](DevisPanier.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

