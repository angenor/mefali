# mefali_api_client.model.SessionPaiement

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**accesPaiement** | **String** | Page de paiement à ouvrir dans le **navigateur système**.  `null` dès que l'état quitte `ouverte` : la colonne est effacée à l'issue, et un accès d'encaissement survivant à son paiement est une surface d'attaque sans usage (FR-006). | [optional] 
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | État : `ouverte` | `reglee` | `echouee` | `expiree` | `payee_hors_delai`. | 
**expireLe** | [**DateTime**](DateTime.md) | Échéance **persistée**, calculée depuis `paiement.session_duree_s`. | 
**montantUnites** | **int** | Montant **figé** à l'ouverture (unités mineures). | 
**moyen** | **String** | Moyen effectivement employé, tel que le fournisseur l'a dit. `inconnu` tant qu'il ne l'a pas dit — jamais deviné (FR-012). | 
**restantS** | **int** | Secondes restantes, **calculées côté serveur** (FR-017).  L'horloge de l'app ne décide de rien : elle affiche un compte à rebours qu'elle recale sur cette valeur à chaque lecture. Vaut `0` sur une session échue, jamais un nombre négatif. | 
**transactionId** | **String** | Transaction de paiement. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


