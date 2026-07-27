# mefali_api_client.api.DispatchApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**basculerDisponibiliteCoursier**](DispatchApi.md#basculerdisponibilitecoursier) | **PUT** /moi/disponibilite | &#x60;PUT /moi/disponibilite&#x60; — se mettre en ligne ou hors ligne.
[**lireDisponibilite**](DispatchApi.md#liredisponibilite) | **GET** /moi/disponibilite | &#x60;GET /moi/disponibilite&#x60; — l&#39;état courant, tel que K1 l&#39;affiche.
[**publierPosition**](DispatchApi.md#publierposition) | **POST** /moi/position | &#x60;POST /moi/position&#x60; — publier sa position, et rester dans le pool.


# **basculerDisponibiliteCoursier**
> EtatDisponibilite basculerDisponibiliteCoursier(basculeDisponibilite)

`PUT /moi/disponibilite` — se mettre en ligne ou hors ligne.

⚠ Le suffixe `_coursier` n'est pas décoratif : utoipa dérive l'`operationId` du NOM DE LA FONCTION, et `vendeur_http::basculer_disponibilite` (bascule d'un article en rupture) porte déjà le nom court. Deux `operationId` identiques font échouer la génération des clients — donc la CI.  Passer `en_ligne: false` retire du pool **immédiatement**, sans attendre l'expiration (FR-005) : un coursier qui a rangé sa moto ne doit pas voir son téléphone sonner 90 s plus tard.  Se mettre en ligne exige un dossier valide et **au moins une capacité déclarée** : sans véhicule, aucune course ne pourra jamais lui être proposée, et le lui dire tout de suite vaut mieux qu'une attente muette.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchApi();
final BasculeDisponibilite basculeDisponibilite = ; // BasculeDisponibilite | 

try {
    final response = api.basculerDisponibiliteCoursier(basculeDisponibilite);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchApi->basculerDisponibiliteCoursier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **basculeDisponibilite** | [**BasculeDisponibilite**](BasculeDisponibilite.md)|  | 

### Return type

[**EtatDisponibilite**](EtatDisponibilite.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **lireDisponibilite**
> EtatDisponibilite lireDisponibilite()

`GET /moi/disponibilite` — l'état courant, tel que K1 l'affiche.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchApi();

try {
    final response = api.lireDisponibilite();
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchApi->lireDisponibilite: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**EtatDisponibilite**](EtatDisponibilite.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **publierPosition**
> EtatPublicationPosition publierPosition(publicationPosition)

`POST /moi/position` — publier sa position, et rester dans le pool.

`204` si le coursier n'est pas en ligne : la position n'est pas **refusée**, elle est **ignorée** — l'app peut être en retard d'un tic après un « hors ligne », et lui rendre une erreur ferait clignoter un écran pour rien.  **Idempotence** : rejouer la même position repousse simplement la durée de vie ; aucun événement n'est écrit dans les deux cas (une position est un fait éphémère qui se répète toutes les 30 s, et elle porte une coordonnée que la minimisation interdit de journaliser).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getDispatchApi();
final PublicationPosition publicationPosition = ; // PublicationPosition | 

try {
    final response = api.publierPosition(publicationPosition);
    print(response);
} on DioException catch (e) {
    print('Exception when calling DispatchApi->publierPosition: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **publicationPosition** | [**PublicationPosition**](PublicationPosition.md)|  | 

### Return type

[**EtatPublicationPosition**](EtatPublicationPosition.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

