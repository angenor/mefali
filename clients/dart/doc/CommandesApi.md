# mefali_api_client.api.CommandesApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**annulerCommande**](CommandesApi.md#annulercommande) | **POST** /commandes/{id}/annuler | CMD-07 — le client annule sa commande.
[**creerCommande**](CommandesApi.md#creercommande) | **POST** /commandes | Crée une commande : prix verrouillés, devis figé, code et QR remis immédiatement (CMD-03).
[**deciderSubstitution**](CommandesApi.md#decidersubstitution) | **POST** /commandes/{id}/substitutions/{sub}/decision | CMD-06 — le client accepte ou refuse un remplacement, dans sa fenêtre.
[**devisPanier**](CommandesApi.md#devispanier) | **POST** /paniers/devis | Devis d&#39;un panier multi-vendeurs — **sans aucun effet de bord** (CMD-01).
[**intentionAppel**](CommandesApi.md#intentionappel) | **POST** /commandes/{id}/appel | CMD-05 — journalise l&#39;intention d&#39;appeler le coursier (FR-041).
[**mesCommandes**](CommandesApi.md#mescommandes) | **GET** /moi/commandes | CMD-05 — les commandes du compte, les plus récentes d&#39;abord.
[**suivreCommande**](CommandesApi.md#suivrecommande) | **GET** /commandes/{id} | CMD-05 — suivi complet d&#39;une commande, pour son **propriétaire**.


# **annulerCommande**
> ResultatAnnulation annulerCommande(id, demandeAnnulation)

CMD-07 — le client annule sa commande.

**Sans frais tant qu'aucun arrêt n'a été collecté** (FR-052) : la frontière est un fait, pas un délai — personne n'a avancé d'argent, il n'y a rien à facturer. Dès le premier achat, la part du coursier est due.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant.
final DemandeAnnulation demandeAnnulation = ; // DemandeAnnulation | 

try {
    final response = api.annulerCommande(id, demandeAnnulation);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->annulerCommande: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant. | 
 **demandeAnnulation** | [**DemandeAnnulation**](DemandeAnnulation.md)|  | 

### Return type

[**ResultatAnnulation**](ResultatAnnulation.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **creerCommande**
> Commande creerCommande(idempotencyKey, demandeCreationCommande)

Crée une commande : prix verrouillés, devis figé, code et QR remis immédiatement (CMD-03).

Un rejeu de la même `Idempotency-Key` rend la commande EXISTANTE avec un corps identique et un `200` — jamais un doublon.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final String idempotencyKey = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | UUIDv7 client — DEVIENT l'identifiant de la commande (R7).
final DemandeCreationCommande demandeCreationCommande = ; // DemandeCreationCommande | 

try {
    final response = api.creerCommande(idempotencyKey, demandeCreationCommande);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->creerCommande: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **idempotencyKey** | **String**| UUIDv7 client — DEVIENT l'identifiant de la commande (R7). | 
 **demandeCreationCommande** | [**DemandeCreationCommande**](DemandeCreationCommande.md)|  | 

### Return type

[**Commande**](Commande.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **deciderSubstitution**
> ResultatDecisionSubstitution deciderSubstitution(id, sub, decisionSubstitution)

CMD-06 — le client accepte ou refuse un remplacement, dans sa fenêtre.

Acceptée, la ligne est remplacée au prix proposé ; refusée, elle est retirée et n'est pas facturée. Dans les deux cas le **devis de livraison ne bouge pas** (FR-050) et le total reste payé **en une fois** (FR-049).  Passé l'échéance, la décision est refusée (`409`) : la fenêtre est une promesse faite au coursier autant qu'au client — au-delà, il a déjà agi.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant.
final String sub = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Proposition de remplacement ouverte.
final DecisionSubstitution decisionSubstitution = ; // DecisionSubstitution | 

try {
    final response = api.deciderSubstitution(id, sub, decisionSubstitution);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->deciderSubstitution: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant. | 
 **sub** | **String**| Proposition de remplacement ouverte. | 
 **decisionSubstitution** | [**DecisionSubstitution**](DecisionSubstitution.md)|  | 

### Return type

[**ResultatDecisionSubstitution**](ResultatDecisionSubstitution.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

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

# **intentionAppel**
> intentionAppel(id, intentionAppel)

CMD-05 — journalise l'intention d'appeler le coursier (FR-041).

L'appel part du téléphone : le serveur n'en voit rien et **ne journalise aucun numéro**. Ce qu'il enregistre, c'est qu'un client a eu BESOIN d'appeler — une métrique de friction (minimisation ARTCI).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant.
final IntentionAppel intentionAppel = ; // IntentionAppel | 

try {
    api.intentionAppel(id, intentionAppel);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->intentionAppel: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant. | 
 **intentionAppel** | [**IntentionAppel**](IntentionAppel.md)|  | 

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **mesCommandes**
> MesCommandes mesCommandes()

CMD-05 — les commandes du compte, les plus récentes d'abord.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();

try {
    final response = api.mesCommandes();
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->mesCommandes: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**MesCommandes**](MesCommandes.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **suivreCommande**
> SuiviCommande suivreCommande(id)

CMD-05 — suivi complet d'une commande, pour son **propriétaire**.

Le code et le jeton de remise ne sont servis qu'ici, et qu'au propriétaire : le coursier, lui, ne reçoit que des empreintes (research R6).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getCommandesApi();
final String id = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Commande du compte appelant.

try {
    final response = api.suivreCommande(id);
    print(response);
} on DioException catch (e) {
    print('Exception when calling CommandesApi->suivreCommande: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **id** | **String**| Commande du compte appelant. | 

### Return type

[**SuiviCommande**](SuiviCommande.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

