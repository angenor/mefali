# mefali_api_client.model.PrestatairePilotable

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**boutique** | [**EtatEffectifBoutique**](EtatEffectifBoutique.md) | État effectif de la boutique. | 
**id** | **String** | Identifiant. | 
**nom** | **String** | Nom public. | 
**offreLivraison** | **String** | Offre de livraison déclarée (VND-08) : `jamais` | `toujours` | `au_dela`.  Champ ADDITIF (cycle PAY 011) : l'app livrée l'ignore et continue de fonctionner. Servi ici plutôt que par une route dédiée parce que le réglage vit sur l'écran boutique, et qu'un second aller-retour pour deux scalaires n'aurait servi personne. | 
**offreLivraisonSeuilUnites** | **int** | Seuil de panier de l'offre `au_dela`, `null` sinon. | [optional] 
**statut** | [**StatutPrestataire**](StatutPrestataire.md) | Cycle de vie — `suspendu` : l'app affiche le refus, le rôle est intact. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


