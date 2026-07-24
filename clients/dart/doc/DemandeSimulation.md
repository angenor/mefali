# mefali_api_client.model.DemandeSimulation

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**attentes** | [**BuiltList&lt;Attente&gt;**](Attente.md) | Attentes constatées, `null` = aucune. | [optional] 
**categorieSlug** | **String** | Catégorie de service, `null` = aucune contrainte. | [optional] 
**destination** | [**Point**](Point.md) | Destination client. | 
**instant** | [**DateTime**](DateTime.md) | Instant d'évaluation (plages horaires, jours, dates d'effet). | 
**monoVendeur** | **bool** | Commande mono-vendeur — condition NÉCESSAIRE de VND-08. | 
**montantPanier** | **int** | Montant du panier (unités mineures) — seuil VND-08. | [optional] 
**nbArticles** | **int** | Nombre total d'articles de la commande (paliers d'effort). | 
**offreLivraisonVendeur** | [**OffreLivraisonVendeur**](OffreLivraisonVendeur.md) | Offre de livraison du vendeur, `null` = aucune. | [optional] 
**transportSlug** | **String** | Véhicule. | 
**vendeurs** | [**BuiltList&lt;Point&gt;**](Point.md) | Points de retrait (1..n), dans un ordre quelconque — le moteur optimise. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


