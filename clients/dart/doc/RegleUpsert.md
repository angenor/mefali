# mefali_api_client.model.RegleUpsert

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**actif** | **bool** | Règle active à l'évaluation. | 
**categorieSlug** | **String** | Slug de catégorie, `null` = toutes catégories. | [optional] 
**devise** | **String** | Devise ISO 4217 — DOIT égaler celle de la zone (FR-023). | 
**distanceMaxM** | **int** | Borne haute INCLUSE, `null` = +∞. | [optional] 
**distanceMinM** | **int** | Borne basse de la tranche de distance routière (mètres). | 
**joursMasque** | **int** | Masque de jours (bit 0 = lundi … bit 6 = dimanche), `null` = tous. | [optional] 
**marge** | **int** | Marge Mefali — DOIT être dans les bornes de la zone (FR-009). | 
**partCoursierBase** | **int** | Part coursier de base (unités mineures). | 
**plageDebutMin** | **int** | Début de plage horaire (minutes depuis minuit, fuseau de la zone). | [optional] 
**plageFinMin** | **int** | Fin de plage horaire (exclue). | [optional] 
**priorite** | **int** | Priorité de départage. | 
**prixParKm** | **int** | Prix par kilomètre au-delà du seuil (abonde client ET coursier). | 
**prixPlafond** | **int** | Plafond du prix client, `null` = aucun. | [optional] 
**seuilKmM** | **int** | Seuil (mètres) au-delà duquel le kilométrage est facturé. | 
**transportSlug** | **String** | Slug du véhicule (référentiel `zones.type_transport`). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


