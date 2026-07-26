/// Orchestration du parcours de commande (cycle CMD 008, T067).
///
/// Le cycle a livré six écrans et leurs porteurs d'état ; il manquait ce qui
/// les relie au serveur. C'est ici — et **uniquement ici** — que les appels de
/// `CommandesApi` rencontrent `Panier`, `Confirmation`, `Suivi` et le cache
/// local. Les écrans, eux, ne connaissent que leurs callbacks.
///
/// Trois règles que ce fichier tient, et dont le reste du parcours dépend :
///
/// - **aucun message n'est composé ici** : les méthodes rendent le `code` du
///   refus, que l'écran passe à `messageErreurCommande` (constitution VII) ;
/// - **une panne réseau n'est pas un refus** : le devis bascule le panier en
///   « estimé » (C3-3c) et le suivi sur le dernier état connu (C4-4d), au lieu
///   d'annoncer une erreur que le serveur n'a jamais prononcée ;
/// - **la clé d'idempotence survit aux tentatives** : elle est générée une fois
///   et rejouée telle quelle, sinon un second appui sur « Commander » après un
///   timeout créerait une deuxième commande, donc une deuxième facturation (R7).
library;

import 'package:geolocator/geolocator.dart';
import 'package:mefali_core/mefali_core.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

import '../commande/etat_suivi.dart';
import '../panier/etat_confirmation.dart';
import '../panier/etat_panier.dart';

part 'actions_commande.g.dart';

/// Position GPS de l'appareil — **injectée par la PORTÉE** (constitution XII).
///
/// Un provider, et non un appel direct à `Geolocator` depuis l'écran : c'est ce
/// qui permet aux tests de servir un pin sans toucher au canal de plateforme
/// (FR-039). Rend `null` quand la permission est refusée ou le service coupé —
/// jamais une position inventée.
@Riverpod(keepAlive: true)
Future<({double lat, double lon})?> Function() positionAppareil(Ref ref) =>
    positionGeolocator;

/// Implémentation de production de [positionAppareilProvider].
Future<({double lat, double lon})?> positionGeolocator() async {
  try {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }
    final position = await Geolocator.getCurrentPosition();
    return (lat: position.latitude, lon: position.longitude);
  } catch (_) {
    // Service de localisation coupé, appareil sans GPS, délai dépassé : la
    // cliente pose son pin à la main. Aucune raison d'échouer le parcours.
    return null;
  }
}

/// Les actions du parcours de commande. `keepAlive` : la clé d'idempotence
/// qu'elle détient doit survivre à la navigation entre panier et confirmation.
@Riverpod(keepAlive: true)
ActionsCommande actionsCommande(Ref ref) => ActionsCommande(ref);

/// Résultat d'une confirmation : l'identifiant de la commande créée, ou le
/// `code` du refus. Jamais les deux, jamais aucun des deux.
typedef IssueConfirmation = ({String? commandeId, String? codeErreur});

/// Actions du parcours : devis, confirmation, suivi, annulation, appel,
/// décision de substitution.
class ActionsCommande {
  /// Construit les actions sur la portée qui les héberge.
  ActionsCommande(this._ref);

  final Ref _ref;

  String? _cleIdempotence;
  String? _cleAdresse;

  CommandesApi get _api => _ref.read(commandesApiProvider);

  CacheCommandes get _cache => _ref.read(cacheCommandesProvider);

  /// Clé d'idempotence de la commande en cours de composition (UUIDv7, R7).
  ///
  /// Générée à la PREMIÈRE demande et conservée : deux appuis sur « Commander »,
  /// ou un rejeu après un timeout, portent la MÊME clé et rendent la MÊME
  /// commande. Remise à zéro seulement quand la commande est créée.
  String get cleIdempotence => _cleIdempotence ??= const Uuid().v7();

  /// Le véhicule demandé — premier **transport actif de la zone** (`/config`),
  /// jamais une constante d'app : la liste est un référentiel de zone (ZON-03).
  /// `null` tant que la configuration n'a pas été chargée.
  Future<String?> transportDemande() async {
    final service = await _ref.read(serviceConfigProvider);
    final actifs = service.courante?.transportsActifs ?? const <String>[];
    return actifs.isEmpty ? null : actifs.first;
  }

