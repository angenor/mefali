# mefali_api_client.api.AdminApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**deciderRole**](AdminApi.md#deciderrole) | **POST** /admin/comptes/{compte_id}/roles/{role} | Décision admin sur un rôle — machine à états de data-model §4, journalisée.


# **deciderRole**
> EtatRoleDto deciderRole(compteId, role, decisionRole)

Décision admin sur un rôle — machine à états de data-model §4, journalisée.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getAdminApi();
final String compteId = 38400000-8cf0-11bd-b23e-10b96e4ef00d; // String | Compte concerné.
final String role = role_example; // String | Rôle décidé (client exclu : immuable).
final DecisionRole decisionRole = ; // DecisionRole | 

try {
    final response = api.deciderRole(compteId, role, decisionRole);
    print(response);
} on DioException catch (e) {
    print('Exception when calling AdminApi->deciderRole: $e\n');
}
```

### Parameters

Name | Type | Description  | Notes
------------- | ------------- | ------------- | -------------
 **compteId** | **String**| Compte concerné. | 
 **role** | **String**| Rôle décidé (client exclu : immuable). | 
 **decisionRole** | [**DecisionRole**](DecisionRole.md)|  | 

### Return type

[**EtatRoleDto**](EtatRoleDto.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

