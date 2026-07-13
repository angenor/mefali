# mefali_api_client.api.SocleApi

## Load the API package
```dart
import 'package:mefali_api_client/api.dart';
```

All URIs are relative to *http://localhost*

Method | HTTP request | Description
------------- | ------------- | -------------
[**health**](SocleApi.md#health) | **GET** /health | Sonde de vie du service. Répond &#x60;200 {status:\&quot;ok\&quot;, version}&#x60;.


# **health**
> HealthResponse health()

Sonde de vie du service. Répond `200 {status:\"ok\", version}`.

### Example
```dart
import 'package:mefali_api_client/api.dart';

final api = MefaliApiClient().getSocleApi();

try {
    final response = api.health();
    print(response);
} on DioException catch (e) {
    print('Exception when calling SocleApi->health: $e\n');
}
```

### Parameters
This endpoint does not need any parameter.

### Return type

[**HealthResponse**](HealthResponse.md)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

