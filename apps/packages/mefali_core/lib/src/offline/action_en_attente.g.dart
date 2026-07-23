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
    empreinteJeton,
    empreinteCode,
    siteLat,
    siteLon,
    montantAvance,
    devise,
    photoExigee,
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

  /// Coche optimiste locale avant réconciliation serveur
  /// (`a_collecter` | `collecte`).
  final String statutLocal;
  const ArretPreprovisionne({
    required this.arretId,
    required this.prestataireId,
    required this.empreinteJeton,
    required this.empreinteCode,
    required this.siteLat,
    required this.siteLon,
    required this.montantAvance,
    required this.devise,
    required this.photoExigee,
    required this.statutLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['arret_id'] = Variable<String>(arretId);
    map['prestataire_id'] = Variable<String>(prestataireId);
    map['empreinte_jeton'] = Variable<String>(empreinteJeton);
    map['empreinte_code'] = Variable<String>(empreinteCode);
    map['site_lat'] = Variable<double>(siteLat);
    map['site_lon'] = Variable<double>(siteLon);
    map['montant_avance'] = Variable<int>(montantAvance);
    map['devise'] = Variable<String>(devise);
    map['photo_exigee'] = Variable<bool>(photoExigee);
    map['statut_local'] = Variable<String>(statutLocal);
    return map;
  }

  ArretsPreprovisionnesCompanion toCompanion(bool nullToAbsent) {
    return ArretsPreprovisionnesCompanion(
      arretId: Value(arretId),
      prestataireId: Value(prestataireId),
      empreinteJeton: Value(empreinteJeton),
      empreinteCode: Value(empreinteCode),
      siteLat: Value(siteLat),
      siteLon: Value(siteLon),
      montantAvance: Value(montantAvance),
      devise: Value(devise),
      photoExigee: Value(photoExigee),
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
      empreinteJeton: serializer.fromJson<String>(json['empreinteJeton']),
      empreinteCode: serializer.fromJson<String>(json['empreinteCode']),
      siteLat: serializer.fromJson<double>(json['siteLat']),
      siteLon: serializer.fromJson<double>(json['siteLon']),
      montantAvance: serializer.fromJson<int>(json['montantAvance']),
      devise: serializer.fromJson<String>(json['devise']),
      photoExigee: serializer.fromJson<bool>(json['photoExigee']),
      statutLocal: serializer.fromJson<String>(json['statutLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'arretId': serializer.toJson<String>(arretId),
      'prestataireId': serializer.toJson<String>(prestataireId),
      'empreinteJeton': serializer.toJson<String>(empreinteJeton),
      'empreinteCode': serializer.toJson<String>(empreinteCode),
      'siteLat': serializer.toJson<double>(siteLat),
      'siteLon': serializer.toJson<double>(siteLon),
      'montantAvance': serializer.toJson<int>(montantAvance),
      'devise': serializer.toJson<String>(devise),
      'photoExigee': serializer.toJson<bool>(photoExigee),
      'statutLocal': serializer.toJson<String>(statutLocal),
    };
  }

  ArretPreprovisionne copyWith({
    String? arretId,
    String? prestataireId,
    String? empreinteJeton,
    String? empreinteCode,
    double? siteLat,
    double? siteLon,
    int? montantAvance,
    String? devise,
    bool? photoExigee,
    String? statutLocal,
  }) => ArretPreprovisionne(
    arretId: arretId ?? this.arretId,
    prestataireId: prestataireId ?? this.prestataireId,
    empreinteJeton: empreinteJeton ?? this.empreinteJeton,
    empreinteCode: empreinteCode ?? this.empreinteCode,
    siteLat: siteLat ?? this.siteLat,
    siteLon: siteLon ?? this.siteLon,
    montantAvance: montantAvance ?? this.montantAvance,
    devise: devise ?? this.devise,
    photoExigee: photoExigee ?? this.photoExigee,
    statutLocal: statutLocal ?? this.statutLocal,
  );
  ArretPreprovisionne copyWithCompanion(ArretsPreprovisionnesCompanion data) {
    return ArretPreprovisionne(
      arretId: data.arretId.present ? data.arretId.value : this.arretId,
      prestataireId: data.prestataireId.present
          ? data.prestataireId.value
          : this.prestataireId,
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
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('montantAvance: $montantAvance, ')
          ..write('devise: $devise, ')
          ..write('photoExigee: $photoExigee, ')
          ..write('statutLocal: $statutLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    arretId,
    prestataireId,
    empreinteJeton,
    empreinteCode,
    siteLat,
    siteLon,
    montantAvance,
    devise,
    photoExigee,
    statutLocal,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArretPreprovisionne &&
          other.arretId == this.arretId &&
          other.prestataireId == this.prestataireId &&
          other.empreinteJeton == this.empreinteJeton &&
          other.empreinteCode == this.empreinteCode &&
          other.siteLat == this.siteLat &&
          other.siteLon == this.siteLon &&
          other.montantAvance == this.montantAvance &&
          other.devise == this.devise &&
          other.photoExigee == this.photoExigee &&
          other.statutLocal == this.statutLocal);
}

class ArretsPreprovisionnesCompanion
    extends UpdateCompanion<ArretPreprovisionne> {
  final Value<String> arretId;
  final Value<String> prestataireId;
  final Value<String> empreinteJeton;
  final Value<String> empreinteCode;
  final Value<double> siteLat;
  final Value<double> siteLon;
  final Value<int> montantAvance;
  final Value<String> devise;
  final Value<bool> photoExigee;
  final Value<String> statutLocal;
  final Value<int> rowid;
  const ArretsPreprovisionnesCompanion({
    this.arretId = const Value.absent(),
    this.prestataireId = const Value.absent(),
    this.empreinteJeton = const Value.absent(),
    this.empreinteCode = const Value.absent(),
    this.siteLat = const Value.absent(),
    this.siteLon = const Value.absent(),
    this.montantAvance = const Value.absent(),
    this.devise = const Value.absent(),
    this.photoExigee = const Value.absent(),
    this.statutLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArretsPreprovisionnesCompanion.insert({
    required String arretId,
    required String prestataireId,
    required String empreinteJeton,
    required String empreinteCode,
    required double siteLat,
    required double siteLon,
    required int montantAvance,
    required String devise,
    required bool photoExigee,
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
    Expression<String>? empreinteJeton,
    Expression<String>? empreinteCode,
    Expression<double>? siteLat,
    Expression<double>? siteLon,
    Expression<int>? montantAvance,
    Expression<String>? devise,
    Expression<bool>? photoExigee,
    Expression<String>? statutLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (arretId != null) 'arret_id': arretId,
      if (prestataireId != null) 'prestataire_id': prestataireId,
      if (empreinteJeton != null) 'empreinte_jeton': empreinteJeton,
      if (empreinteCode != null) 'empreinte_code': empreinteCode,
      if (siteLat != null) 'site_lat': siteLat,
      if (siteLon != null) 'site_lon': siteLon,
      if (montantAvance != null) 'montant_avance': montantAvance,
      if (devise != null) 'devise': devise,
      if (photoExigee != null) 'photo_exigee': photoExigee,
      if (statutLocal != null) 'statut_local': statutLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArretsPreprovisionnesCompanion copyWith({
    Value<String>? arretId,
    Value<String>? prestataireId,
    Value<String>? empreinteJeton,
    Value<String>? empreinteCode,
    Value<double>? siteLat,
    Value<double>? siteLon,
    Value<int>? montantAvance,
    Value<String>? devise,
    Value<bool>? photoExigee,
    Value<String>? statutLocal,
    Value<int>? rowid,
  }) {
    return ArretsPreprovisionnesCompanion(
      arretId: arretId ?? this.arretId,
      prestataireId: prestataireId ?? this.prestataireId,
      empreinteJeton: empreinteJeton ?? this.empreinteJeton,
      empreinteCode: empreinteCode ?? this.empreinteCode,
      siteLat: siteLat ?? this.siteLat,
      siteLon: siteLon ?? this.siteLon,
      montantAvance: montantAvance ?? this.montantAvance,
      devise: devise ?? this.devise,
      photoExigee: photoExigee ?? this.photoExigee,
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
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('siteLat: $siteLat, ')
          ..write('siteLon: $siteLon, ')
          ..write('montantAvance: $montantAvance, ')
          ..write('devise: $devise, ')
          ..write('photoExigee: $photoExigee, ')
          ..write('statutLocal: $statutLocal, ')
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    actionsEnAttente,
    arretsPreprovisionnes,
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
      required String empreinteJeton,
      required String empreinteCode,
      required double siteLat,
      required double siteLon,
      required int montantAvance,
      required String devise,
      required bool photoExigee,
      Value<String> statutLocal,
      Value<int> rowid,
    });
typedef $$ArretsPreprovisionnesTableUpdateCompanionBuilder =
    ArretsPreprovisionnesCompanion Function({
      Value<String> arretId,
      Value<String> prestataireId,
      Value<String> empreinteJeton,
      Value<String> empreinteCode,
      Value<double> siteLat,
      Value<double> siteLon,
      Value<int> montantAvance,
      Value<String> devise,
      Value<bool> photoExigee,
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
                Value<String> empreinteJeton = const Value.absent(),
                Value<String> empreinteCode = const Value.absent(),
                Value<double> siteLat = const Value.absent(),
                Value<double> siteLon = const Value.absent(),
                Value<int> montantAvance = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<bool> photoExigee = const Value.absent(),
                Value<String> statutLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArretsPreprovisionnesCompanion(
                arretId: arretId,
                prestataireId: prestataireId,
                empreinteJeton: empreinteJeton,
                empreinteCode: empreinteCode,
                siteLat: siteLat,
                siteLon: siteLon,
                montantAvance: montantAvance,
                devise: devise,
                photoExigee: photoExigee,
                statutLocal: statutLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String arretId,
                required String prestataireId,
                required String empreinteJeton,
                required String empreinteCode,
                required double siteLat,
                required double siteLon,
                required int montantAvance,
                required String devise,
                required bool photoExigee,
                Value<String> statutLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArretsPreprovisionnesCompanion.insert(
                arretId: arretId,
                prestataireId: prestataireId,
                empreinteJeton: empreinteJeton,
                empreinteCode: empreinteCode,
                siteLat: siteLat,
                siteLon: siteLon,
                montantAvance: montantAvance,
                devise: devise,
                photoExigee: photoExigee,
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

class $BaseOfflineManager {
  final _$BaseOffline _db;
  $BaseOfflineManager(this._db);
  $$ActionsEnAttenteTableTableManager get actionsEnAttente =>
      $$ActionsEnAttenteTableTableManager(_db, _db.actionsEnAttente);
  $$ArretsPreprovisionnesTableTableManager get arretsPreprovisionnes =>
      $$ArretsPreprovisionnesTableTableManager(_db, _db.arretsPreprovisionnes);
}
