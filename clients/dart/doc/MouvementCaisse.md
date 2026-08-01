# mefali_api_client.model.MouvementCaisse

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande concernée — `null` pour un règlement ou un reversement, qui portent sur un solde et non sur une course. | [optional] 
**entree** | **bool** | Vrai si l'argent entre dans la poche du coursier. | 
**heure** | [**DateTime**](DateTime.md) | Horodatage serveur de l'écriture. | 
**id** | **String** | Écriture. | 
**montantUnites** | **int** | Montant **signé** : négatif quand l'argent sort de la poche.  L'app dérive « entrée » ou « sortie » de ce SIGNE, jamais d'une table de types recopiée — une table qui divergerait le jour où une nature changerait de sens. | 
**reference** | **String** | Référence lisible de la commande, quand il y en a une. | [optional] 
**typeEcriture** | **String** | Nature : `avance` | `remboursement` | `indemnisation` | `correction` | `frais_encaisses` | `reglement` | `reversement`. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


