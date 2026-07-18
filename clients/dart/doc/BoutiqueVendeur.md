# mefali_api_client.model.BoutiqueVendeur

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**etatEffectif** | [**EtatEffectifBoutique**](EtatEffectifBoutique.md) | État EFFECTIF dérivé. | 
**horaires** | [**HorairesSemaineDto**](HorairesSemaineDto.md) | Horaires hebdomadaires. | 
**horairesDuJour** | [**BuiltList&lt;PlageDto&gt;**](PlageDto.md) | Plages du jour courant (fuseau de la zone). | 
**pauseFin** | [**DateTime**](DateTime.md) | Échéance de la pause en cours. | [optional] 
**rappelOuverture** | **bool** | FR-035 — rappel non bloquant à afficher (fermé manuel dans les horaires) ; « rester fermé » = fermer pour la journée, qui l'éteint. | 
**statut** | [**StatutBoutique**](StatutBoutique.md) | Statut DÉCLARÉ (l'effectif peut différer — FR-032). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


