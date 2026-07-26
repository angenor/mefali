# mefali_api_client.model.DemandeCreationCommande

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**adresseId** | **String** | Adresse du carnet (CPT-05) — ou `lieu` + repère fournis en clair. | [optional] 
**categorieSlug** | **String** | Catégorie de service. | 
**lieu** | [**Lieu**](Lieu.md) | Pin GPS, si aucune adresse du carnet n'est utilisée. | [optional] 
**lignes** | [**BuiltList&lt;LignePanier&gt;**](LignePanier.md) | Lignes du panier. | 
**modePaiement** | **String** | `cash` | `mobile_money`. | 
**repereTexte** | **String** | Repère écrit. | [optional] 
**repereVocalCle** | **String** | Clé S3 du repère vocal. | [optional] 
**transportSlug** | **String** | Véhicule demandé. | 
**zoneId** | **String** | Zone de la commande. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


