# mefali_api_client.model.ClientCourse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**depotAutorise** | **bool** | La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ? | 
**lieuLat** | **double** | Point de livraison. | [optional] 
**lieuLon** | **double** | Point de livraison. | [optional] 
**nomUsage** | **String** | Nom d'usage. **Absent** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — l'app affiche le repère. | [optional] 
**repereTexte** | **String** | Repère écrit. | [optional] 
**repereVocalDureeS** | **int** | Durée de la note vocale (s). | [optional] 
**repereVocalUrl** | **String** | URL **présignée** de la note vocale — à télécharger tout de suite pour la jouer hors ligne (FR-024). | [optional] 
**telephone** | **String** | Contact du client. Jamais journalisé, effacé du cache à la clôture (R6). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


