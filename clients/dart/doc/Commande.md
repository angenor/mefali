# mefali_api_client.model.Commande

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | État de très haut niveau. | 
**id** | **String** | Identifiant (= `Idempotency-Key`). | 
**livraison** | [**LivraisonCommande**](LivraisonCommande.md) | Livraison, si la commande en a une — **composant 0..n du tronc**.  Optionnel comme `SuiviCommande.livraison_id` l'est déjà : le tronc ne porte aucun champ logistique, et `creer_relivraison` crée bel et bien une commande sans livraison. L'exiger ici était un oubli, pas un choix. Tous les verticaux du MVP en créent exactement une : la valeur reste donc toujours renseignée aujourd'hui. | [optional] 
**montantArticlesUnites** | **int** | Montant des articles. | 
**paiement** | [**PaiementCommande**](PaiementCommande.md) | Paiement. | 
**remise** | [**SecretsRemise**](SecretsRemise.md) | Code et jeton de remise. | 
**totalUnites** | **int** | Total à payer. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


