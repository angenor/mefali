# mefali_api_client.model.ExpositionCash

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**au** | [**DateTime**](DateTime.md) | Instant de la lecture — l'exposition est vraie **à quelques secondes** près (délai du worker outbox, SC-010 l'accepte explicitement). | 
**devise** | **String** | Devise ISO 4217. | 
**parCoursier** | [**BuiltList&lt;LigneExposition&gt;**](LigneExposition.md) | Détail, du plus exposé au moins exposé. | 
**totalUnites** | **int** | Total en circulation. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


