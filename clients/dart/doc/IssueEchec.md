# mefali_api_client.model.IssueEchec

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande concernée. | 
**detenteurArgent** | **String** | Qui détient l'ARGENT. | 
**detenteurMarchandise** | **String** | Qui détient la MARCHANDISE — axe indépendant du précédent (R14). | 
**devise** | **String** | Devise ISO 4217. | 
**indemnisationDue** | **bool** | Le coursier doit être indemnisé (contrat CRS-06). | 
**issueId** | **String** | Identifiant de l'issue. | 
**litigeOuvert** | **bool** | Un litige est ouvert (contrat AVI-04). | 
**montantEnJeuUnites** | **int** | Montant en jeu (unités mineures). | 
**relivraisonId** | **String** | Commande de re-livraison créée (§7.5-10 seulement). | [optional] 
**sanction** | **String** | Sanction effectivement posée sur le compte client. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


