// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_en_attente.dart';

// ignore_for_file: type=lint
class $ActionsEnAttenteTable extends ActionsEnAttente
    with TableInfo<$ActionsEnAttenteTable, ActionEnAttente> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ActionsEnAttenteTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uuidClientMeta = const VerificationMeta(
    'uuidClient',
  );
  @override
  late final GeneratedColumn<String> uuidClient = GeneratedColumn<String>(
    'uuid_client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endpointMeta = const VerificationMeta(
    'endpoint',
  );
  @override
  late final GeneratedColumn<String> endpoint = GeneratedColumn<String>(
    'endpoint',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _methodeMeta = const VerificationMeta(
    'methode',
  );
  @override
  late final GeneratedColumn<String> methode = GeneratedColumn<String>(
    'methode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('POST'),
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoOctetsMeta = const VerificationMeta(
    'photoOctets',
  );
  @override
  late final GeneratedColumn<Uint8List> photoOctets =
      GeneratedColumn<Uint8List>(
        'photo_octets',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _creeLeLocalMeta = const VerificationMeta(
    'creeLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> creeLeLocal = GeneratedColumn<DateTime>(
    'cree_le_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tentativesMeta = const VerificationMeta(
    'tentatives',
  );
  @override
  late final GeneratedColumn<int> tentatives = GeneratedColumn<int>(
    'tentatives',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dernierMotifMeta = const VerificationMeta(
    'dernierMotif',
  );
  @override
  late final GeneratedColumn<String> dernierMotif = GeneratedColumn<String>(
    'dernier_motif',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuidClient,
    endpoint,
    methode,
    payloadJson,
    photoOctets,
    creeLeLocal,
    tentatives,
    dernierMotif,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'actions_en_attente';
  @override
  VerificationContext validateIntegrity(
    Insertable<ActionEnAttente> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid_client')) {
      context.handle(
        _uuidClientMeta,
        uuidClient.isAcceptableOrUnknown(data['uuid_client']!, _uuidClientMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidClientMeta);
    }
    if (data.containsKey('endpoint')) {
      context.handle(
        _endpointMeta,
        endpoint.isAcceptableOrUnknown(data['endpoint']!, _endpointMeta),
      );
    } else if (isInserting) {
      context.missing(_endpointMeta);
    }
    if (data.containsKey('methode')) {
      context.handle(
        _methodeMeta,
        methode.isAcceptableOrUnknown(data['methode']!, _methodeMeta),
      );
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('photo_octets')) {
      context.handle(
        _photoOctetsMeta,
        photoOctets.isAcceptableOrUnknown(
          data['photo_octets']!,
          _photoOctetsMeta,
        ),
      );
    }
    if (data.containsKey('cree_le_local')) {
      context.handle(
        _creeLeLocalMeta,
        creeLeLocal.isAcceptableOrUnknown(
          data['cree_le_local']!,
          _creeLeLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_creeLeLocalMeta);
    }
    if (data.containsKey('tentatives')) {
      context.handle(
        _tentativesMeta,
        tentatives.isAcceptableOrUnknown(data['tentatives']!, _tentativesMeta),
      );
    }
    if (data.containsKey('dernier_motif')) {
      context.handle(
        _dernierMotifMeta,
        dernierMotif.isAcceptableOrUnknown(
          data['dernier_motif']!,
          _dernierMotifMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuidClient};
  @override
  ActionEnAttente map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ActionEnAttente(
      uuidClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid_client'],
      )!,
      endpoint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}endpoint'],
      )!,
      methode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}methode'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      photoOctets: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}photo_octets'],
      ),
      creeLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}cree_le_local'],
      )!,
      tentatives: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tentatives'],
      )!,
      dernierMotif: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dernier_motif'],
      ),
    );
  }

  @override
  $ActionsEnAttenteTable createAlias(String alias) {
    return $ActionsEnAttenteTable(attachedDatabase, alias);
  }
}

class ActionEnAttente extends DataClass implements Insertable<ActionEnAttente> {
  /// Clé d'idempotence (UUIDv7) générée à l'action — PK.
  final String uuidClient;

  /// Endpoint cible (ex. `/courses/arrets/{id}/collecte`).
  final String endpoint;

  /// Méthode HTTP (MVP : `POST`).
  final String methode;

  /// Corps JSON sérialisé de la demande.
  final String payloadJson;

  /// Photo de récupération (si exigée) — octets bruts, facultatif.
  final Uint8List? photoOctets;

  /// Horodatage LOCAL de création (journalisé, jamais fait autorité).
  final DateTime creeLeLocal;

  /// Nombre de tentatives de rejeu.
  final int tentatives;

