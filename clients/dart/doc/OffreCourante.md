# mefali_api_client.model.OffreCourante

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arrets** | [**BuiltList&lt;ArretOffre&gt;**](ArretOffre.md) | Arrêts dans l'ordre optimisé du devis FIGÉ. | 
**avance** | [**AvanceOffre**](AvanceOffre.md) | Avance et plafond. | 
**commandeId** | **String** | Commande offerte. | 
**degraded** | **bool** | Vrai si les distances viennent du repli vol d'oiseau (constitution IV). | 
**destination** | [**DestinationOffre**](DestinationOffre.md) | Destination approximative. | 
**echeanceLe** | [**DateTime**](DateTime.md) | **AUTORITÉ** du compte à rebours : le widget compte, le serveur tranche. | 
**gain** | [**GainOffre**](GainOffre.md) | Gain détaillé. | 
**mode** | **String** | `cascade` | `broadcast`. | 
**offreId** | **String** | Offre concernée. | 
**restantS** | **int** | Secondes restantes à l'instant de la lecture. | 
**timerS** | **int** | Durée totale du compte à rebours (secondes). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