  /// Pose le pin de livraison depuis le GPS de l'appareil. Rend `false` si la
  /// position n'a pas pu être obtenue — l'écran le dit alors, sans inventer.
  Future<bool> utiliserPositionActuelle() async {
    final position = await _ref.read(positionAppareilProvider)();
    if (position == null) return false;
    _ref.read(confirmationProvider.notifier).poserPin(position.lat, position.lon);
    return true;
  }

  /// Recalcule le devis du panier courant (`POST /paniers/devis`, CMD-01).
  ///
  /// Rend le `code` d'un refus, ou `null` si tout s'est bien passé — y compris
  /// hors ligne, où le panier reste composable avec des montants ESTIMÉS
  /// (C3-3c) : perdre le réseau n'est pas une erreur de la cliente.
  Future<String?> rafraichirDevis() async {
    final panier = _ref.read(panierProvider);
    if (panier.estVide) return null;

    final lieu = await _lieuCourant();
    if (lieu == null) return 'lieu_indisponible';

    final transport = await transportDemande();
    if (transport == null) return 'zone_indisponible';

    try {
      final json = await _api.devis(
        zoneId: panier.zoneId,
        categorieSlug: panier.categorieSlug,
        transportSlug: transport,
        lat: lieu.lat,
        lon: lieu.lon,
        lignes: [for (final l in panier.lignes) l.versJson()],
      );
      _ref.read(panierProvider.notifier).poserDevis(DevisPanierVue.depuisJson(json));
      return null;
    } catch (erreur) {
      if (estPanneReseau(erreur)) {
        _ref.read(panierProvider.notifier).marquerHorsLigne();
        return null;
      }
      return codeErreurApi(erreur);
    }
  }

  /// Crée la commande (`POST /commandes`, CMD-03), met le code et le QR en
  /// cache, et vide le panier.
  ///
  /// La mise en cache est faite AVANT de rendre la main : c'est elle qui rend
  /// le bloc « À la livraison » disponible sans réseau (SC-009), et le moment
  /// où le réseau est encore là est le seul où on peut l'écrire.
  /// `libelleAdresse` n'est utilisé que sur le chemin du repère VOCAL, qui crée
  /// une adresse de carnet : il vient de l'écran, donc du l10n — aucune chaîne
  /// utilisateur ne se compose ici (constitution VII).
  Future<IssueConfirmation> confirmer({required String libelleAdresse}) async {
    final panier = _ref.read(panierProvider);
    final saisie = _ref.read(confirmationProvider);
    if (panier.estVide) return (commandeId: null, codeErreur: 'panier_invalide');

    final transport = await transportDemande();
    if (transport == null) {
      return (commandeId: null, codeErreur: 'zone_indisponible');
    }

    final String? adresseId;
    try {
      adresseId = await _adresseDeLivraison(saisie, libelleAdresse);
    } catch (erreur) {
      return (commandeId: null, codeErreur: codeErreurApi(erreur));
    }
    // Sans adresse du carnet, le pin est obligatoire : le serveur refuserait
    // un lieu absent, autant ne pas partir.
    if (adresseId == null && (saisie.lat == null || saisie.lon == null)) {
      return (commandeId: null, codeErreur: 'lieu_indisponible');
    }

    try {
      final json = await _api.creer(
        idempotencyKey: cleIdempotence,
        zoneId: panier.zoneId,
        categorieSlug: panier.categorieSlug,
        transportSlug: transport,
        modePaiement: saisie.modePaiement,
        lignes: [for (final l in panier.lignes) l.versJson()],
        adresseId: adresseId,
        // Une adresse du carnet porte déjà son pin et son repère : les renvoyer
        // ferait diverger la commande de l'adresse qu'elle réutilise.
        lat: adresseId == null ? saisie.lat : null,
        lon: adresseId == null ? saisie.lon : null,
        repereTexte: adresseId == null ? saisie.repereTexte.trim() : null,
      );

      final creee = CommandeCreeeVue.depuisJson(json);
      await _cache.memoriser(
        commandeId: creee.id,
        etat: creee.etat,
        codeLivraison: creee.codeLivraison,
        jetonReception: creee.jetonReception,
        totalUnites: creee.totalUnites,
        devise: creee.devise,
        majLeLocal: DateTime.now(),
      );
      _ref.read(confirmationProvider.notifier).poserCommande(creee);
      _ref.read(panierProvider.notifier).vider();
      // La commande existe : la clé a fini son office. En garder une pour la
      // suivante ferait rendre CETTE commande au prochain « Commander ».
      _cleIdempotence = null;
      return (commandeId: creee.id, codeErreur: null);
    } catch (erreur) {
      return (commandeId: null, codeErreur: codeErreurApi(erreur));
    }
  }

