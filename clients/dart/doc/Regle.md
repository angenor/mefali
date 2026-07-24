# mefali_api_client.model.Regle

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**actif** | **bool** | Active. | 
**categorieSlug** | **String** | Catégorie, `null` = toutes. | [optional] 
**devise** | **String** | Devise ISO 4217. | 
**distanceMaxM** | **int** | Borne haute incluse. | [optional] 
**distanceMinM** | **int** | Borne basse de tranche (mètres). | 
**id** | **String** | Identifiant. | 
**joursMasque** | **int** | Masque de jours. | [optional] 
**marge** | **int** | Marge Mefali. | 
**partCoursierBase** | **int** | Part coursier de base. | 
**plageDebutMin** | **int** | Début de plage horaire. | [optional] 
**plageFinMin** | **int** | Fin de plage horaire. | [optional] 
**priorite** | **int** | Priorité. | 
**prixClientBase** | **int** | Prix client de base DÉRIVÉ (`part_coursier_base + marge`) — jamais stocké, servi pour que l'admin lise le tarif sans le recalculer. | 
**prixParKm** | **int** | Prix par km au-delà du seuil. | 
**prixPlafond** | **int** | Plafond du prix client. | [optional] 
**seuilKmM** | **int** | Seuil de kilométrage facturé (mètres). | 
**transportSlug** | **String** | Véhicule. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


