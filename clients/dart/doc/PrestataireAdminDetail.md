# mefali_api_client.model.PrestataireAdminDetail

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**categorie** | **String** | Slug de la catégorie de service. | 
**commandable** | **bool** | FR-028, dérivé à la lecture. | 
**contactTelephone** | **String** | Contact téléphonique — surface ADMIN uniquement. | 
**delaiPreparationMin** | **int** | Délai de préparation (minutes). | 
**id** | **String** | Identifiant. | 
**nom** | **String** | Nom public. | 
**statut** | [**StatutPrestataire**](StatutPrestataire.md) | Cycle de vie. | 
**villeId** | **String** | Ville de rattachement. | 
**chartes** | [**BuiltList&lt;CharteAdminDto&gt;**](CharteAdminDto.md) | Chartes déposées, la plus récente d'abord. | 
**codeSecours** | **String** | Code de secours — AUCUNE recherche par ce code n'existe (FR-014). | [optional] 
**jetonPlaque** | **String** | Jeton de plaque (posé au premier agrément, stable — FR-013). | [optional] 
**photos** | [**BuiltList&lt;PhotoAdminDto&gt;**](PhotoAdminDto.md) | Photos présignées. | 
**rattachements** | [**BuiltList&lt;RattachementDto&gt;**](RattachementDto.md) | Comptes rattachés. | 
**site** | [**SiteAdminVueDto**](SiteAdminVueDto.md) | LE site unique, s'il est créé. | [optional] 
**statutDecideLe** | [**DateTime**](DateTime.md) | Horodatage de la dernière décision. | [optional] 
**statutDecidePar** | **String** | Auteur de la dernière décision de cycle de vie. | [optional] 
**statutMotif** | **String** | Motif de la dernière décision (suspension). | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


