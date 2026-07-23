# mefali_api_client.model.ArretPreProvisionne

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt à collecter. | 
**devise** | **String** | Devise ISO 4217. | 
**distanceMaxM** | **int** | Rayon max de scan (m) — validation de proximité hors-ligne. | 
**empreinteCode** | **String** | base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne. | 
**empreinteJeton** | **String** | base16(sha256(jeton)) — match hors-ligne du QR scanné. | 
**montantAvance** | **int** | Montant avancé (unités mineures). | 
**nom** | **String** | Nom du prestataire (affiché sur la carte K3). | 
**photoExigee** | **bool** | Photo exigée (politique résolue). | 
**prestataireId** | **String** | Prestataire visé. | 
**siteLat** | **double** | Position attendue du site. | 
**siteLon** | **double** | Position attendue du site. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


