# mefali_api_client.model.DemandeDevisPanier

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categorieSlug** | **String** | Catégorie de service (`marche`, `restauration`…). | 
**lieu** | [**Lieu**](Lieu.md) | Lieu de prestation — destination de la course. | 
**lignes** | [**BuiltList&lt;LignePanier&gt;**](LignePanier.md) | Lignes du panier, dans l'ordre de composition. | 
**transportSlug** | **String** | Véhicule demandé (`moto`, `velo`…). | 
**zoneId** | **String** | Zone de la commande (résout mixage, plafonds, devise). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