  /// Charge le suivi d'une commande (`GET /commandes/{id}`, CMD-05), rafraîchit
  /// le cache, et **bascule sur le dernier état connu** si le réseau manque.
  ///
  /// C'est la fonction derrière `sourceSuiviProvider`. Sans réseau ET sans
  /// cache, elle relance : mieux vaut l'écran d'erreur qu'un suivi inventé.
  Future<EtatSuivi> chargerSuivi(String commandeId) async {
    try {
      final json = await _api.suivre(commandeId);
      final suivi = EtatSuivi.depuisJson(json);
      await _cache.memoriser(
        commandeId: suivi.commandeId,
        etat: suivi.etat,
        etatCle: suivi.etatCle,
        collectesFaites: suivi.collectesFaites,
        collectesTotal: suivi.collectesTotal,
        codeLivraison: suivi.codeLivraison,
        jetonReception: suivi.jetonReception,
        totalUnites: suivi.totalUnites,
        devise: suivi.devise,
        positionLat: suivi.position?.lat,
        positionLon: suivi.position?.lon,
        positionAgeS: suivi.position?.ageS,
        majLeLocal: DateTime.now(),
      );
      return suivi;
    } catch (erreur) {
      if (!estPanneReseau(erreur)) rethrow;
      final cache = await _cache.lire(commandeId);
      if (cache == null) rethrow;
      return EtatSuivi.depuisCache(cache);
    }
  }

  /// Les commandes du compte (`GET /moi/commandes`). Hors ligne, rend celles du
  /// cache local plutôt qu'une liste vide — une commande en cours ne disparaît
  /// pas parce que le réseau a sauté.
  Future<List<CommandeResumeeVue>> mesCommandes() async {
    try {
      final liste = await _api.mesCommandes();
      return [for (final c in liste) CommandeResumeeVue.depuisJson(c)];
    } catch (erreur) {
      if (!estPanneReseau(erreur)) rethrow;
      final cache = await _cache.toutes();
      return [for (final c in cache) CommandeResumeeVue.depuisCache(c)];
    }
  }

  /// Annule la commande (`POST /commandes/{id}/annuler`, CMD-07) et oublie son
  /// code de remise : il ne sert plus, il n'a pas à survivre sur l'appareil.
  Future<String?> annuler(String commandeId) async {
    try {
      await _api.annuler(commandeId);
      await _cache.oublier(commandeId);
      _ref.invalidate(suiviProvider(commandeId));
      return null;
    } catch (erreur) {
      return codeErreurApi(erreur);
    }
  }

  /// Journalise l'intention d'appeler le coursier (`POST /commandes/{id}/appel`,
  /// FR-041). Un échec ne bloque rien : la cliente appelle quand même.
  Future<void> signalerAppel(String commandeId) async {
    try {
      await _api.signalerAppel(commandeId);
    } catch (_) {
      // Métrique de friction, pas une action métier : elle ne mérite pas
      // d'interrompre un appel qu'on cherche justement à faciliter.
    }
  }

