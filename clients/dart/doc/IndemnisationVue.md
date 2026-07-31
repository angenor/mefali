# mefali_api_client.model.IndemnisationVue

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**commandeId** | **String** | Commande d'origine. | 
**commandeReference** | **String** | Référence lisible de la commande. | 
**creeLe** | [**DateTime**](DateTime.md) | Naissance de la demande. | 
**decideLe** | [**DateTime**](DateTime.md) | Quand la décision a été prise. | [optional] 
**decisionMotifCle** | **String** | Clé i18n du motif de décision (refus surtout). | [optional] 
**devise** | **String** | Devise ISO 4217. | 
**etat** | **String** | `demandee` | `validee` | `refusee`. | 
**id** | **String** | Indemnisation. | 
**litigeId** | **String** | Litige rattaché — **absent** tant qu'AVI-04 n'existe pas (R16). | [optional] 
**montantUnites** | **int** | Montant (unités mineures, positif). | 
**motifCle** | **String** | Clé i18n du motif. | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


