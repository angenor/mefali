# mefali_api_client.model.RemiseBloquee

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**bloqueLe** | [**DateTime**](DateTime.md) | Instant du blocage — **l'ordre de la liste**, le plus ancien d'abord. | 
**commandeId** | **String** | Commande verrouillée. | 
**coursierId** | **String** | Coursier assigné, s'il l'est encore. | [optional] 
**essaisCode** | **int** | Essais consommés au blocage. | 
**livraisonId** | **String** | Livraison portée — celle où le coursier est resté devant la porte. | [optional] 
**reference** | **String** | Référence courte, pour se parler au téléphone. | 
**zoneId** | **String** | Zone de la commande. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