  /// Accepte ou refuse un remplacement (CMD-06), puis recharge le suivi pour
  /// que le total affiché soit celui que la décision vient de produire.
  Future<String?> deciderSubstitution({
    required String commandeId,
    required String substitutionId,
    required bool accepte,
  }) async {
    try {
      await _api.deciderSubstitution(
        commandeId: commandeId,
        substitutionId: substitutionId,
        accepte: accepte,
      );
      _ref.invalidate(suiviProvider(commandeId));
      return null;
    } catch (erreur) {
      return codeErreurApi(erreur);
    }
  }

  /// L'adresse sur laquelle commander, ou `null` pour commander sur le pin et
  /// le repère écrit.
  ///
  /// Un repère **VOCAL** impose le carnet : `POST /commandes` attend une clé S3
  /// que seule `POST /moi/adresses` sait produire (multipart). On enregistre
  /// donc l'adresse — ce que CPT-05 propose de toute façon après la livraison —
  /// et la commande s'appuie dessus. La clé d'idempotence de cette adresse est
  /// distincte de celle de la commande et rejouée à l'identique : deux
  /// tentatives ne laissent pas deux adresses jumelles.
  Future<String?> _adresseDeLivraison(
    EtatConfirmation saisie,
    String libelle,
  ) async {
    if (saisie.adresseId != null) return saisie.adresseId;
    final note = saisie.noteVocale;
    if (saisie.mode != ModeRepere.vocal || note == null) return null;

    final lat = saisie.lat;
    final lon = saisie.lon;
    if (lat == null || lon == null) return null;

    final adresseId = await _ref.read(adressesApiProvider).enregistrer(
          idempotencyKey: _cleAdresse ??= const Uuid().v7(),
          lat: lat,
          lon: lon,
          libelle: libelle,
          note: note,
        );
    // La saisie retient l'adresse : un second appui sur « Commander » ne
    // re-téléverse pas la note, il réutilise l'adresse déjà créée.
    _ref.read(confirmationProvider.notifier).reutiliser(
          adresseId: adresseId,
          lat: lat,
          lon: lon,
          noteVocale: note,
        );
    return adresseId;
  }

  /// Le pin de livraison : celui déjà saisi, sinon le GPS. `null` si aucun des
  /// deux n'est disponible — le devis ne part pas sans destination.
  Future<({double lat, double lon})?> _lieuCourant() async {
    final saisie = _ref.read(confirmationProvider);
    final lat = saisie.lat;
    final lon = saisie.lon;
    if (lat != null && lon != null) return (lat: lat, lon: lon);
    return _ref.read(positionAppareilProvider)();
  }
}

/// Une commande de la liste d'accueil, réduite à ce qu'elle affiche.
class CommandeResumeeVue {
  /// Crée la vue d'une commande résumée.
  const CommandeResumeeVue({
    required this.id,
    required this.etat,
    required this.etatCle,
    required this.totalUnites,
    required this.devise,
    required this.nbVendeurs,
  });

  /// Construit la vue depuis un élément de `GET /moi/commandes`.
  factory CommandeResumeeVue.depuisJson(Map<String, Object?> json) =>
      CommandeResumeeVue(
        id: json['id']! as String,
        etat: json['etat']! as String,
        etatCle: json['etat_cle']! as String,
        totalUnites: json['total_unites']! as int,
        devise: json['devise']! as String,
        nbVendeurs: json['nb_vendeurs']! as int,
      );

  /// Reconstruit depuis le cache local — le nombre de vendeurs n'y est pas
  /// stocké : hors ligne on l'omet plutôt que d'afficher un chiffre faux.
  factory CommandeResumeeVue.depuisCache(CommandeCache cache) =>
      CommandeResumeeVue(
        id: cache.commandeId,
        etat: cache.etat,
        etatCle: cache.etatCle,
        totalUnites: cache.totalUnites,
        devise: cache.devise,
        nbVendeurs: 0,
      );

  /// Commande.
  final String id;

  /// État de très haut niveau.
  final String etat;

  /// Clé i18n de l'état.
  final String etatCle;

  /// Total à régler.
  final int totalUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Nombre de vendeurs (0 quand la vue vient du cache).
  final int nbVendeurs;

  /// La commande est encore en cours : elle mène au suivi.
  bool get enCours =>
      etat != 'terminee' && etat != 'annulee' && etat != 'echouee';
}
