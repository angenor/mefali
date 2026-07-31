# mefali_api_client.api.CoursesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**arretArrive**](CoursesApi.md#arretarrive) | **POST** /courses/{livraison_id}/arrets/{arret_id}/arrive | CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.
[**arretEnRoute**](CoursesApi.md#arretenroute) | **POST** /courses/{livraison_id}/arrets/{arret_id}/en-route | CMD-04 — le coursier déclare partir vers un arrêt.
[**arretIndisponible**](CoursesApi.md#arretindisponible) | **POST** /courses/{livraison_id}/arrets/{arret_id}/indisponible | CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).
[**declarerEchec**](CoursesApi.md#declarerechec) | **POST** /courses/{livraison_id}/echec | CMD-08 — le coursier déclare l&#39;échec ; le serveur déroule l&#39;arbre §7.5.
[**declarerRupture**](CoursesApi.md#declarerrupture) | **POST** /courses/{livraison_id}/substitutions | CMD-06 — le coursier déclare un article indisponible et applique la préférence du client (FR-044/045).
[**remise**](CoursesApi.md#remise) | **POST** /courses/{livraison_id}/remise | CMD-08 — remise au client : QR, code de secours, ou dépôt convenu.


# **arretArrive**
> EtatArretCourse arretArrive(livraisonId, arretId, actionArret)

CMD-04 — le coursier déclare son ARRIVÉE sur un arrêt.

`arrive_le` est posé par le serveur : c'est la borne de départ de l'attente facturable (prime TRF-06). C'est pour cela que `en_route → collecte` n'existe pas — on ne saute pas une déclaration qui vaut de l'argent.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course, déjà EN ROUTE.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretArrive(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretArrive: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course, déjà EN ROUTE. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **arretEnRoute**
> EtatArretCourse arretEnRoute(livraisonId, arretId, actionArret)

CMD-04 — le coursier déclare partir vers un arrêt.

Le PREMIER départ d'une course la fait passer EN_COLLECTE (data-model §3.2).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretEnRoute(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretEnRoute: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **arretIndisponible**
> EtatArretCourse arretIndisponible(livraisonId, arretId, actionArret)

CMD-04/CMD-06 — arrêt entièrement indisponible (FR-051).

Vendeur fermé, ou plus une seule ligne à collecter. L'arrêt est compté **résolu** (la course continue), son montant avancé retombe à zéro, et ses lignes sont retirées de la commande — les frais de livraison, eux, ne bougent pas (FR-050).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final String arretId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Arrêt de cette course.
final ActionArret actionArret = ; // ActionArret | 

try {
    final response = api.arretIndisponible(livraisonId, arretId, actionArret);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->arretIndisponible: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **arretId** | **String**| Arrêt de cette course. | 
 **actionArret** | [**ActionArret**](ActionArret.md)|  | 

### Return type

[**EtatArretCourse**](EtatArretCourse.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declarerEchec**
> IssueEchec declarerEchec(livraisonId, demandeEchec)

CMD-08 — le coursier déclare l'échec ; le serveur déroule l'arbre §7.5.

**Refusé sans preuves** (`409 preuves_incompletes`, FR-056) : « le coursier ne perd jamais » suppose une trace — appels via l'app espacés, présence géolocalisée, photo sur place. Sans elle, la promesse deviendrait une invitation.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final DemandeEchec demandeEchec = ; // DemandeEchec | 

try {
    final response = api.declarerEchec(livraisonId, demandeEchec);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->declarerEchec: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **demandeEchec** | [**DemandeEchec**](DemandeEchec.md)|  | 

### Return type

[**IssueEchec**](IssueEchec.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **declarerRupture**
> IssueRupture declarerRupture(livraisonId, demande, photo)

CMD-06 — le coursier déclare un article indisponible et applique la préférence du client (FR-044/045).

Trois chemins, deux invariants : le **devis de livraison ne bouge jamais** (FR-050) et le total reste payé **en une fois** (FR-049). La proposition de remplacement est refusée si l'article vient d'un **autre vendeur** (FR-048) ou si l'écart de prix dépasse le plafond de zone (FR-047).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final DemandeRupture demande = ; // DemandeRupture | Partie JSON `demande`.
final MultipartFile photo = BINARY_DATA_HERE; // MultipartFile | Photo du remplacement (obligatoire pour `remplacer` — FR-045).

try {
    final response = api.declarerRupture(livraisonId, demande, photo);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->declarerRupture: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **demande** | [**DemandeRupture**](DemandeRupture.md)| Partie JSON `demande`. | 
 **photo** | **MultipartFile**| Photo du remplacement (obligatoire pour `remplacer` — FR-045). | [optional] 

### Return type

[**IssueRupture**](IssueRupture.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **remise**
> ResultatRemise remise(livraisonId, demande, photo)

CMD-08 — remise au client : QR, code de secours, ou dépôt convenu.

⚠ Le coursier ne reçoit **JAMAIS** le code (research R6) : il en a l'empreinte, et c'est le client qui le lui dicte. La comparaison a lieu côté serveur, sur la valeur stockée.  Trois codes faux et la **saisie par code** est verrouillée (`423`) jusqu'à intervention admin : quatre chiffres se devinent en quelques minutes sans plafond. Le **scan QR reste ouvert** (FR-043, K4-1d) — le jeton est un aléa long, il ne se devine pas.  **Multipart** depuis CRS 010 (R18) : la partie `photo` voyage AVEC la demande, donc dans la file hors-ligne. Référencer un objet « déjà déposé » faisait de la voie dépôt la seule des trois à exiger du réseau.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCoursesApi();
final String livraisonId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Course assignée à l'appelant.
final DemandeRemise demande = ; // DemandeRemise | Partie JSON `demande`.
final MultipartFile photo = BINARY_DATA_HERE; // MultipartFile | Photo du dépôt sur place (mode `depot` — FR-048).

try {
    final response = api.remise(livraisonId, demande, photo);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CoursesApi->remise: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **livraisonId** | **String**| Course assignée à l'appelant. | 
 **demande** | [**DemandeRemise**](DemandeRemise.md)| Partie JSON `demande`. | 
 **photo** | **MultipartFile**| Photo du dépôt sur place (mode `depot` — FR-048). | [optional] 

### Return type

[**ResultatRemise**](ResultatRemise.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: multipart/form-data
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

