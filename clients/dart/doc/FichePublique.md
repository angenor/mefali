# mefali_api_client.model.FichePublique

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**affichageRupture** | [**AffichageRupture**](AffichageRupture.md) | Mode de rendu des ruptures, résolu pour la catégorie. | 
**articles** | [**BuiltList&lt;ArticlePublic&gt;**](ArticlePublic.md) | Catalogue servi (retirés absents ; ruptures selon le mode). | 
**boutique** | [**EtatEffectifBoutique**](EtatEffectifBoutique.md) | État effectif de la boutique. | 
**categorie** | **String** | Slug de la catégorie de service. | 
**commandable** | **bool** | FR-028 — la SEULE définition de « commandable ». | 
**delaiPreparationMin** | **int** | Délai de préparation moyen déclaré (minutes). | 
**horaires** | [**HorairesSemaineDto**](HorairesSemaineDto.md) | Horaires hebdomadaires. | 
**id** | **String** | Identifiant du prestataire. | 
**nom** | **String** | Nom public. | 
**photos** | **BuiltList&lt;String&gt;** | URLs présignées des photos de fiche. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


