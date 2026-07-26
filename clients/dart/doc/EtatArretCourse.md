# mefali_api_client.model.EtatArretCourse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**arretId** | **String** | Arrêt concerné. | 
**collectesFaites** | **int** | Arrêts effectivement COLLECTÉS (la remise n'en est pas une). | 
**collectesResolues** | **int** | Arrêts RÉSOLUS — collectés **ou** indisponibles. C'est ce compteur qui dit au coursier ce qui lui reste à faire : un étal fermé est fini, même s'il n'y a rien pris. | 
**collectesTotal** | **int** | Nombre total de COLLECTES de la course. | 
**commandeId** | **String** | Commande ancre. | 
**enLivraison** | **bool** | Vrai si la course vient de basculer EN_LIVRAISON. | 
**livraisonEtat** | **String** | État de la livraison : `assignee` | `en_collecte` | `en_livraison`. | 
**livraisonId** | **String** | Livraison porteuse. | 
**rejeu** | **bool** | Vrai si l'appel était un rejeu du même `uuid_client` : rien n'a été réécrit, aucun événement n'a été ré-émis. | 
**statut** | **String** | Statut de l'arrêt : `en_route` | `arrive` | `indisponible`. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


