# mefali_api_client.model.ArretCourse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt de la course. | 
**arriveLe** | [**DateTime**](DateTime.md) | Arrivée sur l'arrêt. | [optional] 
**collecteLe** | [**DateTime**](DateTime.md) | Collecte validée. | [optional] 
**distanceMaxM** | **int** | Rayon max de scan (m). | 
**distancePrecedentM** | **int** | Distance depuis l'arrêt précédent (m). **Absente** : le tronçon n'est pas figé au devis et ce cycle ne recalcule aucun itinéraire (FR-009). | [optional] 
**empreinteCode** | **String** | base16(sha256(prestataire ‖ code)) — mode dégradé hors-ligne. | 
**empreinteJeton** | **String** | base16(sha256(jeton)) — match hors-ligne du QR de plaque. | 
**enRouteLe** | [**DateTime**](DateTime.md) | Départ déclaré vers l'arrêt. | [optional] 
**lignes** | [**BuiltList&lt;LigneArret&gt;**](LigneArret.md) | Articles à acheter chez ce vendeur. | 
**montantAvance** | **int** | Montant à avancer à CE vendeur, lignes retirées exclues (FR-013). | 
**nom** | **String** | Nom du vendeur. | 
**ordre** | **int** | Rang dans l'ordre optimisé. | 
**photoExigee** | **bool** | Photo de récupération exigée (politique résolue). | 
**prestataireId** | **String** | Prestataire visé. | 
**siteLat** | **double** | Position attendue du site. | 
**siteLon** | **double** | Position attendue du site. | 
**statut** | **String** | `a_collecter` | `en_route` | `arrive` | `collecte` | `indisponible`. | 
**telephoneVendeur** | **String** | Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé. | [optional] 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


