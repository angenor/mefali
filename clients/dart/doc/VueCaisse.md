# mefali_api_client.model.VueCaisse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**avanceEnCoursUnites** | **int** | Argent avancé et non encore récupéré (FR-067) — toujours positif. | 
**avancesEnAttenteReglementUnites** | **int** | Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117). | 
**coursesConcernees** | **int** | Combien de courses portent cette avance. | 
**devise** | **String** | Devise ISO 4217 de la zone. | 
**ecartPlafond** | **bool** | Les avances en cours dépassent le plafond déclaré du jour (FR-078). | 
**historiqueDuJour** | [**BuiltList&lt;LigneHistoriqueCaisse&gt;**](LigneHistoriqueCaisse.md) | Historique du jour civil **de la zone**. | 
**indemnisations** | [**BuiltList&lt;IndemnisationVue&gt;**](IndemnisationVue.md) | Indemnisations rattachées. | 
**litigesEnCours** | [**BuiltList&lt;LitigeVu&gt;**](LitigeVu.md) | Litiges en cours — vide tant qu'AVI-04 n'existe pas. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