  /// Dernier motif d'échec (clé i18n ou message serveur), le cas échéant.
  final String? dernierMotif;
  const ActionEnAttente({
    required this.uuidClient,
    required this.endpoint,
    required this.methode,
    required this.payloadJson,
    this.photoOctets,
    required this.creeLeLocal,
    required this.tentatives,
    this.dernierMotif,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid_client'] = Variable<String>(uuidClient);
    map['endpoint'] = Variable<String>(endpoint);
    map['methode'] = Variable<String>(methode);
    map['payload_json'] = Variable<String>(payloadJson);
    if (!nullToAbsent || photoOctets != null) {
      map['photo_octets'] = Variable<Uint8List>(photoOctets);
    }
    map['cree_le_local'] = Variable<DateTime>(creeLeLocal);
    map['tentatives'] = Variable<int>(tentatives);
    if (!nullToAbsent || dernierMotif != null) {
      map['dernier_motif'] = Variable<String>(dernierMotif);
    }
    return map;
  }

  ActionsEnAttenteCompanion toCompanion(bool nullToAbsent) {
    return ActionsEnAttenteCompanion(
      uuidClient: Value(uuidClient),
      endpoint: Value(endpoint),
      methode: Value(methode),
      payloadJson: Value(payloadJson),
      photoOctets: photoOctets == null && nullToAbsent
          ? const Value.absent()
          : Value(photoOctets),
      creeLeLocal: Value(creeLeLocal),
      tentatives: Value(tentatives),
      dernierMotif: dernierMotif == null && nullToAbsent
          ? const Value.absent()
          : Value(dernierMotif),
    );
  }

  factory ActionEnAttente.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ActionEnAttente(
      uuidClient: serializer.fromJson<String>(json['uuidClient']),
      endpoint: serializer.fromJson<String>(json['endpoint']),
      methode: serializer.fromJson<String>(json['methode']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      photoOctets: serializer.fromJson<Uint8List?>(json['photoOctets']),
      creeLeLocal: serializer.fromJson<DateTime>(json['creeLeLocal']),
      tentatives: serializer.fromJson<int>(json['tentatives']),
      dernierMotif: serializer.fromJson<String?>(json['dernierMotif']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuidClient': serializer.toJson<String>(uuidClient),
      'endpoint': serializer.toJson<String>(endpoint),
      'methode': serializer.toJson<String>(methode),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'photoOctets': serializer.toJson<Uint8List?>(photoOctets),
      'creeLeLocal': serializer.toJson<DateTime>(creeLeLocal),
      'tentatives': serializer.toJson<int>(tentatives),
      'dernierMotif': serializer.toJson<String?>(dernierMotif),
    };
  }

  ActionEnAttente copyWith({
    String? uuidClient,
    String? endpoint,
    String? methode,
    String? payloadJson,
    Value<Uint8List?> photoOctets = const Value.absent(),
    DateTime? creeLeLocal,
    int? tentatives,
    Value<String?> dernierMotif = const Value.absent(),
  }) => ActionEnAttente(
    uuidClient: uuidClient ?? this.uuidClient,
    endpoint: endpoint ?? this.endpoint,
    methode: methode ?? this.methode,
    payloadJson: payloadJson ?? this.payloadJson,
    photoOctets: photoOctets.present ? photoOctets.value : this.photoOctets,
    creeLeLocal: creeLeLocal ?? this.creeLeLocal,
    tentatives: tentatives ?? this.tentatives,
    dernierMotif: dernierMotif.present ? dernierMotif.value : this.dernierMotif,
  );
  ActionEnAttente copyWithCompanion(ActionsEnAttenteCompanion data) {
    return ActionEnAttente(
      uuidClient: data.uuidClient.present
          ? data.uuidClient.value
          : this.uuidClient,
      endpoint: data.endpoint.present ? data.endpoint.value : this.endpoint,
      methode: data.methode.present ? data.methode.value : this.methode,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      photoOctets: data.photoOctets.present
          ? data.photoOctets.value
          : this.photoOctets,
      creeLeLocal: data.creeLeLocal.present
          ? data.creeLeLocal.value
          : this.creeLeLocal,
      tentatives: data.tentatives.present
          ? data.tentatives.value
          : this.tentatives,
      dernierMotif: data.dernierMotif.present
          ? data.dernierMotif.value
          : this.dernierMotif,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ActionEnAttente(')
          ..write('uuidClient: $uuidClient, ')
          ..write('endpoint: $endpoint, ')
          ..write('methode: $methode, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('photoOctets: $photoOctets, ')
          ..write('creeLeLocal: $creeLeLocal, ')
          ..write('tentatives: $tentatives, ')
          ..write('dernierMotif: $dernierMotif')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuidClient,
    endpoint,
    methode,
    payloadJson,
    $driftBlobEquality.hash(photoOctets),
    creeLeLocal,
    tentatives,
    dernierMotif,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ActionEnAttente &&
          other.uuidClient == this.uuidClient &&
          other.endpoint == this.endpoint &&
          other.methode == this.methode &&
          other.payloadJson == this.payloadJson &&
          $driftBlobEquality.equals(other.photoOctets, this.photoOctets) &&
          other.creeLeLocal == this.creeLeLocal &&
          other.tentatives == this.tentatives &&
          other.dernierMotif == this.dernierMotif);
}

class ActionsEnAttenteCompanion extends UpdateCompanion<ActionEnAttente> {
  final Value<String> uuidClient;
  final Value<String> endpoint;
  final Value<String> methode;
  final Value<String> payloadJson;
  final Value<Uint8List?> photoOctets;
  final Value<DateTime> creeLeLocal;
  final Value<int> tentatives;
  final Value<String?> dernierMotif;
  final Value<int> rowid;
  const ActionsEnAttenteCompanion({
    this.uuidClient = const Value.absent(),
    this.endpoint = const Value.absent(),
    this.methode = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.photoOctets = const Value.absent(),
    this.creeLeLocal = const Value.absent(),
    this.tentatives = const Value.absent(),
    this.dernierMotif = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ActionsEnAttenteCompanion.insert({
    required String uuidClient,
    required String endpoint,
    this.methode = const Value.absent(),
    required String payloadJson,
    this.photoOctets = const Value.absent(),
    required DateTime creeLeLocal,
    this.tentatives = const Value.absent(),
    this.dernierMotif = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuidClient = Value(uuidClient),
       endpoint = Value(endpoint),
       payloadJson = Value(payloadJson),
       creeLeLocal = Value(creeLeLocal);
  static Insertable<ActionEnAttente> custom({
    Expression<String>? uuidClient,
    Expression<String>? endpoint,
    Expression<String>? methode,
    Expression<String>? payloadJson,
    Expression<Uint8List>? photoOctets,
    Expression<DateTime>? creeLeLocal,
    Expression<int>? tentatives,
    Expression<String>? dernierMotif,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuidClient != null) 'uuid_client': uuidClient,
      if (endpoint != null) 'endpoint': endpoint,
      if (methode != null) 'methode': methode,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (photoOctets != null) 'photo_octets': photoOctets,
      if (creeLeLocal != null) 'cree_le_local': creeLeLocal,
      if (tentatives != null) 'tentatives': tentatives,
      if (dernierMotif != null) 'dernier_motif': dernierMotif,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ActionsEnAttenteCompanion copyWith({
    Value<String>? uuidClient,
    Value<String>? endpoint,
    Value<String>? methode,
    Value<String>? payloadJson,
    Value<Uint8List?>? photoOctets,
    Value<DateTime>? creeLeLocal,
    Value<int>? tentatives,
    Value<String?>? dernierMotif,
    Value<int>? rowid,
  }) {
    return ActionsEnAttenteCompanion(
      uuidClient: uuidClient ?? this.uuidClient,
      endpoint: endpoint ?? this.endpoint,
      methode: methode ?? this.methode,
      payloadJson: payloadJson ?? this.payloadJson,
      photoOctets: photoOctets ?? this.photoOctets,
      creeLeLocal: creeLeLocal ?? this.creeLeLocal,
      tentatives: tentatives ?? this.tentatives,
      dernierMotif: dernierMotif ?? this.dernierMotif,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuidClient.present) {
      map['uuid_client'] = Variable<String>(uuidClient.value);
    }
    if (endpoint.present) {
      map['endpoint'] = Variable<String>(endpoint.value);
    }
    if (methode.present) {
      map['methode'] = Variable<String>(methode.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (photoOctets.present) {
      map['photo_octets'] = Variable<Uint8List>(photoOctets.value);
    }
    if (creeLeLocal.present) {
      map['cree_le_local'] = Variable<DateTime>(creeLeLocal.value);
    }
    if (tentatives.present) {
      map['tentatives'] = Variable<int>(tentatives.value);
    }
    if (dernierMotif.present) {
      map['dernier_motif'] = Variable<String>(dernierMotif.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ActionsEnAttenteCompanion(')
          ..write('uuidClient: $uuidClient, ')
          ..write('endpoint: $endpoint, ')
          ..write('methode: $methode, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('photoOctets: $photoOctets, ')
          ..write('creeLeLocal: $creeLeLocal, ')
          ..write('tentatives: $tentatives, ')
          ..write('dernierMotif: $dernierMotif, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ArretsPreprovisionnesTable extends ArretsPreprovisionnes
    with TableInfo<$ArretsPreprovisionnesTable, ArretPreprovisionne> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArretsPreprovisionnesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _arretIdMeta = const VerificationMeta(
    'arretId',
  );
  @override
  late final GeneratedColumn<String> arretId = GeneratedColumn<String>(
    'arret_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _prestataireIdMeta = const VerificationMeta(
    'prestataireId',
  );
  @override
  late final GeneratedColumn<String> prestataireId = GeneratedColumn<String>(
    'prestataire_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nomMeta = const VerificationMeta('nom');
  @override
  late final GeneratedColumn<String> nom = GeneratedColumn<String>(
    'nom',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _empreinteJetonMeta = const VerificationMeta(
    'empreinteJeton',
  );
  @override
  late final GeneratedColumn<String> empreinteJeton = GeneratedColumn<String>(
    'empreinte_jeton',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _empreinteCodeMeta = const VerificationMeta(
    'empreinteCode',
  );
  @override
  late final GeneratedColumn<String> empreinteCode = GeneratedColumn<String>(
    'empreinte_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteLatMeta = const VerificationMeta(
    'siteLat',
  );
  @override
  late final GeneratedColumn<double> siteLat = GeneratedColumn<double>(
    'site_lat',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _siteLonMeta = const VerificationMeta(
    'siteLon',
  );
  @override
  late final GeneratedColumn<double> siteLon = GeneratedColumn<double>(
    'site_lon',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantAvanceMeta = const VerificationMeta(
    'montantAvance',
  );
  @override
  late final GeneratedColumn<int> montantAvance = GeneratedColumn<int>(
    'montant_avance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deviseMeta = const VerificationMeta('devise');
  @override
  late final GeneratedColumn<String> devise = GeneratedColumn<String>(
    'devise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoExigeeMeta = const VerificationMeta(
    'photoExigee',
  );
  @override
  late final GeneratedColumn<bool> photoExigee = GeneratedColumn<bool>(
    'photo_exigee',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("photo_exigee" IN (0, 1))',
    ),
  );
  static const VerificationMeta _distanceMaxMMeta = const VerificationMeta(
    'distanceMaxM',
  );
  @override
  late final GeneratedColumn<int> distanceMaxM = GeneratedColumn<int>(
    'distance_max_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(100),
  );
  static const VerificationMeta _statutLocalMeta = const VerificationMeta(
    'statutLocal',
  );
  @override
  late final GeneratedColumn<String> statutLocal = GeneratedColumn<String>(
    'statut_local',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('a_collecter'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    arretId,
    prestataireId,
    nom,
    empreinteJeton,
    empreinteCode,
    siteLat,
    siteLon,
    montantAvance,
    devise,
    photoExigee,
    distanceMaxM,
    statutLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arrets_preprovisionnes';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArretPreprovisionne> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('arret_id')) {
      context.handle(
        _arretIdMeta,
        arretId.isAcceptableOrUnknown(data['arret_id']!, _arretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_arretIdMeta);
    }
    if (data.containsKey('prestataire_id')) {
      context.handle(
        _prestataireIdMeta,
        prestataireId.isAcceptableOrUnknown(
          data['prestataire_id']!,
          _prestataireIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_prestataireIdMeta);
    }
    if (data.containsKey('nom')) {
      context.handle(
        _nomMeta,
        nom.isAcceptableOrUnknown(data['nom']!, _nomMeta),
      );
    }
    if (data.containsKey('empreinte_jeton')) {
      context.handle(
        _empreinteJetonMeta,
        empreinteJeton.isAcceptableOrUnknown(
          data['empreinte_jeton']!,
          _empreinteJetonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_empreinteJetonMeta);
    }
    if (data.containsKey('empreinte_code')) {
      context.handle(
        _empreinteCodeMeta,
        empreinteCode.isAcceptableOrUnknown(
          data['empreinte_code']!,
          _empreinteCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_empreinteCodeMeta);
    }
    if (data.containsKey('site_lat')) {
      context.handle(
        _siteLatMeta,
        siteLat.isAcceptableOrUnknown(data['site_lat']!, _siteLatMeta),
      );
    } else if (isInserting) {
      context.missing(_siteLatMeta);
    }
    if (data.containsKey('site_lon')) {
      context.handle(
        _siteLonMeta,
        siteLon.isAcceptableOrUnknown(data['site_lon']!, _siteLonMeta),
      );
    } else if (isInserting) {
      context.missing(_siteLonMeta);
    }
    if (data.containsKey('montant_avance')) {
      context.handle(
        _montantAvanceMeta,
        montantAvance.isAcceptableOrUnknown(
          data['montant_avance']!,
          _montantAvanceMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_montantAvanceMeta);
    }
    if (data.containsKey('devise')) {
      context.handle(
        _deviseMeta,
        devise.isAcceptableOrUnknown(data['devise']!, _deviseMeta),
      );
    } else if (isInserting) {
      context.missing(_deviseMeta);
    }
    if (data.containsKey('photo_exigee')) {
      context.handle(
        _photoExigeeMeta,
        photoExigee.isAcceptableOrUnknown(
          data['photo_exigee']!,
          _photoExigeeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_photoExigeeMeta);
    }
    if (data.containsKey('distance_max_m')) {
      context.handle(
        _distanceMaxMMeta,
        distanceMaxM.isAcceptableOrUnknown(
          data['distance_max_m']!,
          _distanceMaxMMeta,
        ),
      );
    }
    if (data.containsKey('statut_local')) {
      context.handle(
        _statutLocalMeta,
        statutLocal.isAcceptableOrUnknown(
          data['statut_local']!,
          _statutLocalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {arretId};
  @override
  ArretPreprovisionne map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArretPreprovisionne(
      arretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arret_id'],
      )!,
      prestataireId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prestataire_id'],
      )!,
      nom: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nom'],
      )!,
      empreinteJeton: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empreinte_jeton'],
      )!,
      empreinteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empreinte_code'],
      )!,
      siteLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}site_lat'],
      )!,
      siteLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}site_lon'],
      )!,
      montantAvance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_avance'],
      )!,
      devise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devise'],
      )!,
      photoExigee: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}photo_exigee'],
      )!,
      distanceMaxM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_max_m'],
      )!,
      statutLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut_local'],
      )!,
    );
  }

  @override
  $ArretsPreprovisionnesTable createAlias(String alias) {
    return $ArretsPreprovisionnesTable(attachedDatabase, alias);
  }
}

class ArretPreprovisionne extends DataClass
    implements Insertable<ArretPreprovisionne> {
  /// Arrêt à collecter — PK.
  final String arretId;

  /// Prestataire visé.
  final String prestataireId;

  /// Nom du prestataire (affiché sur la carte K3).
  final String nom;

  /// base16(sha256(jeton)) — match hors-ligne du QR scanné.
  final String empreinteJeton;

  /// base16(sha256(prestataire_id ‖ code)) — confirmation dégradée hors-ligne.
  final String empreinteCode;

  /// Position attendue du site (proximité).
  final double siteLat;

  /// Position attendue du site.
  final double siteLon;

  /// Montant avancé (unités mineures).
  final int montantAvance;

  /// Devise ISO 4217.
  final String devise;

  /// Photo exigée (politique résolue).
  final bool photoExigee;

  /// Rayon max de scan (m) — validation de proximité HORS-LIGNE (R6).
  final int distanceMaxM;

  /// Coche optimiste locale avant réconciliation serveur
  /// (`a_collecter` | `collecte`).
  final String statutLocal;
  const ArretPreprovisionne({
    required this.arretId,
    required this.prestataireId,
    required this.nom,
    required this.empreinteJeton,
    required this.empreinteCode,
    required this.siteLat,
    required this.siteLon,
    required this.montantAvance,
    required this.devise,
    required this.photoExigee,
    required this.distanceMaxM,
    required this.statutLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arret_id'] = Variable<String>(arretId);
    map['prestataire_id'] = Variable<String>(prestataireId);
    map['nom'] = Variable<String>(nom);
    map['empreinte_jeton'] = Variable<String>(empreinteJeton);
    map['empreinte_code'] = Variable<String>(empreinteCode);
    map['site_lat'] = Variable<double>(siteLat);
    map['site_lon'] = Variable<double>(siteLon);
    map['montant_avance'] = Variable<int>(montantAvance);
    map['devise'] = Variable<String>(devise);
    map['photo_exigee'] = Variable<bool>(photoExigee);
    map['distance_max_m'] = Variable<int>(distanceMaxM);
    map['statut_local'] = Variable<String>(statutLocal);
    return map;
  }

  ArretsPreprovisionnesCompanion toCompanion(bool nullToAbsent) {
    return ArretsPreprovisionnesCompanion(
      arretId: Value(arretId),
      prestataireId: Value(prestataireId),
      nom: Value(nom),
      empreinteJeton: Value(empreinteJeton),
      empreinteCode: Value(empreinteCode),
      siteLat: Value(siteLat),
      siteLon: Value(siteLon),
      montantAvance: Value(montantAvance),
      devise: Value(devise),
      photoExigee: Value(photoExigee),
      distanceMaxM: Value(distanceMaxM),
      statutLocal: Value(statutLocal),
    );
  }

  factory ArretPreprovisionne.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArretPreprovisionne(
      arretId: serializer.fromJson<String>(json['arretId']),
      prestataireId: serializer.fromJson<String>(json['prestataireId']),
      nom: serializer.fromJson<String>(json['nom']),
      empreinteJeton: serializer.fromJson<String>(json['empreinteJeton']),
      empreinteCode: serializer.fromJson<String>(json['empreinteCode']),
      siteLat: serializer.fromJson<double>(json['siteLat']),
      siteLon: serializer.fromJson<double>(json['siteLon']),
      montantAvance: serializer.fromJson<int>(json['montantAvance']),
      devise: serializer.fromJson<String>(json['devise']),
      photoExigee: serializer.fromJson<bool>(json['photoExigee']),
      distanceMaxM: serializer.fromJson<int>(json['distanceMaxM']),
      statutLocal: serializer.fromJson<String>(json['statutLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arretId': serializer.toJson<String>(arretId),
      'prestataireId': serializer.toJson<String>(prestataireId),
      'nom': serializer.toJson<String>(nom),
      'empreinteJeton': serializer.toJson<String>(empreinteJeton),
      'empreinteCode': serializer.toJson<String>(empreinteCode),
      'siteLat': serializer.toJson<double>(siteLat),
      'siteLon': serializer.toJson<double>(siteLon),
      'montantAvance': serializer.toJson<int>(montantAvance),
      'devise': serializer.toJson<String>(devise),
      'photoExigee': serializer.toJson<bool>(photoExigee),
      'distanceMaxM': serializer.toJson<int>(distanceMaxM),
      'statutLocal': serializer.toJson<String>(statutLocal),
    };
  }

  ArretPreprovisionne copyWith({
    String? arretId,
    String? prestataireId,
    String? nom,
    String? empreinteJeton,
    String? empreinteCode,
    double? siteLat,
    double? siteLon,
    int? montantAvance,
    String? devise,
    bool? photoExigee,
    int? distanceMaxM,
    String? statutLocal,
  }) => ArretPreprovisionne(
    arretId: arretId ?? this.arretId,
    prestataireId: prestataireId ?? this.prestataireId,
    nom: nom ?? this.nom,
    empreinteJeton: empreinteJeton ?? this.empreinteJeton,
    empreinteCode: empreinteCode ?? this.empreinteCode,
    siteLat: siteLat ?? this.siteLat,
    siteLon: siteLon ?? this.siteLon,
    montantAvance: montantAvance ?? this.montantAvance,
    devise: devise ?? this.devise,
    photoExigee: photoExigee ?? this.photoExigee,
    distanceMaxM: distanceMaxM ?? this.distanceMaxM,
    statutLocal: statutLocal ?? this.statutLocal,
  );
  ArretPreprovisionne copyWithCompanion(ArretsPreprovisionnesCompanion data) {
    return ArretPreprovisionne(
      arretId: data.arretId.present ? data.arretId.value : this.arretId,
      prestataireId: data.prestataireId.present
          ? data.prestataireId.value
          : this.prestataireId,
      nom: data.nom.present ? data.nom.value : this.nom,
      empreinteJeton: data.empreinteJeton.present
          ? data.empreinteJeton.value
          : this.empreinteJeton,
      empreinteCode: data.empreinteCode.present
          ? data.empreinteCode.value
          : this.empreinteCode,
      siteLat: data.siteLat.present ? data.siteLat.value : this.siteLat,
      siteLon: data.siteLon.present ? data.siteLon.value : this.siteLon,
      montantAvance: data.montantAvance.present
          ? data.montantAvance.value
          : this.montantAvance,
      devise: data.devise.present ? data.devise.value : this.devise,
      photoExigee: data.photoExigee.present
          ? data.photoExigee.value
          : this.photoExigee,
      distanceMaxM: data.distanceMaxM.present
          ? data.distanceMaxM.value
          : this.distanceMaxM,
      statutLocal: data.statutLocal.present
          ? data.statutLocal.value
          : this.statutLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArretPreprovisionne(')
          ..write('arretId: $arretId, ')
          ..write('prestataireId: $prestataireId, ')
          ..write('nom: $nom, ')
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('montantAvance: $montantAvance, ')
          ..write('devise: $devise, ')
          ..write('photoExigee: $photoExigee, ')
          ..write('distanceMaxM: $distanceMaxM, ')
          ..write('statutLocal: $statutLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    arretId,
    prestataireId,
    nom,
    empreinteJeton,
    empreinteCode,
    siteLat,
    siteLon,
    montantAvance,
    devise,
    photoExigee,
    distanceMaxM,
    statutLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArretPreprovisionne &&
          other.arretId == this.arretId &&
          other.prestataireId == this.prestataireId &&
          other.nom == this.nom &&
          other.empreinteJeton == this.empreinteJeton &&
          other.empreinteCode == this.empreinteCode &&
          other.siteLat == this.siteLat &&
          other.siteLon == this.siteLon &&
          other.montantAvance == this.montantAvance &&
          other.devise == this.devise &&
          other.photoExigee == this.photoExigee &&
          other.distanceMaxM == this.distanceMaxM &&
          other.statutLocal == this.statutLocal);
}

class ArretsPreprovisionnesCompanion
    extends UpdateCompanion<ArretPreprovisionne> {
  final Value<String> arretId;
  final Value<String> prestataireId;
  final Value<String> nom;
  final Value<String> empreinteJeton;
  final Value<String> empreinteCode;
  final Value<double> siteLat;
  final Value<double> siteLon;
  final Value<int> montantAvance;
  final Value<String> devise;
  final Value<bool> photoExigee;
  final Value<int> distanceMaxM;
  final Value<String> statutLocal;
  final Value<int> rowid;
  const ArretsPreprovisionnesCompanion({
    this.arretId = const Value.absent(),
    this.prestataireId = const Value.absent(),
    this.nom = const Value.absent(),
    this.empreinteJeton = const Value.absent(),
    this.empreinteCode = const Value.absent(),
    this.siteLat = const Value.absent(),
    this.siteLon = const Value.absent(),
    this.montantAvance = const Value.absent(),
    this.devise = const Value.absent(),
    this.photoExigee = const Value.absent(),
    this.distanceMaxM = const Value.absent(),
    this.statutLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArretsPreprovisionnesCompanion.insert({
    required String arretId,
    required String prestataireId,
    this.nom = const Value.absent(),
    required String empreinteJeton,
    required String empreinteCode,
    required double siteLat,
    required double siteLon,
    required int montantAvance,
    required String devise,
    required bool photoExigee,
    this.distanceMaxM = const Value.absent(),
    this.statutLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : arretId = Value(arretId),
       prestataireId = Value(prestataireId),
       empreinteJeton = Value(empreinteJeton),
       empreinteCode = Value(empreinteCode),
       siteLat = Value(siteLat),
       siteLon = Value(siteLon),
       montantAvance = Value(montantAvance),
       devise = Value(devise),
       photoExigee = Value(photoExigee);
  static Insertable<ArretPreprovisionne> custom({
    Expression<String>? arretId,
    Expression<String>? prestataireId,
    Expression<String>? nom,
    Expression<String>? empreinteJeton,
    Expression<String>? empreinteCode,
    Expression<double>? siteLat,
    Expression<double>? siteLon,
    Expression<int>? montantAvance,
    Expression<String>? devise,
    Expression<bool>? photoExigee,
    Expression<int>? distanceMaxM,
    Expression<String>? statutLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arretId != null) 'arret_id': arretId,
      if (prestataireId != null) 'prestataire_id': prestataireId,
      if (nom != null) 'nom': nom,
      if (empreinteJeton != null) 'empreinte_jeton': empreinteJeton,
      if (empreinteCode != null) 'empreinte_code': empreinteCode,
      if (siteLat != null) 'site_lat': siteLat,
      if (siteLon != null) 'site_lon': siteLon,
      if (montantAvance != null) 'montant_avance': montantAvance,
      if (devise != null) 'devise': devise,
      if (photoExigee != null) 'photo_exigee': photoExigee,
      if (distanceMaxM != null) 'distance_max_m': distanceMaxM,
      if (statutLocal != null) 'statut_local': statutLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArretsPreprovisionnesCompanion copyWith({
    Value<String>? arretId,
    Value<String>? prestataireId,
    Value<String>? nom,
    Value<String>? empreinteJeton,
    Value<String>? empreinteCode,
    Value<double>? siteLat,
    Value<double>? siteLon,
    Value<int>? montantAvance,
    Value<String>? devise,
    Value<bool>? photoExigee,
    Value<int>? distanceMaxM,
    Value<String>? statutLocal,
    Value<int>? rowid,
  }) {
    return ArretsPreprovisionnesCompanion(
      arretId: arretId ?? this.arretId,
      prestataireId: prestataireId ?? this.prestataireId,
      nom: nom ?? this.nom,
      empreinteJeton: empreinteJeton ?? this.empreinteJeton,
      empreinteCode: empreinteCode ?? this.empreinteCode,
      siteLat: siteLat ?? this.siteLat,
      siteLon: siteLon ?? this.siteLon,
      montantAvance: montantAvance ?? this.montantAvance,
      devise: devise ?? this.devise,
      photoExigee: photoExigee ?? this.photoExigee,
      distanceMaxM: distanceMaxM ?? this.distanceMaxM,
      statutLocal: statutLocal ?? this.statutLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (arretId.present) {
      map['arret_id'] = Variable<String>(arretId.value);
    }
    if (prestataireId.present) {
      map['prestataire_id'] = Variable<String>(prestataireId.value);
    }
    if (nom.present) {
      map['nom'] = Variable<String>(nom.value);
    }
    if (empreinteJeton.present) {
      map['empreinte_jeton'] = Variable<String>(empreinteJeton.value);
    }
    if (empreinteCode.present) {
      map['empreinte_code'] = Variable<String>(empreinteCode.value);
    }
    if (siteLat.present) {
      map['site_lat'] = Variable<double>(siteLat.value);
    }
    if (siteLon.present) {
      map['site_lon'] = Variable<double>(siteLon.value);
    }
    if (montantAvance.present) {
      map['montant_avance'] = Variable<int>(montantAvance.value);
    }
    if (devise.present) {
      map['devise'] = Variable<String>(devise.value);
    }
    if (photoExigee.present) {
      map['photo_exigee'] = Variable<bool>(photoExigee.value);
    }
    if (distanceMaxM.present) {
      map['distance_max_m'] = Variable<int>(distanceMaxM.value);
    }
    if (statutLocal.present) {
      map['statut_local'] = Variable<String>(statutLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ArretsPreprovisionnesCompanion(')
          ..write('arretId: $arretId, ')
          ..write('prestataireId: $prestataireId, ')
          ..write('nom: $nom, ')
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('montantAvance: $montantAvance, ')
          ..write('devise: $devise, ')
          ..write('photoExigee: $photoExigee, ')
          ..write('distanceMaxM: $distanceMaxM, ')
          ..write('statutLocal: $statutLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BrouillonsPanierTable extends BrouillonsPanier
    with TableInfo<$BrouillonsPanierTable, BrouillonPanier> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BrouillonsPanierTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _zoneIdMeta = const VerificationMeta('zoneId');
  @override
  late final GeneratedColumn<String> zoneId = GeneratedColumn<String>(
    'zone_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categorieSlugMeta = const VerificationMeta(
    'categorieSlug',
  );
  @override
  late final GeneratedColumn<String> categorieSlug = GeneratedColumn<String>(
    'categorie_slug',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lignesJsonMeta = const VerificationMeta(
    'lignesJson',
  );
  @override
  late final GeneratedColumn<String> lignesJson = GeneratedColumn<String>(
    'lignes_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _montantArticlesEstimeUnitesMeta =
      const VerificationMeta('montantArticlesEstimeUnites');
  @override
  late final GeneratedColumn<int> montantArticlesEstimeUnites =
      GeneratedColumn<int>(
        'montant_articles_estime_unites',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _deviseMeta = const VerificationMeta('devise');
  @override
  late final GeneratedColumn<String> devise = GeneratedColumn<String>(
    'devise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('XOF'),
  );
  static const VerificationMeta _majLeLocalMeta = const VerificationMeta(
    'majLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> majLeLocal = GeneratedColumn<DateTime>(
    'maj_le_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    zoneId,
    categorieSlug,
    lignesJson,
    montantArticlesEstimeUnites,
    devise,
    majLeLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'brouillons_panier';
  @override
  VerificationContext validateIntegrity(
    Insertable<BrouillonPanier> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('zone_id')) {
      context.handle(
        _zoneIdMeta,
        zoneId.isAcceptableOrUnknown(data['zone_id']!, _zoneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_zoneIdMeta);
    }
    if (data.containsKey('categorie_slug')) {
      context.handle(
        _categorieSlugMeta,
        categorieSlug.isAcceptableOrUnknown(
          data['categorie_slug']!,
          _categorieSlugMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_categorieSlugMeta);
    }
    if (data.containsKey('lignes_json')) {
      context.handle(
        _lignesJsonMeta,
        lignesJson.isAcceptableOrUnknown(data['lignes_json']!, _lignesJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_lignesJsonMeta);
    }
    if (data.containsKey('montant_articles_estime_unites')) {
      context.handle(
        _montantArticlesEstimeUnitesMeta,
        montantArticlesEstimeUnites.isAcceptableOrUnknown(
          data['montant_articles_estime_unites']!,
          _montantArticlesEstimeUnitesMeta,
        ),
      );
    }
    if (data.containsKey('devise')) {
      context.handle(
        _deviseMeta,
        devise.isAcceptableOrUnknown(data['devise']!, _deviseMeta),
      );
    }
    if (data.containsKey('maj_le_local')) {
      context.handle(
        _majLeLocalMeta,
        majLeLocal.isAcceptableOrUnknown(
          data['maj_le_local']!,
          _majLeLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_majLeLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {zoneId};
  @override
  BrouillonPanier map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BrouillonPanier(
      zoneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}zone_id'],
      )!,
      categorieSlug: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}categorie_slug'],
      )!,
      lignesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lignes_json'],
      )!,
      montantArticlesEstimeUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_articles_estime_unites'],
      )!,
      devise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devise'],
      )!,
      majLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maj_le_local'],
      )!,
    );
  }

  @override
  $BrouillonsPanierTable createAlias(String alias) {
    return $BrouillonsPanierTable(attachedDatabase, alias);
  }
}

class BrouillonPanier extends DataClass implements Insertable<BrouillonPanier> {
  /// Un seul brouillon à la fois par zone — PK.
  final String zoneId;

  /// Catégorie de service en cours de composition.
  final String categorieSlug;

  /// Lignes sérialisées (prestataire, article, quantité, préférence).
  final String lignesJson;

  /// Total ESTIMÉ des articles, unités mineures (jamais les frais — hors ligne,
  /// l'app ne connaît pas le devis).
  final int montantArticlesEstimeUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Dernière modification locale.
  final DateTime majLeLocal;
  const BrouillonPanier({
    required this.zoneId,
    required this.categorieSlug,
    required this.lignesJson,
    required this.montantArticlesEstimeUnites,
    required this.devise,
    required this.majLeLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['zone_id'] = Variable<String>(zoneId);
    map['categorie_slug'] = Variable<String>(categorieSlug);
    map['lignes_json'] = Variable<String>(lignesJson);
    map['montant_articles_estime_unites'] = Variable<int>(
      montantArticlesEstimeUnites,
    );
    map['devise'] = Variable<String>(devise);
    map['maj_le_local'] = Variable<DateTime>(majLeLocal);
    return map;
  }

  BrouillonsPanierCompanion toCompanion(bool nullToAbsent) {
    return BrouillonsPanierCompanion(
      zoneId: Value(zoneId),
      categorieSlug: Value(categorieSlug),
      lignesJson: Value(lignesJson),
      montantArticlesEstimeUnites: Value(montantArticlesEstimeUnites),
      devise: Value(devise),
      majLeLocal: Value(majLeLocal),
    );
  }

  factory BrouillonPanier.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BrouillonPanier(
      zoneId: serializer.fromJson<String>(json['zoneId']),
      categorieSlug: serializer.fromJson<String>(json['categorieSlug']),
      lignesJson: serializer.fromJson<String>(json['lignesJson']),
      montantArticlesEstimeUnites: serializer.fromJson<int>(
        json['montantArticlesEstimeUnites'],
      ),
      devise: serializer.fromJson<String>(json['devise']),
      majLeLocal: serializer.fromJson<DateTime>(json['majLeLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'zoneId': serializer.toJson<String>(zoneId),
      'categorieSlug': serializer.toJson<String>(categorieSlug),
      'lignesJson': serializer.toJson<String>(lignesJson),
      'montantArticlesEstimeUnites': serializer.toJson<int>(
        montantArticlesEstimeUnites,
      ),
      'devise': serializer.toJson<String>(devise),
      'majLeLocal': serializer.toJson<DateTime>(majLeLocal),
    };
  }

  BrouillonPanier copyWith({
    String? zoneId,
    String? categorieSlug,
    String? lignesJson,
    int? montantArticlesEstimeUnites,
    String? devise,
    DateTime? majLeLocal,
  }) => BrouillonPanier(
    zoneId: zoneId ?? this.zoneId,
    categorieSlug: categorieSlug ?? this.categorieSlug,
    lignesJson: lignesJson ?? this.lignesJson,
    montantArticlesEstimeUnites:
        montantArticlesEstimeUnites ?? this.montantArticlesEstimeUnites,
    devise: devise ?? this.devise,
    majLeLocal: majLeLocal ?? this.majLeLocal,
  );
  BrouillonPanier copyWithCompanion(BrouillonsPanierCompanion data) {
    return BrouillonPanier(
      zoneId: data.zoneId.present ? data.zoneId.value : this.zoneId,
      categorieSlug: data.categorieSlug.present
          ? data.categorieSlug.value
          : this.categorieSlug,
      lignesJson: data.lignesJson.present
          ? data.lignesJson.value
          : this.lignesJson,
      montantArticlesEstimeUnites: data.montantArticlesEstimeUnites.present
          ? data.montantArticlesEstimeUnites.value
          : this.montantArticlesEstimeUnites,
      devise: data.devise.present ? data.devise.value : this.devise,
      majLeLocal: data.majLeLocal.present
          ? data.majLeLocal.value
          : this.majLeLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BrouillonPanier(')
          ..write('zoneId: $zoneId, ')
          ..write('categorieSlug: $categorieSlug, ')
          ..write('lignesJson: $lignesJson, ')
          ..write('montantArticlesEstimeUnites: $montantArticlesEstimeUnites, ')
          ..write('devise: $devise, ')
          ..write('majLeLocal: $majLeLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    zoneId,
    categorieSlug,
    lignesJson,
    montantArticlesEstimeUnites,
    devise,
    majLeLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BrouillonPanier &&
          other.zoneId == this.zoneId &&
          other.categorieSlug == this.categorieSlug &&
          other.lignesJson == this.lignesJson &&
          other.montantArticlesEstimeUnites ==
              this.montantArticlesEstimeUnites &&
          other.devise == this.devise &&
          other.majLeLocal == this.majLeLocal);
}

class BrouillonsPanierCompanion extends UpdateCompanion<BrouillonPanier> {
  final Value<String> zoneId;
  final Value<String> categorieSlug;
  final Value<String> lignesJson;
  final Value<int> montantArticlesEstimeUnites;
  final Value<String> devise;
  final Value<DateTime> majLeLocal;
  final Value<int> rowid;
  const BrouillonsPanierCompanion({
    this.zoneId = const Value.absent(),
    this.categorieSlug = const Value.absent(),
    this.lignesJson = const Value.absent(),
    this.montantArticlesEstimeUnites = const Value.absent(),
    this.devise = const Value.absent(),
    this.majLeLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BrouillonsPanierCompanion.insert({
    required String zoneId,
    required String categorieSlug,
    required String lignesJson,
    this.montantArticlesEstimeUnites = const Value.absent(),
    this.devise = const Value.absent(),
    required DateTime majLeLocal,
    this.rowid = const Value.absent(),
  }) : zoneId = Value(zoneId),
       categorieSlug = Value(categorieSlug),
       lignesJson = Value(lignesJson),
       majLeLocal = Value(majLeLocal);
  static Insertable<BrouillonPanier> custom({
    Expression<String>? zoneId,
    Expression<String>? categorieSlug,
    Expression<String>? lignesJson,
    Expression<int>? montantArticlesEstimeUnites,
    Expression<String>? devise,
    Expression<DateTime>? majLeLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (zoneId != null) 'zone_id': zoneId,
      if (categorieSlug != null) 'categorie_slug': categorieSlug,
      if (lignesJson != null) 'lignes_json': lignesJson,
      if (montantArticlesEstimeUnites != null)
        'montant_articles_estime_unites': montantArticlesEstimeUnites,
      if (devise != null) 'devise': devise,
      if (majLeLocal != null) 'maj_le_local': majLeLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BrouillonsPanierCompanion copyWith({
    Value<String>? zoneId,
    Value<String>? categorieSlug,
    Value<String>? lignesJson,
    Value<int>? montantArticlesEstimeUnites,
    Value<String>? devise,
    Value<DateTime>? majLeLocal,
    Value<int>? rowid,
  }) {
    return BrouillonsPanierCompanion(
      zoneId: zoneId ?? this.zoneId,
      categorieSlug: categorieSlug ?? this.categorieSlug,
      lignesJson: lignesJson ?? this.lignesJson,
      montantArticlesEstimeUnites:
          montantArticlesEstimeUnites ?? this.montantArticlesEstimeUnites,
      devise: devise ?? this.devise,
      majLeLocal: majLeLocal ?? this.majLeLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (zoneId.present) {
      map['zone_id'] = Variable<String>(zoneId.value);
    }
    if (categorieSlug.present) {
      map['categorie_slug'] = Variable<String>(categorieSlug.value);
    }
    if (lignesJson.present) {
      map['lignes_json'] = Variable<String>(lignesJson.value);
    }
    if (montantArticlesEstimeUnites.present) {
      map['montant_articles_estime_unites'] = Variable<int>(
        montantArticlesEstimeUnites.value,
      );
    }
    if (devise.present) {
      map['devise'] = Variable<String>(devise.value);
    }
    if (majLeLocal.present) {
      map['maj_le_local'] = Variable<DateTime>(majLeLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BrouillonsPanierCompanion(')
          ..write('zoneId: $zoneId, ')
          ..write('categorieSlug: $categorieSlug, ')
          ..write('lignesJson: $lignesJson, ')
          ..write('montantArticlesEstimeUnites: $montantArticlesEstimeUnites, ')
          ..write('devise: $devise, ')
          ..write('majLeLocal: $majLeLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CommandesCacheTable extends CommandesCache
    with TableInfo<$CommandesCacheTable, CommandeCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CommandesCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _commandeIdMeta = const VerificationMeta(
    'commandeId',
  );
  @override
  late final GeneratedColumn<String> commandeId = GeneratedColumn<String>(
    'commande_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etatMeta = const VerificationMeta('etat');
  @override
  late final GeneratedColumn<String> etat = GeneratedColumn<String>(
    'etat',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _etatCleMeta = const VerificationMeta(
    'etatCle',
  );
  @override
  late final GeneratedColumn<String> etatCle = GeneratedColumn<String>(
    'etat_cle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _collectesFaitesMeta = const VerificationMeta(
    'collectesFaites',
  );
  @override
  late final GeneratedColumn<int> collectesFaites = GeneratedColumn<int>(
    'collectes_faites',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _collectesTotalMeta = const VerificationMeta(
    'collectesTotal',
  );
  @override
  late final GeneratedColumn<int> collectesTotal = GeneratedColumn<int>(
    'collectes_total',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _codeLivraisonMeta = const VerificationMeta(
    'codeLivraison',
  );
  @override
  late final GeneratedColumn<String> codeLivraison = GeneratedColumn<String>(
    'code_livraison',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jetonReceptionMeta = const VerificationMeta(
    'jetonReception',
  );
  @override
  late final GeneratedColumn<String> jetonReception = GeneratedColumn<String>(
    'jeton_reception',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _totalUnitesMeta = const VerificationMeta(
    'totalUnites',
  );
  @override
  late final GeneratedColumn<int> totalUnites = GeneratedColumn<int>(
    'total_unites',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _deviseMeta = const VerificationMeta('devise');
  @override
  late final GeneratedColumn<String> devise = GeneratedColumn<String>(
    'devise',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('XOF'),
  );
  static const VerificationMeta _positionLatMeta = const VerificationMeta(
    'positionLat',
  );
  @override
  late final GeneratedColumn<double> positionLat = GeneratedColumn<double>(
    'position_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionLonMeta = const VerificationMeta(
    'positionLon',
  );
  @override
  late final GeneratedColumn<double> positionLon = GeneratedColumn<double>(
    'position_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionAgeSMeta = const VerificationMeta(
    'positionAgeS',
  );
  @override
  late final GeneratedColumn<int> positionAgeS = GeneratedColumn<int>(
    'position_age_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _majLeLocalMeta = const VerificationMeta(
    'majLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> majLeLocal = GeneratedColumn<DateTime>(
    'maj_le_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    commandeId,
    etat,
    etatCle,
    collectesFaites,
    collectesTotal,
    codeLivraison,
    jetonReception,
    totalUnites,
    devise,
    positionLat,
    positionLon,
    positionAgeS,
    majLeLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'commandes_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CommandeCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('commande_id')) {
      context.handle(
        _commandeIdMeta,
        commandeId.isAcceptableOrUnknown(data['commande_id']!, _commandeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_commandeIdMeta);
    }
    if (data.containsKey('etat')) {
      context.handle(
        _etatMeta,
        etat.isAcceptableOrUnknown(data['etat']!, _etatMeta),
      );
    } else if (isInserting) {
      context.missing(_etatMeta);
    }
    if (data.containsKey('etat_cle')) {
      context.handle(
        _etatCleMeta,
        etatCle.isAcceptableOrUnknown(data['etat_cle']!, _etatCleMeta),
      );
    }
    if (data.containsKey('collectes_faites')) {
      context.handle(
        _collectesFaitesMeta,
        collectesFaites.isAcceptableOrUnknown(
          data['collectes_faites']!,
          _collectesFaitesMeta,
        ),
      );
    }
    if (data.containsKey('collectes_total')) {
      context.handle(
        _collectesTotalMeta,
        collectesTotal.isAcceptableOrUnknown(
          data['collectes_total']!,
          _collectesTotalMeta,
        ),
      );
    }
    if (data.containsKey('code_livraison')) {
      context.handle(
        _codeLivraisonMeta,
        codeLivraison.isAcceptableOrUnknown(
          data['code_livraison']!,
          _codeLivraisonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_codeLivraisonMeta);
    }
    if (data.containsKey('jeton_reception')) {
      context.handle(
        _jetonReceptionMeta,
        jetonReception.isAcceptableOrUnknown(
          data['jeton_reception']!,
          _jetonReceptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_jetonReceptionMeta);
    }
    if (data.containsKey('total_unites')) {
      context.handle(
        _totalUnitesMeta,
        totalUnites.isAcceptableOrUnknown(
          data['total_unites']!,
          _totalUnitesMeta,
        ),
      );
    }
    if (data.containsKey('devise')) {
      context.handle(
        _deviseMeta,
        devise.isAcceptableOrUnknown(data['devise']!, _deviseMeta),
      );
    }
    if (data.containsKey('position_lat')) {
      context.handle(
        _positionLatMeta,
        positionLat.isAcceptableOrUnknown(
          data['position_lat']!,
          _positionLatMeta,
        ),
      );
    }
    if (data.containsKey('position_lon')) {
      context.handle(
        _positionLonMeta,
        positionLon.isAcceptableOrUnknown(
          data['position_lon']!,
          _positionLonMeta,
        ),
      );
    }
    if (data.containsKey('position_age_s')) {
      context.handle(
        _positionAgeSMeta,
        positionAgeS.isAcceptableOrUnknown(
          data['position_age_s']!,
          _positionAgeSMeta,
        ),
      );
    }
    if (data.containsKey('maj_le_local')) {
      context.handle(
        _majLeLocalMeta,
        majLeLocal.isAcceptableOrUnknown(
          data['maj_le_local']!,
          _majLeLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_majLeLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {commandeId};
  @override
  CommandeCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CommandeCache(
      commandeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commande_id'],
      )!,
      etat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etat'],
      )!,
      etatCle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etat_cle'],
      )!,
      collectesFaites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collectes_faites'],
      )!,
      collectesTotal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}collectes_total'],
      )!,
      codeLivraison: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}code_livraison'],
      )!,
      jetonReception: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}jeton_reception'],
      )!,
      totalUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_unites'],
      )!,
      devise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devise'],
      )!,
      positionLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position_lat'],
      ),
      positionLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}position_lon'],
      ),
      positionAgeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_age_s'],
      ),
      majLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maj_le_local'],
      )!,
    );
  }

  @override
  $CommandesCacheTable createAlias(String alias) {
    return $CommandesCacheTable(attachedDatabase, alias);
  }
}

class CommandeCache extends DataClass implements Insertable<CommandeCache> {
  /// Commande — PK.
  final String commandeId;

  /// Dernier état connu du tronc (`nouvelle`, `en_cours`…). Annoncé COMME TEL
  /// hors ligne : l'app ne prétend jamais que c'est l'état courant.
  final String etat;

  /// Clé i18n de l'état, pour l'affichage en langage clair.
  final String etatCle;

  /// Collectes faites (la remise n'en est pas une — P1).
  final int collectesFaites;

  /// Total de collectes.
  final int collectesTotal;

  /// Code de remise à 4 chiffres — lisible par le CLIENT seul.
  final String codeLivraison;

  /// Jeton encodé dans le QR de réception.
  final String jetonReception;

  /// Total à régler, unités mineures.
  final int totalUnites;

  /// Devise ISO 4217.
  final String devise;

  /// Dernière position connue du coursier (nulle si aucune).
  final double? positionLat;

  /// Dernière position connue du coursier.
  final double? positionLon;

  /// Âge de la position AU MOMENT DE LA MISE EN CACHE (secondes). L'app y
  /// ajoute le temps écoulé depuis [majLeLocal] : elle n'invente jamais une
  /// position fraîche (FR-040).
  final int? positionAgeS;

  /// Horodatage local de la mise en cache — base du calcul d'ancienneté.
  final DateTime majLeLocal;
  const CommandeCache({
    required this.commandeId,
    required this.etat,
    required this.etatCle,
    required this.collectesFaites,
    required this.collectesTotal,
    required this.codeLivraison,
    required this.jetonReception,
    required this.totalUnites,
    required this.devise,
    this.positionLat,
    this.positionLon,
    this.positionAgeS,
    required this.majLeLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['commande_id'] = Variable<String>(commandeId);
    map['etat'] = Variable<String>(etat);
    map['etat_cle'] = Variable<String>(etatCle);
    map['collectes_faites'] = Variable<int>(collectesFaites);
    map['collectes_total'] = Variable<int>(collectesTotal);
    map['code_livraison'] = Variable<String>(codeLivraison);
    map['jeton_reception'] = Variable<String>(jetonReception);
    map['total_unites'] = Variable<int>(totalUnites);
    map['devise'] = Variable<String>(devise);
    if (!nullToAbsent || positionLat != null) {
      map['position_lat'] = Variable<double>(positionLat);
    }
    if (!nullToAbsent || positionLon != null) {
      map['position_lon'] = Variable<double>(positionLon);
    }
    if (!nullToAbsent || positionAgeS != null) {
      map['position_age_s'] = Variable<int>(positionAgeS);
    }
    map['maj_le_local'] = Variable<DateTime>(majLeLocal);
    return map;
  }

  CommandesCacheCompanion toCompanion(bool nullToAbsent) {
    return CommandesCacheCompanion(
      commandeId: Value(commandeId),
      etat: Value(etat),
      etatCle: Value(etatCle),
      collectesFaites: Value(collectesFaites),
      collectesTotal: Value(collectesTotal),
      codeLivraison: Value(codeLivraison),
      jetonReception: Value(jetonReception),
      totalUnites: Value(totalUnites),
      devise: Value(devise),
      positionLat: positionLat == null && nullToAbsent
          ? const Value.absent()
          : Value(positionLat),
      positionLon: positionLon == null && nullToAbsent
          ? const Value.absent()
          : Value(positionLon),
      positionAgeS: positionAgeS == null && nullToAbsent
          ? const Value.absent()
          : Value(positionAgeS),
      majLeLocal: Value(majLeLocal),
    );
  }

  factory CommandeCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CommandeCache(
      commandeId: serializer.fromJson<String>(json['commandeId']),
      etat: serializer.fromJson<String>(json['etat']),
      etatCle: serializer.fromJson<String>(json['etatCle']),
      collectesFaites: serializer.fromJson<int>(json['collectesFaites']),
      collectesTotal: serializer.fromJson<int>(json['collectesTotal']),
      codeLivraison: serializer.fromJson<String>(json['codeLivraison']),
      jetonReception: serializer.fromJson<String>(json['jetonReception']),
      totalUnites: serializer.fromJson<int>(json['totalUnites']),
      devise: serializer.fromJson<String>(json['devise']),
      positionLat: serializer.fromJson<double?>(json['positionLat']),
      positionLon: serializer.fromJson<double?>(json['positionLon']),
      positionAgeS: serializer.fromJson<int?>(json['positionAgeS']),
      majLeLocal: serializer.fromJson<DateTime>(json['majLeLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'commandeId': serializer.toJson<String>(commandeId),
      'etat': serializer.toJson<String>(etat),
      'etatCle': serializer.toJson<String>(etatCle),
      'collectesFaites': serializer.toJson<int>(collectesFaites),
      'collectesTotal': serializer.toJson<int>(collectesTotal),
      'codeLivraison': serializer.toJson<String>(codeLivraison),
      'jetonReception': serializer.toJson<String>(jetonReception),
      'totalUnites': serializer.toJson<int>(totalUnites),
      'devise': serializer.toJson<String>(devise),
      'positionLat': serializer.toJson<double?>(positionLat),
      'positionLon': serializer.toJson<double?>(positionLon),
      'positionAgeS': serializer.toJson<int?>(positionAgeS),
      'majLeLocal': serializer.toJson<DateTime>(majLeLocal),
    };
  }

  CommandeCache copyWith({
    String? commandeId,
    String? etat,
    String? etatCle,
    int? collectesFaites,
    int? collectesTotal,
    String? codeLivraison,
    String? jetonReception,
    int? totalUnites,
    String? devise,
    Value<double?> positionLat = const Value.absent(),
    Value<double?> positionLon = const Value.absent(),
    Value<int?> positionAgeS = const Value.absent(),
    DateTime? majLeLocal,
  }) => CommandeCache(
    commandeId: commandeId ?? this.commandeId,
    etat: etat ?? this.etat,
    etatCle: etatCle ?? this.etatCle,
    collectesFaites: collectesFaites ?? this.collectesFaites,
    collectesTotal: collectesTotal ?? this.collectesTotal,
    codeLivraison: codeLivraison ?? this.codeLivraison,
    jetonReception: jetonReception ?? this.jetonReception,
    totalUnites: totalUnites ?? this.totalUnites,
    devise: devise ?? this.devise,
    positionLat: positionLat.present ? positionLat.value : this.positionLat,
    positionLon: positionLon.present ? positionLon.value : this.positionLon,
    positionAgeS: positionAgeS.present ? positionAgeS.value : this.positionAgeS,
    majLeLocal: majLeLocal ?? this.majLeLocal,
  );
  CommandeCache copyWithCompanion(CommandesCacheCompanion data) {
    return CommandeCache(
      commandeId: data.commandeId.present
          ? data.commandeId.value
          : this.commandeId,
      etat: data.etat.present ? data.etat.value : this.etat,
      etatCle: data.etatCle.present ? data.etatCle.value : this.etatCle,
      collectesFaites: data.collectesFaites.present
          ? data.collectesFaites.value
          : this.collectesFaites,
      collectesTotal: data.collectesTotal.present
          ? data.collectesTotal.value
          : this.collectesTotal,
      codeLivraison: data.codeLivraison.present
          ? data.codeLivraison.value
          : this.codeLivraison,
      jetonReception: data.jetonReception.present
          ? data.jetonReception.value
          : this.jetonReception,
      totalUnites: data.totalUnites.present
          ? data.totalUnites.value
          : this.totalUnites,
      devise: data.devise.present ? data.devise.value : this.devise,
      positionLat: data.positionLat.present
          ? data.positionLat.value
          : this.positionLat,
      positionLon: data.positionLon.present
          ? data.positionLon.value
          : this.positionLon,
      positionAgeS: data.positionAgeS.present
          ? data.positionAgeS.value
          : this.positionAgeS,
      majLeLocal: data.majLeLocal.present
          ? data.majLeLocal.value
          : this.majLeLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CommandeCache(')
          ..write('commandeId: $commandeId, ')
          ..write('etat: $etat, ')
          ..write('etatCle: $etatCle, ')
          ..write('collectesFaites: $collectesFaites, ')
          ..write('collectesTotal: $collectesTotal, ')
          ..write('codeLivraison: $codeLivraison, ')
          ..write('jetonReception: $jetonReception, ')
          ..write('totalUnites: $totalUnites, ')
          ..write('devise: $devise, ')
          ..write('positionLat: $positionLat, ')
          ..write('positionLon: $positionLon, ')
          ..write('positionAgeS: $positionAgeS, ')
          ..write('majLeLocal: $majLeLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    commandeId,
    etat,
    etatCle,
    collectesFaites,
    collectesTotal,
    codeLivraison,
    jetonReception,
    totalUnites,
    devise,
    positionLat,
    positionLon,
    positionAgeS,
    majLeLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CommandeCache &&
          other.commandeId == this.commandeId &&
          other.etat == this.etat &&
          other.etatCle == this.etatCle &&
          other.collectesFaites == this.collectesFaites &&
          other.collectesTotal == this.collectesTotal &&
          other.codeLivraison == this.codeLivraison &&
          other.jetonReception == this.jetonReception &&
          other.totalUnites == this.totalUnites &&
          other.devise == this.devise &&
          other.positionLat == this.positionLat &&
          other.positionLon == this.positionLon &&
          other.positionAgeS == this.positionAgeS &&
          other.majLeLocal == this.majLeLocal);
}

class CommandesCacheCompanion extends UpdateCompanion<CommandeCache> {
  final Value<String> commandeId;
  final Value<String> etat;
  final Value<String> etatCle;
  final Value<int> collectesFaites;
  final Value<int> collectesTotal;
  final Value<String> codeLivraison;
  final Value<String> jetonReception;
  final Value<int> totalUnites;
  final Value<String> devise;
  final Value<double?> positionLat;
  final Value<double?> positionLon;
  final Value<int?> positionAgeS;
  final Value<DateTime> majLeLocal;
  final Value<int> rowid;
  const CommandesCacheCompanion({
    this.commandeId = const Value.absent(),
    this.etat = const Value.absent(),
    this.etatCle = const Value.absent(),
    this.collectesFaites = const Value.absent(),
    this.collectesTotal = const Value.absent(),
    this.codeLivraison = const Value.absent(),
    this.jetonReception = const Value.absent(),
    this.totalUnites = const Value.absent(),
    this.devise = const Value.absent(),
    this.positionLat = const Value.absent(),
    this.positionLon = const Value.absent(),
    this.positionAgeS = const Value.absent(),
    this.majLeLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CommandesCacheCompanion.insert({
    required String commandeId,
    required String etat,
    this.etatCle = const Value.absent(),
    this.collectesFaites = const Value.absent(),
    this.collectesTotal = const Value.absent(),
    required String codeLivraison,
    required String jetonReception,
    this.totalUnites = const Value.absent(),
    this.devise = const Value.absent(),
    this.positionLat = const Value.absent(),
    this.positionLon = const Value.absent(),
    this.positionAgeS = const Value.absent(),
    required DateTime majLeLocal,
    this.rowid = const Value.absent(),
  }) : commandeId = Value(commandeId),
       etat = Value(etat),
       codeLivraison = Value(codeLivraison),
       jetonReception = Value(jetonReception),
       majLeLocal = Value(majLeLocal);
  static Insertable<CommandeCache> custom({
    Expression<String>? commandeId,
    Expression<String>? etat,
    Expression<String>? etatCle,
    Expression<int>? collectesFaites,
    Expression<int>? collectesTotal,
    Expression<String>? codeLivraison,
    Expression<String>? jetonReception,
    Expression<int>? totalUnites,
    Expression<String>? devise,
    Expression<double>? positionLat,
    Expression<double>? positionLon,
    Expression<int>? positionAgeS,
    Expression<DateTime>? majLeLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (commandeId != null) 'commande_id': commandeId,
      if (etat != null) 'etat': etat,
      if (etatCle != null) 'etat_cle': etatCle,
      if (collectesFaites != null) 'collectes_faites': collectesFaites,
      if (collectesTotal != null) 'collectes_total': collectesTotal,
      if (codeLivraison != null) 'code_livraison': codeLivraison,
      if (jetonReception != null) 'jeton_reception': jetonReception,
      if (totalUnites != null) 'total_unites': totalUnites,
      if (devise != null) 'devise': devise,
      if (positionLat != null) 'position_lat': positionLat,
      if (positionLon != null) 'position_lon': positionLon,
      if (positionAgeS != null) 'position_age_s': positionAgeS,
      if (majLeLocal != null) 'maj_le_local': majLeLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CommandesCacheCompanion copyWith({
    Value<String>? commandeId,
    Value<String>? etat,
    Value<String>? etatCle,
    Value<int>? collectesFaites,
    Value<int>? collectesTotal,
    Value<String>? codeLivraison,
    Value<String>? jetonReception,
    Value<int>? totalUnites,
    Value<String>? devise,
    Value<double?>? positionLat,
    Value<double?>? positionLon,
    Value<int?>? positionAgeS,
    Value<DateTime>? majLeLocal,
    Value<int>? rowid,
  }) {
    return CommandesCacheCompanion(
      commandeId: commandeId ?? this.commandeId,
      etat: etat ?? this.etat,
      etatCle: etatCle ?? this.etatCle,
      collectesFaites: collectesFaites ?? this.collectesFaites,
      collectesTotal: collectesTotal ?? this.collectesTotal,
      codeLivraison: codeLivraison ?? this.codeLivraison,
      jetonReception: jetonReception ?? this.jetonReception,
      totalUnites: totalUnites ?? this.totalUnites,
      devise: devise ?? this.devise,
      positionLat: positionLat ?? this.positionLat,
      positionLon: positionLon ?? this.positionLon,
      positionAgeS: positionAgeS ?? this.positionAgeS,
      majLeLocal: majLeLocal ?? this.majLeLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (commandeId.present) {
      map['commande_id'] = Variable<String>(commandeId.value);
    }
    if (etat.present) {
      map['etat'] = Variable<String>(etat.value);
    }
    if (etatCle.present) {
      map['etat_cle'] = Variable<String>(etatCle.value);
    }
    if (collectesFaites.present) {
      map['collectes_faites'] = Variable<int>(collectesFaites.value);
    }
    if (collectesTotal.present) {
      map['collectes_total'] = Variable<int>(collectesTotal.value);
    }
    if (codeLivraison.present) {
      map['code_livraison'] = Variable<String>(codeLivraison.value);
    }
    if (jetonReception.present) {
      map['jeton_reception'] = Variable<String>(jetonReception.value);
    }
    if (totalUnites.present) {
      map['total_unites'] = Variable<int>(totalUnites.value);
    }
    if (devise.present) {
      map['devise'] = Variable<String>(devise.value);
    }
    if (positionLat.present) {
      map['position_lat'] = Variable<double>(positionLat.value);
    }
    if (positionLon.present) {
      map['position_lon'] = Variable<double>(positionLon.value);
    }
    if (positionAgeS.present) {
      map['position_age_s'] = Variable<int>(positionAgeS.value);
    }
    if (majLeLocal.present) {
      map['maj_le_local'] = Variable<DateTime>(majLeLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CommandesCacheCompanion(')
          ..write('commandeId: $commandeId, ')
          ..write('etat: $etat, ')
          ..write('etatCle: $etatCle, ')
          ..write('collectesFaites: $collectesFaites, ')
          ..write('collectesTotal: $collectesTotal, ')
          ..write('codeLivraison: $codeLivraison, ')
          ..write('jetonReception: $jetonReception, ')
          ..write('totalUnites: $totalUnites, ')
          ..write('devise: $devise, ')
          ..write('positionLat: $positionLat, ')
          ..write('positionLon: $positionLon, ')
          ..write('positionAgeS: $positionAgeS, ')
          ..write('majLeLocal: $majLeLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$BaseOffline extends GeneratedDatabase {
  _$BaseOffline(QueryExecutor e) : super(e);
  $BaseOfflineManager get managers => $BaseOfflineManager(this);
  late final $ActionsEnAttenteTable actionsEnAttente = $ActionsEnAttenteTable(
    this,
  );
  late final $ArretsPreprovisionnesTable arretsPreprovisionnes =
      $ArretsPreprovisionnesTable(this);
  late final $BrouillonsPanierTable brouillonsPanier = $BrouillonsPanierTable(
    this,
  );
  late final $CommandesCacheTable commandesCache = $CommandesCacheTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    actionsEnAttente,
    arretsPreprovisionnes,
    brouillonsPanier,
    commandesCache,
  ];
}

typedef $$ActionsEnAttenteTableCreateCompanionBuilder =
    ActionsEnAttenteCompanion Function({
      required String uuidClient,
      required String endpoint,
      Value<String> methode,
      required String payloadJson,
      Value<Uint8List?> photoOctets,
      required DateTime creeLeLocal,
      Value<int> tentatives,
      Value<String?> dernierMotif,
      Value<int> rowid,
    });
typedef $$ActionsEnAttenteTableUpdateCompanionBuilder =
    ActionsEnAttenteCompanion Function({
      Value<String> uuidClient,
      Value<String> endpoint,
      Value<String> methode,
      Value<String> payloadJson,
      Value<Uint8List?> photoOctets,
      Value<DateTime> creeLeLocal,
      Value<int> tentatives,
      Value<String?> dernierMotif,
      Value<int> rowid,
    });

class $$ActionsEnAttenteTableFilterComposer
    extends Composer<_$BaseOffline, $ActionsEnAttenteTable> {
  $$ActionsEnAttenteTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uuidClient => $composableBuilder(
    column: $table.uuidClient,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get methode => $composableBuilder(
    column: $table.methode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get photoOctets => $composableBuilder(
    column: $table.photoOctets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get creeLeLocal => $composableBuilder(
    column: $table.creeLeLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dernierMotif => $composableBuilder(
    column: $table.dernierMotif,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ActionsEnAttenteTableOrderingComposer
    extends Composer<_$BaseOffline, $ActionsEnAttenteTable> {
  $$ActionsEnAttenteTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uuidClient => $composableBuilder(
    column: $table.uuidClient,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endpoint => $composableBuilder(
    column: $table.endpoint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get methode => $composableBuilder(
    column: $table.methode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get photoOctets => $composableBuilder(
    column: $table.photoOctets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get creeLeLocal => $composableBuilder(
    column: $table.creeLeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dernierMotif => $composableBuilder(
    column: $table.dernierMotif,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ActionsEnAttenteTableAnnotationComposer
    extends Composer<_$BaseOffline, $ActionsEnAttenteTable> {
  $$ActionsEnAttenteTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uuidClient => $composableBuilder(
    column: $table.uuidClient,
    builder: (column) => column,
  );

  GeneratedColumn<String> get endpoint =>
      $composableBuilder(column: $table.endpoint, builder: (column) => column);

  GeneratedColumn<String> get methode =>
      $composableBuilder(column: $table.methode, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<Uint8List> get photoOctets => $composableBuilder(
    column: $table.photoOctets,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get creeLeLocal => $composableBuilder(
    column: $table.creeLeLocal,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tentatives => $composableBuilder(
    column: $table.tentatives,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dernierMotif => $composableBuilder(
    column: $table.dernierMotif,
    builder: (column) => column,
  );
}

class $$ActionsEnAttenteTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $ActionsEnAttenteTable,
          ActionEnAttente,
          $$ActionsEnAttenteTableFilterComposer,
          $$ActionsEnAttenteTableOrderingComposer,
          $$ActionsEnAttenteTableAnnotationComposer,
          $$ActionsEnAttenteTableCreateCompanionBuilder,
          $$ActionsEnAttenteTableUpdateCompanionBuilder,
          (
            ActionEnAttente,
            BaseReferences<
              _$BaseOffline,
              $ActionsEnAttenteTable,
              ActionEnAttente
            >,
          ),
          ActionEnAttente,
          PrefetchHooks Function()
        > {
  $$ActionsEnAttenteTableTableManager(
    _$BaseOffline db,
    $ActionsEnAttenteTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ActionsEnAttenteTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ActionsEnAttenteTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ActionsEnAttenteTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> uuidClient = const Value.absent(),
                Value<String> endpoint = const Value.absent(),
                Value<String> methode = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<Uint8List?> photoOctets = const Value.absent(),
                Value<DateTime> creeLeLocal = const Value.absent(),
                Value<int> tentatives = const Value.absent(),
                Value<String?> dernierMotif = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActionsEnAttenteCompanion(
                uuidClient: uuidClient,
                endpoint: endpoint,
                methode: methode,
                payloadJson: payloadJson,
                photoOctets: photoOctets,
                creeLeLocal: creeLeLocal,
                tentatives: tentatives,
                dernierMotif: dernierMotif,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuidClient,
                required String endpoint,
                Value<String> methode = const Value.absent(),
                required String payloadJson,
                Value<Uint8List?> photoOctets = const Value.absent(),
                required DateTime creeLeLocal,
                Value<int> tentatives = const Value.absent(),
                Value<String?> dernierMotif = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ActionsEnAttenteCompanion.insert(
                uuidClient: uuidClient,
                endpoint: endpoint,
                methode: methode,
                payloadJson: payloadJson,
                photoOctets: photoOctets,
                creeLeLocal: creeLeLocal,
                tentatives: tentatives,
                dernierMotif: dernierMotif,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ActionsEnAttenteTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $ActionsEnAttenteTable,
      ActionEnAttente,
      $$ActionsEnAttenteTableFilterComposer,
      $$ActionsEnAttenteTableOrderingComposer,
      $$ActionsEnAttenteTableAnnotationComposer,
      $$ActionsEnAttenteTableCreateCompanionBuilder,
      $$ActionsEnAttenteTableUpdateCompanionBuilder,
      (
        ActionEnAttente,
        BaseReferences<_$BaseOffline, $ActionsEnAttenteTable, ActionEnAttente>,
      ),
      ActionEnAttente,
      PrefetchHooks Function()
    >;
typedef $$ArretsPreprovisionnesTableCreateCompanionBuilder =
    ArretsPreprovisionnesCompanion Function({
      required String arretId,
      required String prestataireId,
      Value<String> nom,
      required String empreinteJeton,
      required String empreinteCode,
      required double siteLat,
      required double siteLon,
      required int montantAvance,
      required String devise,
      required bool photoExigee,
      Value<int> distanceMaxM,
      Value<String> statutLocal,
      Value<int> rowid,
    });
typedef $$ArretsPreprovisionnesTableUpdateCompanionBuilder =
    ArretsPreprovisionnesCompanion Function({
      Value<String> arretId,
      Value<String> prestataireId,
      Value<String> nom,
      Value<String> empreinteJeton,
      Value<String> empreinteCode,
      Value<double> siteLat,
      Value<double> siteLon,
      Value<int> montantAvance,
      Value<String> devise,
      Value<bool> photoExigee,
      Value<int> distanceMaxM,
      Value<String> statutLocal,
      Value<int> rowid,
    });

class $$ArretsPreprovisionnesTableFilterComposer
    extends Composer<_$BaseOffline, $ArretsPreprovisionnesTable> {
  $$ArretsPreprovisionnesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get arretId => $composableBuilder(
    column: $table.arretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prestataireId => $composableBuilder(
    column: $table.prestataireId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get siteLat => $composableBuilder(
    column: $table.siteLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get siteLon => $composableBuilder(
    column: $table.siteLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantAvance => $composableBuilder(
    column: $table.montantAvance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get photoExigee => $composableBuilder(
    column: $table.photoExigee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceMaxM => $composableBuilder(
    column: $table.distanceMaxM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statutLocal => $composableBuilder(
    column: $table.statutLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArretsPreprovisionnesTableOrderingComposer
    extends Composer<_$BaseOffline, $ArretsPreprovisionnesTable> {
  $$ArretsPreprovisionnesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get arretId => $composableBuilder(
    column: $table.arretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prestataireId => $composableBuilder(
    column: $table.prestataireId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nom => $composableBuilder(
    column: $table.nom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get siteLat => $composableBuilder(
    column: $table.siteLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get siteLon => $composableBuilder(
    column: $table.siteLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantAvance => $composableBuilder(
    column: $table.montantAvance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get photoExigee => $composableBuilder(
    column: $table.photoExigee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceMaxM => $composableBuilder(
    column: $table.distanceMaxM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statutLocal => $composableBuilder(
    column: $table.statutLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArretsPreprovisionnesTableAnnotationComposer
    extends Composer<_$BaseOffline, $ArretsPreprovisionnesTable> {
  $$ArretsPreprovisionnesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get arretId =>
      $composableBuilder(column: $table.arretId, builder: (column) => column);

  GeneratedColumn<String> get prestataireId => $composableBuilder(
    column: $table.prestataireId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get nom =>
      $composableBuilder(column: $table.nom, builder: (column) => column);

  GeneratedColumn<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => column,
  );

  GeneratedColumn<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => column,
  );

  GeneratedColumn<double> get siteLat =>
      $composableBuilder(column: $table.siteLat, builder: (column) => column);

  GeneratedColumn<double> get siteLon =>
      $composableBuilder(column: $table.siteLon, builder: (column) => column);

  GeneratedColumn<int> get montantAvance => $composableBuilder(
    column: $table.montantAvance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devise =>
      $composableBuilder(column: $table.devise, builder: (column) => column);

  GeneratedColumn<bool> get photoExigee => $composableBuilder(
    column: $table.photoExigee,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceMaxM => $composableBuilder(
    column: $table.distanceMaxM,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statutLocal => $composableBuilder(
    column: $table.statutLocal,
    builder: (column) => column,
  );
}

class $$ArretsPreprovisionnesTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $ArretsPreprovisionnesTable,
          ArretPreprovisionne,
          $$ArretsPreprovisionnesTableFilterComposer,
          $$ArretsPreprovisionnesTableOrderingComposer,
          $$ArretsPreprovisionnesTableAnnotationComposer,
          $$ArretsPreprovisionnesTableCreateCompanionBuilder,
          $$ArretsPreprovisionnesTableUpdateCompanionBuilder,
          (
            ArretPreprovisionne,
            BaseReferences<
              _$BaseOffline,
              $ArretsPreprovisionnesTable,
              ArretPreprovisionne
            >,
          ),
          ArretPreprovisionne,
          PrefetchHooks Function()
        > {
  $$ArretsPreprovisionnesTableTableManager(
    _$BaseOffline db,
    $ArretsPreprovisionnesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArretsPreprovisionnesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$ArretsPreprovisionnesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$ArretsPreprovisionnesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> arretId = const Value.absent(),
                Value<String> prestataireId = const Value.absent(),
                Value<String> nom = const Value.absent(),
                Value<String> empreinteJeton = const Value.absent(),
                Value<String> empreinteCode = const Value.absent(),
                Value<double> siteLat = const Value.absent(),
                Value<double> siteLon = const Value.absent(),
                Value<int> montantAvance = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<bool> photoExigee = const Value.absent(),
                Value<int> distanceMaxM = const Value.absent(),
                Value<String> statutLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArretsPreprovisionnesCompanion(
                arretId: arretId,
                prestataireId: prestataireId,
                nom: nom,
                empreinteJeton: empreinteJeton,
                empreinteCode: empreinteCode,
                siteLat: siteLat,
                siteLon: siteLon,
                montantAvance: montantAvance,
                devise: devise,
                photoExigee: photoExigee,
                distanceMaxM: distanceMaxM,
                statutLocal: statutLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String arretId,
                required String prestataireId,
                Value<String> nom = const Value.absent(),
                required String empreinteJeton,
                required String empreinteCode,
                required double siteLat,
                required double siteLon,
                required int montantAvance,
                required String devise,
                required bool photoExigee,
                Value<int> distanceMaxM = const Value.absent(),
                Value<String> statutLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArretsPreprovisionnesCompanion.insert(
                arretId: arretId,
                prestataireId: prestataireId,
                nom: nom,
                empreinteJeton: empreinteJeton,
                empreinteCode: empreinteCode,
                siteLat: siteLat,
                siteLon: siteLon,
                montantAvance: montantAvance,
                devise: devise,
                photoExigee: photoExigee,
                distanceMaxM: distanceMaxM,
                statutLocal: statutLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ArretsPreprovisionnesTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $ArretsPreprovisionnesTable,
      ArretPreprovisionne,
      $$ArretsPreprovisionnesTableFilterComposer,
      $$ArretsPreprovisionnesTableOrderingComposer,
      $$ArretsPreprovisionnesTableAnnotationComposer,
      $$ArretsPreprovisionnesTableCreateCompanionBuilder,
      $$ArretsPreprovisionnesTableUpdateCompanionBuilder,
      (
        ArretPreprovisionne,
        BaseReferences<
          _$BaseOffline,
          $ArretsPreprovisionnesTable,
          ArretPreprovisionne
        >,
      ),
      ArretPreprovisionne,
      PrefetchHooks Function()
    >;
typedef $$BrouillonsPanierTableCreateCompanionBuilder =
    BrouillonsPanierCompanion Function({
      required String zoneId,
      required String categorieSlug,
      required String lignesJson,
      Value<int> montantArticlesEstimeUnites,
      Value<String> devise,
      required DateTime majLeLocal,
      Value<int> rowid,
    });
typedef $$BrouillonsPanierTableUpdateCompanionBuilder =
    BrouillonsPanierCompanion Function({
      Value<String> zoneId,
      Value<String> categorieSlug,
      Value<String> lignesJson,
      Value<int> montantArticlesEstimeUnites,
      Value<String> devise,
      Value<DateTime> majLeLocal,
      Value<int> rowid,
    });

class $$BrouillonsPanierTableFilterComposer
    extends Composer<_$BaseOffline, $BrouillonsPanierTable> {
  $$BrouillonsPanierTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categorieSlug => $composableBuilder(
    column: $table.categorieSlug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lignesJson => $composableBuilder(
    column: $table.lignesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantArticlesEstimeUnites => $composableBuilder(
    column: $table.montantArticlesEstimeUnites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BrouillonsPanierTableOrderingComposer
    extends Composer<_$BaseOffline, $BrouillonsPanierTable> {
  $$BrouillonsPanierTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get zoneId => $composableBuilder(
    column: $table.zoneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categorieSlug => $composableBuilder(
    column: $table.categorieSlug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lignesJson => $composableBuilder(
    column: $table.lignesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantArticlesEstimeUnites => $composableBuilder(
    column: $table.montantArticlesEstimeUnites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BrouillonsPanierTableAnnotationComposer
    extends Composer<_$BaseOffline, $BrouillonsPanierTable> {
  $$BrouillonsPanierTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get zoneId =>
      $composableBuilder(column: $table.zoneId, builder: (column) => column);

  GeneratedColumn<String> get categorieSlug => $composableBuilder(
    column: $table.categorieSlug,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lignesJson => $composableBuilder(
    column: $table.lignesJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get montantArticlesEstimeUnites => $composableBuilder(
    column: $table.montantArticlesEstimeUnites,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devise =>
      $composableBuilder(column: $table.devise, builder: (column) => column);

  GeneratedColumn<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => column,
  );
}

class $$BrouillonsPanierTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $BrouillonsPanierTable,
          BrouillonPanier,
          $$BrouillonsPanierTableFilterComposer,
          $$BrouillonsPanierTableOrderingComposer,
          $$BrouillonsPanierTableAnnotationComposer,
          $$BrouillonsPanierTableCreateCompanionBuilder,
          $$BrouillonsPanierTableUpdateCompanionBuilder,
          (
            BrouillonPanier,
            BaseReferences<
              _$BaseOffline,
              $BrouillonsPanierTable,
              BrouillonPanier
            >,
          ),
          BrouillonPanier,
          PrefetchHooks Function()
        > {
  $$BrouillonsPanierTableTableManager(
    _$BaseOffline db,
    $BrouillonsPanierTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BrouillonsPanierTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BrouillonsPanierTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BrouillonsPanierTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> zoneId = const Value.absent(),
                Value<String> categorieSlug = const Value.absent(),
                Value<String> lignesJson = const Value.absent(),
                Value<int> montantArticlesEstimeUnites = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<DateTime> majLeLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BrouillonsPanierCompanion(
                zoneId: zoneId,
                categorieSlug: categorieSlug,
                lignesJson: lignesJson,
                montantArticlesEstimeUnites: montantArticlesEstimeUnites,
                devise: devise,
                majLeLocal: majLeLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String zoneId,
                required String categorieSlug,
                required String lignesJson,
                Value<int> montantArticlesEstimeUnites = const Value.absent(),
                Value<String> devise = const Value.absent(),
                required DateTime majLeLocal,
                Value<int> rowid = const Value.absent(),
              }) => BrouillonsPanierCompanion.insert(
                zoneId: zoneId,
                categorieSlug: categorieSlug,
                lignesJson: lignesJson,
                montantArticlesEstimeUnites: montantArticlesEstimeUnites,
                devise: devise,
                majLeLocal: majLeLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BrouillonsPanierTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $BrouillonsPanierTable,
      BrouillonPanier,
      $$BrouillonsPanierTableFilterComposer,
      $$BrouillonsPanierTableOrderingComposer,
      $$BrouillonsPanierTableAnnotationComposer,
      $$BrouillonsPanierTableCreateCompanionBuilder,
      $$BrouillonsPanierTableUpdateCompanionBuilder,
      (
        BrouillonPanier,
        BaseReferences<_$BaseOffline, $BrouillonsPanierTable, BrouillonPanier>,
      ),
      BrouillonPanier,
      PrefetchHooks Function()
    >;
typedef $$CommandesCacheTableCreateCompanionBuilder =
    CommandesCacheCompanion Function({
      required String commandeId,
      required String etat,
      Value<String> etatCle,
      Value<int> collectesFaites,
      Value<int> collectesTotal,
      required String codeLivraison,
      required String jetonReception,
      Value<int> totalUnites,
      Value<String> devise,
      Value<double?> positionLat,
      Value<double?> positionLon,
      Value<int?> positionAgeS,
      required DateTime majLeLocal,
      Value<int> rowid,
    });
typedef $$CommandesCacheTableUpdateCompanionBuilder =
    CommandesCacheCompanion Function({
      Value<String> commandeId,
      Value<String> etat,
      Value<String> etatCle,
      Value<int> collectesFaites,
      Value<int> collectesTotal,
      Value<String> codeLivraison,
      Value<String> jetonReception,
      Value<int> totalUnites,
      Value<String> devise,
      Value<double?> positionLat,
      Value<double?> positionLon,
      Value<int?> positionAgeS,
      Value<DateTime> majLeLocal,
      Value<int> rowid,
    });

class $$CommandesCacheTableFilterComposer
    extends Composer<_$BaseOffline, $CommandesCacheTable> {
  $$CommandesCacheTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etat => $composableBuilder(
    column: $table.etat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etatCle => $composableBuilder(
    column: $table.etatCle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get collectesFaites => $composableBuilder(
    column: $table.collectesFaites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get collectesTotal => $composableBuilder(
    column: $table.collectesTotal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get codeLivraison => $composableBuilder(
    column: $table.codeLivraison,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get jetonReception => $composableBuilder(
    column: $table.jetonReception,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalUnites => $composableBuilder(
    column: $table.totalUnites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get positionLon => $composableBuilder(
    column: $table.positionLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionAgeS => $composableBuilder(
    column: $table.positionAgeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CommandesCacheTableOrderingComposer
    extends Composer<_$BaseOffline, $CommandesCacheTable> {
  $$CommandesCacheTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etat => $composableBuilder(
    column: $table.etat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etatCle => $composableBuilder(
    column: $table.etatCle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get collectesFaites => $composableBuilder(
    column: $table.collectesFaites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get collectesTotal => $composableBuilder(
    column: $table.collectesTotal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get codeLivraison => $composableBuilder(
    column: $table.codeLivraison,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get jetonReception => $composableBuilder(
    column: $table.jetonReception,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalUnites => $composableBuilder(
    column: $table.totalUnites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get positionLon => $composableBuilder(
    column: $table.positionLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionAgeS => $composableBuilder(
    column: $table.positionAgeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CommandesCacheTableAnnotationComposer
    extends Composer<_$BaseOffline, $CommandesCacheTable> {
  $$CommandesCacheTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etat =>
      $composableBuilder(column: $table.etat, builder: (column) => column);

  GeneratedColumn<String> get etatCle =>
      $composableBuilder(column: $table.etatCle, builder: (column) => column);

  GeneratedColumn<int> get collectesFaites => $composableBuilder(
    column: $table.collectesFaites,
    builder: (column) => column,
  );

  GeneratedColumn<int> get collectesTotal => $composableBuilder(
    column: $table.collectesTotal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get codeLivraison => $composableBuilder(
    column: $table.codeLivraison,
    builder: (column) => column,
  );

  GeneratedColumn<String> get jetonReception => $composableBuilder(
    column: $table.jetonReception,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalUnites => $composableBuilder(
    column: $table.totalUnites,
    builder: (column) => column,
  );

  GeneratedColumn<String> get devise =>
      $composableBuilder(column: $table.devise, builder: (column) => column);

  GeneratedColumn<double> get positionLat => $composableBuilder(
    column: $table.positionLat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get positionLon => $composableBuilder(
    column: $table.positionLon,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionAgeS => $composableBuilder(
    column: $table.positionAgeS,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => column,
  );
}

class $$CommandesCacheTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $CommandesCacheTable,
          CommandeCache,
          $$CommandesCacheTableFilterComposer,
          $$CommandesCacheTableOrderingComposer,
          $$CommandesCacheTableAnnotationComposer,
          $$CommandesCacheTableCreateCompanionBuilder,
          $$CommandesCacheTableUpdateCompanionBuilder,
          (
            CommandeCache,
            BaseReferences<_$BaseOffline, $CommandesCacheTable, CommandeCache>,
          ),
          CommandeCache,
          PrefetchHooks Function()
        > {
  $$CommandesCacheTableTableManager(
    _$BaseOffline db,
    $CommandesCacheTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CommandesCacheTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CommandesCacheTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CommandesCacheTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> commandeId = const Value.absent(),
                Value<String> etat = const Value.absent(),
                Value<String> etatCle = const Value.absent(),
                Value<int> collectesFaites = const Value.absent(),
                Value<int> collectesTotal = const Value.absent(),
                Value<String> codeLivraison = const Value.absent(),
                Value<String> jetonReception = const Value.absent(),
                Value<int> totalUnites = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<double?> positionLat = const Value.absent(),
                Value<double?> positionLon = const Value.absent(),
                Value<int?> positionAgeS = const Value.absent(),
                Value<DateTime> majLeLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CommandesCacheCompanion(
                commandeId: commandeId,
                etat: etat,
                etatCle: etatCle,
                collectesFaites: collectesFaites,
                collectesTotal: collectesTotal,
                codeLivraison: codeLivraison,
                jetonReception: jetonReception,
                totalUnites: totalUnites,
                devise: devise,
                positionLat: positionLat,
                positionLon: positionLon,
                positionAgeS: positionAgeS,
                majLeLocal: majLeLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String commandeId,
                required String etat,
                Value<String> etatCle = const Value.absent(),
                Value<int> collectesFaites = const Value.absent(),
                Value<int> collectesTotal = const Value.absent(),
                required String codeLivraison,
                required String jetonReception,
                Value<int> totalUnites = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<double?> positionLat = const Value.absent(),
                Value<double?> positionLon = const Value.absent(),
                Value<int?> positionAgeS = const Value.absent(),
                required DateTime majLeLocal,
                Value<int> rowid = const Value.absent(),
              }) => CommandesCacheCompanion.insert(
                commandeId: commandeId,
                etat: etat,
                etatCle: etatCle,
                collectesFaites: collectesFaites,
                collectesTotal: collectesTotal,
                codeLivraison: codeLivraison,
                jetonReception: jetonReception,
                totalUnites: totalUnites,
                devise: devise,
                positionLat: positionLat,
                positionLon: positionLon,
                positionAgeS: positionAgeS,
                majLeLocal: majLeLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CommandesCacheTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $CommandesCacheTable,
      CommandeCache,
      $$CommandesCacheTableFilterComposer,
      $$CommandesCacheTableOrderingComposer,
      $$CommandesCacheTableAnnotationComposer,
      $$CommandesCacheTableCreateCompanionBuilder,
      $$CommandesCacheTableUpdateCompanionBuilder,
      (
        CommandeCache,
        BaseReferences<_$BaseOffline, $CommandesCacheTable, CommandeCache>,
      ),
      CommandeCache,
      PrefetchHooks Function()
    >;

class $BaseOfflineManager {
  final _$BaseOffline _db;
  $BaseOfflineManager(this._db);
  $$ActionsEnAttenteTableTableManager get actionsEnAttente =>
      $$ActionsEnAttenteTableTableManager(_db, _db.actionsEnAttente);
  $$ArretsPreprovisionnesTableTableManager get arretsPreprovisionnes =>
      $$ArretsPreprovisionnesTableTableManager(_db, _db.arretsPreprovisionnes);
  $$BrouillonsPanierTableTableManager get brouillonsPanier =>
      $$BrouillonsPanierTableTableManager(_db, _db.brouillonsPanier);
  $$CommandesCacheTableTableManager get commandesCache =>
      $$CommandesCacheTableTableManager(_db, _db.commandesCache);
}
