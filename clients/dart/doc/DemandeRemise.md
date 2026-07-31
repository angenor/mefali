# mefali_api_client.model.DemandeRemise

## Load the model package
```dart
import 'package:mefali_api_client/api.dart';
```

## Properties
Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**code** | **String** | Code à 4 chiffres dicté par le client (mode `code`). | [optional] 
**confirmeLeLocal** | [**DateTime**](DateTime.md) | Horodatage de l'appareil. **Observation seulement**. | [optional] 
**depotLat** | **double** | Latitude du coursier au dépôt (mode `depot`, FR-048). | [optional] 
**depotLon** | **double** | Longitude du coursier au dépôt (mode `depot`, FR-048). | [optional] 
**essaisHorsLigne** | **int** | Essais faux consommés **hors ligne**, consolidés en `max()` côté serveur contre le seuil de zone `commande.essais_code_livraison` (R5). | [optional] 
**horsLigne** | **bool** | La validation a-t-elle eu lieu sans réseau ? Journalisé, jamais décisif — le serveur revalide la preuve ici même (FR-046). | [optional] 
**jeton** | **String** | Jeton lu dans le QR de réception (mode `qr`). | [optional] 
**mode** | **String** | `qr` | `code` | `depot`. | 
**photoCle** | **String** | Clé d'une photo **déjà** déposée (mode `depot`) — compatibilité du cycle 008 ; l'app coursier envoie la partie binaire `photo` (R18). | [optional] 
**uuidClient** | **String** | Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : sans elle, un rejeu de la file clôturait deux fois la même course (R4). | 

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)


