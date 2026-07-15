# mefali_api_client.model.DossierCoursierAdmin

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**compteId** | **String** | Compte du coursier. | 
**motif** | **String** | Motif de la dernière décision admin. | [optional] 
**pieceUrl** | **String** | URL présignée de la pièce (TTL 10 min) — DÉTAIL uniquement, absente en liste : présigner N pièces pour un tableau serait du gaspillage, et autant de liens vivants qu'aucun œil n'ouvrira. | [optional] 
**referentNom** | **String** | Référent local. | 
**referentTelephoneE164** | **String** | Téléphone du référent. | 
**soumisLe** | [**DateTime**](DateTime.md) | Dernier dépôt. | 
**statut** | **String** | Statut = celui de l'attribution `coursier`. | 
**telephoneE164** | **String** | Numéro du coursier — l'admin doit pouvoir le rappeler (FR-017). | 
**vehicules** | [**BuiltList&lt;VehiculeDeclare&gt;**](VehiculeDeclare.md) | Véhicules déclarés. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


