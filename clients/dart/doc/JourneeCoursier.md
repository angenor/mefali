# mefali_api_client.model.JourneeCoursier

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**avancesEnCoursUnites** | **int** | Argent encore dehors, à l'origine de l'amputation ci-dessus. | 
**coursesLivrees** | **int** | Courses dont la remise est validée dans le jour civil **de la zone**. | 
**devise** | **String** | Devise ISO 4217. | 
**gainsUnites** | **int** | Somme des parts coursier de ces courses (devis FIGÉ du cycle 007). | 
**noteCentiemes** | **int** | **Toujours `null`** tant qu'AVI n'est pas construit (FR-094) : l'absence vaut mieux qu'un chiffre inventé. | [optional] 
**plafondRetenuUnites** | **int** | Plafond d'avance qui s'applique — `min(déclaré, palier de la grille)`. | 
**resteDisponibleUnites** | **int** | Ce qu'il reste engageable : plafond retenu **moins** avances en cours (FR-095). Jamais négatif — un « reste » négatif ne veut rien dire à l'écran ; l'écart, lui, est signalé par la caisse (FR-078). | 
**tauxAcceptationPourcent** | **int** | Taux d'acceptation tenu par le dispatch, ou `null` si aucune offre décidable n'a été émise sur la fenêtre (FR-093). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


