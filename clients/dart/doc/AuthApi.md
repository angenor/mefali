# mefali_api_client.api.AuthApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deconnexion**](AuthApi.md#deconnexion) | **POST** /auth/deconnexion | Révoque la session courante (déconnexion locale).
[**demander**](AuthApi.md#demander) | **POST** /auth/otp/demander | Demande l&#39;envoi d&#39;un code OTP. Réponse TOUJOURS neutre (SC-003).
[**inscrire**](AuthApi.md#inscrire) | **POST** /auth/inscription | Crée le compte après consentement ARTCI, puis ouvre sa session.
[**rafraichir**](AuthApi.md#rafraichir) | **POST** /auth/rafraichir | Échange le refresh contre un nouvel accès (rotation systématique, R2).
[**verifier**](AuthApi.md#verifier) | **POST** /auth/otp/verifier | Vérifie le code : ouvre une session (numéro connu) ou exige le consentement.


# **deconnexion**
> deconnexion()

Révoque la session courante (déconnexion locale).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAuthApi();

try {
    api.deconnexion();
} on DioException catch (e) {
    print('Exception when calling AuthApi->deconnexion: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

void (empty response body)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **demander**
> Accepte demander(demandeOtp)

Demande l'envoi d'un code OTP. Réponse TOUJOURS neutre (SC-003).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAuthApi();
final DemandeOtp demandeOtp = ; // DemandeOtp | 

try {
    final response = api.demander(demandeOtp);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->demander: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **demandeOtp** | [**DemandeOtp**](DemandeOtp.md)|  | 

### Return type

[**Accepte**](Accepte.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **inscrire**
> ResultatVerification inscrire(inscription)

Crée le compte après consentement ARTCI, puis ouvre sa session.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAuthApi();
final Inscription inscription = ; // Inscription | 

try {
    final response = api.inscrire(inscription);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->inscrire: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **inscription** | [**Inscription**](Inscription.md)|  | 

### Return type

[**ResultatVerification**](ResultatVerification.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **rafraichir**
> JetonsDto rafraichir(demandeRafraichissement)

Échange le refresh contre un nouvel accès (rotation systématique, R2).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAuthApi();
final DemandeRafraichissement demandeRafraichissement = ; // DemandeRafraichissement | 

try {
    final response = api.rafraichir(demandeRafraichissement);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->rafraichir: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **demandeRafraichissement** | [**DemandeRafraichissement**](DemandeRafraichissement.md)|  | 

### Return type

[**JetonsDto**](JetonsDto.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **verifier**
> ResultatVerification verifier(verificationOtp)

Vérifie le code : ouvre une session (numéro connu) ou exige le consentement.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAuthApi();
final VerificationOtp verificationOtp = ; // VerificationOtp | 

try {
    final response = api.verifier(verificationOtp);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AuthApi->verifier: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **verificationOtp** | [**VerificationOtp**](VerificationOtp.md)|  | 

### Return type

[**ResultatVerification**](ResultatVerification.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

