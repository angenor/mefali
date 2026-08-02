# mefali_api_client.model.RecuCommande

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande. | 
**dejaRegle** | **bool** | La commande est-elle déjà réglée ? (FR-073) | 
**devise** | **String** | Devise ISO 4217. | 
**fraisLivraisonUnites** | **int** | Frais de livraison facturés. | 
**lignes** | [**BuiltList&lt;LigneRecu&gt;**](LigneRecu.md) | Lignes, **retirées comprises** : le reçu explique pourquoi le total a bougé plutôt que de le faire bouger en silence. | 
**modePaiement** | **String** | `cash` | `mobile_money`. | 
**montantARemettreAuCoursierUnites** | **int** | Ce qui reste à remettre au coursier — **0** sur une commande prépayée. | 
**montantArticlesUnites** | **int** | Somme des lignes vivantes. | 
**moyen** | **String** | Moyen employé — `null` tant que le fournisseur ne l'a pas dit (FR-012). | [optional] 
**retenueVendeurUnites** | **int** | Part de frais prise en charge par le vendeur (VND-08), `0` sinon. | 
**totalDuUnites** | **int** | Total dû, déjà ajusté par les retraits et les arrêts indisponibles. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


