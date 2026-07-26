# mefali_api_client.model.SuiviCommande

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**coursier** | [**CoursierSuivi**](CoursierSuivi.md) | Coursier affecté. | [optional] 
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | État de très haut niveau. | 
**etatCle** | **String** | **Clé i18n** de l'état affiché — jamais une phrase (constitution VII). | 
**etatLe** | [**DateTime**](DateTime.md) | Instant du dernier changement d'état. | 
**id** | **String** | Commande. | 
**livraisonEtat** | **String** | État logistique. | [optional] 
**livraisonId** | **String** | Livraison, si la commande en a une (composant 0..n). | [optional] 
**montantArticlesUnites** | **int** | Montant des articles (révisé si des articles ont sauté). | 
**position** | [**PositionSuivi**](PositionSuivi.md) | Dernière position connue — `null` si aucune (research R13). | [optional] 
**progression** | [**ProgressionSuivi**](ProgressionSuivi.md) | Progression par arrêt. | 
**remise** | [**SecretsRemise**](SecretsRemise.md) | Code et QR de remise — **propriétaire seul** (R6). | 
**substitutionEnAttente** | [**SubstitutionSuivi**](SubstitutionSuivi.md) | Proposition de remplacement ouverte. | [optional] 
**totalUnites** | **int** | Total à payer. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


