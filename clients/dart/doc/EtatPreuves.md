# mefali_api_client.model.EtatPreuves

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**appels** | [**PreuveAppels**](PreuveAppels.md) | Preuve « appels ». | 
**photos** | [**PreuvePhotos**](PreuvePhotos.md) | Preuve « photo ». | 
**presence** | [**PreuvePresence**](PreuvePresence.md) | Preuve « présence ». | 
**reunies** | **bool** | Les trois sont réunies — l'échec devient déclarable. | 
**reuniesSur** | **int** | Compteur « N sur 3 » de K4-1e. | 
**total** | **int** | Toujours 3 — le compteur n'a de sens que si le total est explicite. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


