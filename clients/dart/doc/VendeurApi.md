# mefali_api_client.api.VendeurApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**mesPrestataires**](VendeurApi.md#mesprestataires) | **GET** /vendeur/prestataires | Prestataires que ce compte pilote (rattachements du cycle VND).


# **mesPrestataires**
> BuiltList<PrestatairePilotable> mesPrestataires()

Prestataires que ce compte pilote (rattachements du cycle VND).

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getVendeurApi();

try {
    final response = api.mesPrestataires();
    print(response);
} on DioException catch (e) {
    print('Exception when calling VendeurApi->mesPrestataires: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**BuiltList&lt;PrestatairePilotable&gt;**](PrestatairePilotable.md)

### Authorization

[bearerAuth](../README.md#bearerAuth)

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

