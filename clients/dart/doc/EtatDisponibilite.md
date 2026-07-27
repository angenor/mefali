# mefali_api_client.model.EtatDisponibilite

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**capacites** | [**BuiltList&lt;CapaciteCoursier&gt;**](CapaciteCoursier.md) | Capacités déclarées au dossier coursier. | 
**dansLePool** | **bool** | Vrai seulement après une position publiée : l'intention ne suffit pas. | 
**devise** | **String** | Devise ISO 4217 de la zone. | 
**enLigne** | **bool** | Intention déclarée aujourd'hui. | 
**jour** | **String** | Jour civil de la déclaration. | 
**noteCentiemes** | **int** | Note du coursier, ou `null` tant qu'AVI n'existe pas. | [optional] 
**palierNoteCle** | **String** | Clé i18n du palier appliqué. | 
**periodePositionS** | **int** | Période de publication attendue (paramètre de zone du cycle 008). | 
**plafondDeclareUnites** | **int** | Plafond déclaré du jour, ou `null` si rien n'a été déclaré (FR-011 : jamais reporté — l'app le redemande au nouveau jour). | [optional] 
**plafondRetenuUnites** | **int** | Ce qui s'applique : `min(déclaré, palier de la grille)`. | 
**plafondSource** | **String** | `grille_note` | `declaration`. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


