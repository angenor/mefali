# mefali_api_client.model.ResultatAnnulation

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande annulée. | 
**devise** | **String** | Devise ISO 4217. | 
**montantAvance** | **int** | Montant déjà avancé chez les vendeurs. | 
**partCoursierDue** | **int** | Part due au coursier (unités mineures) — 0 si sans frais. | 
**remboursementDu** | **bool** | Vrai si la commande était prépayée : un remboursement est dû. | 
**sansFrais** | **bool** | Vrai si rien n'avait encore été acheté : annulation SANS FRAIS. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


