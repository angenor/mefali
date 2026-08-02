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
  static const VerificationMeta _multipartMeta = const VerificationMeta(
    'multipart',
  );
  @override
  late final GeneratedColumn<bool> multipart = GeneratedColumn<bool>(
    'multipart',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("multipart" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('en_attente'),
  );
  static const VerificationMeta _refuseLeLocalMeta = const VerificationMeta(
    'refuseLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> refuseLeLocal =
      GeneratedColumn<DateTime>(
        'refuse_le_local',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
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
    multipart,
    statut,
    refuseLeLocal,
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
    if (data.containsKey('multipart')) {
      context.handle(
        _multipartMeta,
        multipart.isAcceptableOrUnknown(data['multipart']!, _multipartMeta),
      );
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('refuse_le_local')) {
      context.handle(
        _refuseLeLocalMeta,
        refuseLeLocal.isAcceptableOrUnknown(
          data['refuse_le_local']!,
          _refuseLeLocalMeta,
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
      multipart: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}multipart'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      refuseLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}refuse_le_local'],
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

  /// L'action voyage-t-elle en `multipart/form-data` ?
  ///
  /// **Toutes ne le sont pas, et c'est le contrat qui le dit** : seules celles
  /// qui peuvent porter une photo (collecte, substitution, remise, preuve) sont
  /// multipart ; les transitions d'arrêt attendent du JSON. Envoyer tout de la
  /// même façon faisait échouer la moitié des endpoints au drain — bug attrapé
  /// par le test qui fait foi du module.
  final bool multipart;

  /// `en_attente` (rejouable) ou `refuse` (refus DÉFINITIF du serveur).
  ///
  /// Les deux issues d'un rejeu n'ont rien à voir (FR-085) : un échec RÉSEAU se
  /// réessaie indéfiniment ; un refus MÉTIER — course réassignée, arrêt déjà
  /// collecté — ne se réessaiera jamais avec succès, et insister le ferait
  /// compter comme une panne. Une action refusée sort donc de la file… mais pas
  /// de la trace : Yao doit pouvoir savoir ce qui est arrivé à une collecte
  /// qu'il a réellement faite (FR-086).
  final String statut;

  /// Instant LOCAL du refus définitif — l'ordre du journal de réconciliation.
  final DateTime? refuseLeLocal;
  const ActionEnAttente({
    required this.uuidClient,
    required this.endpoint,
    required this.methode,
    required this.payloadJson,
    this.photoOctets,
    required this.creeLeLocal,
    required this.tentatives,
    this.dernierMotif,
    required this.multipart,
    required this.statut,
    this.refuseLeLocal,
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
    map['multipart'] = Variable<bool>(multipart);
    map['statut'] = Variable<String>(statut);
    if (!nullToAbsent || refuseLeLocal != null) {
      map['refuse_le_local'] = Variable<DateTime>(refuseLeLocal);
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
      multipart: Value(multipart),
      statut: Value(statut),
      refuseLeLocal: refuseLeLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(refuseLeLocal),
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
      multipart: serializer.fromJson<bool>(json['multipart']),
      statut: serializer.fromJson<String>(json['statut']),
      refuseLeLocal: serializer.fromJson<DateTime?>(json['refuseLeLocal']),
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
      'multipart': serializer.toJson<bool>(multipart),
      'statut': serializer.toJson<String>(statut),
      'refuseLeLocal': serializer.toJson<DateTime?>(refuseLeLocal),
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
    bool? multipart,
    String? statut,
    Value<DateTime?> refuseLeLocal = const Value.absent(),
  }) => ActionEnAttente(
    uuidClient: uuidClient ?? this.uuidClient,
    endpoint: endpoint ?? this.endpoint,
    methode: methode ?? this.methode,
    payloadJson: payloadJson ?? this.payloadJson,
    photoOctets: photoOctets.present ? photoOctets.value : this.photoOctets,
    creeLeLocal: creeLeLocal ?? this.creeLeLocal,
    tentatives: tentatives ?? this.tentatives,
    dernierMotif: dernierMotif.present ? dernierMotif.value : this.dernierMotif,
    multipart: multipart ?? this.multipart,
    statut: statut ?? this.statut,
    refuseLeLocal: refuseLeLocal.present
        ? refuseLeLocal.value
        : this.refuseLeLocal,
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
      multipart: data.multipart.present ? data.multipart.value : this.multipart,
      statut: data.statut.present ? data.statut.value : this.statut,
      refuseLeLocal: data.refuseLeLocal.present
          ? data.refuseLeLocal.value
          : this.refuseLeLocal,
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
          ..write('dernierMotif: $dernierMotif, ')
          ..write('multipart: $multipart, ')
          ..write('statut: $statut, ')
          ..write('refuseLeLocal: $refuseLeLocal')
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
    multipart,
    statut,
    refuseLeLocal,
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
          other.dernierMotif == this.dernierMotif &&
          other.multipart == this.multipart &&
          other.statut == this.statut &&
          other.refuseLeLocal == this.refuseLeLocal);
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
  final Value<bool> multipart;
  final Value<String> statut;
  final Value<DateTime?> refuseLeLocal;
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
    this.multipart = const Value.absent(),
    this.statut = const Value.absent(),
    this.refuseLeLocal = const Value.absent(),
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
    this.multipart = const Value.absent(),
    this.statut = const Value.absent(),
    this.refuseLeLocal = const Value.absent(),
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
    Expression<bool>? multipart,
    Expression<String>? statut,
    Expression<DateTime>? refuseLeLocal,
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
      if (multipart != null) 'multipart': multipart,
      if (statut != null) 'statut': statut,
      if (refuseLeLocal != null) 'refuse_le_local': refuseLeLocal,
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
    Value<bool>? multipart,
    Value<String>? statut,
    Value<DateTime?>? refuseLeLocal,
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
      multipart: multipart ?? this.multipart,
      statut: statut ?? this.statut,
      refuseLeLocal: refuseLeLocal ?? this.refuseLeLocal,
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
    if (multipart.present) {
      map['multipart'] = Variable<bool>(multipart.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (refuseLeLocal.present) {
      map['refuse_le_local'] = Variable<DateTime>(refuseLeLocal.value);
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
          ..write('multipart: $multipart, ')
          ..write('statut: $statut, ')
          ..write('refuseLeLocal: $refuseLeLocal, ')
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
  static const VerificationMeta _montantArticlesUnitesMeta =
      const VerificationMeta('montantArticlesUnites');
  @override
  late final GeneratedColumn<int> montantArticlesUnites = GeneratedColumn<int>(
    'montant_articles_unites',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retenueAppliqueeUnitesMeta =
      const VerificationMeta('retenueAppliqueeUnites');
  @override
  late final GeneratedColumn<int> retenueAppliqueeUnites = GeneratedColumn<int>(
    'retenue_appliquee_unites',
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
    montantArticlesUnites,
    retenueAppliqueeUnites,
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
    if (data.containsKey('montant_articles_unites')) {
      context.handle(
        _montantArticlesUnitesMeta,
        montantArticlesUnites.isAcceptableOrUnknown(
          data['montant_articles_unites']!,
          _montantArticlesUnitesMeta,
        ),
      );
    }
    if (data.containsKey('retenue_appliquee_unites')) {
      context.handle(
        _retenueAppliqueeUnitesMeta,
        retenueAppliqueeUnites.isAcceptableOrUnknown(
          data['retenue_appliquee_unites']!,
          _retenueAppliqueeUnitesMeta,
        ),
      );
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
      montantArticlesUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_articles_unites'],
      )!,
      retenueAppliqueeUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retenue_appliquee_unites'],
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

  /// Montant avancé (unités mineures) — **net de retenue vendeur**.
  final int montantAvance;

  /// Articles bruts, AVANT retenue VND-08 (cycle PAY 011, FR-092).
  ///
  /// Défaut `0` : une course déjà en cache au moment de la mise à jour n'a pas
  /// cette valeur, et l'app retombe alors sur [montantAvance] — le net, qui
  /// reste juste. Mieux vaut une explication absente qu'un montant faux.
  final int montantArticlesUnites;

  /// Part prise en charge par le vendeur (VND-08), `0` sinon.
  final int retenueAppliqueeUnites;

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
    required this.montantArticlesUnites,
    required this.retenueAppliqueeUnites,
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
    map['montant_articles_unites'] = Variable<int>(montantArticlesUnites);
    map['retenue_appliquee_unites'] = Variable<int>(retenueAppliqueeUnites);
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
      montantArticlesUnites: Value(montantArticlesUnites),
      retenueAppliqueeUnites: Value(retenueAppliqueeUnites),
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
      montantArticlesUnites: serializer.fromJson<int>(
        json['montantArticlesUnites'],
      ),
      retenueAppliqueeUnites: serializer.fromJson<int>(
        json['retenueAppliqueeUnites'],
      ),
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
      'montantArticlesUnites': serializer.toJson<int>(montantArticlesUnites),
      'retenueAppliqueeUnites': serializer.toJson<int>(retenueAppliqueeUnites),
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
    int? montantArticlesUnites,
    int? retenueAppliqueeUnites,
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
    montantArticlesUnites: montantArticlesUnites ?? this.montantArticlesUnites,
    retenueAppliqueeUnites:
        retenueAppliqueeUnites ?? this.retenueAppliqueeUnites,
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
      montantArticlesUnites: data.montantArticlesUnites.present
          ? data.montantArticlesUnites.value
          : this.montantArticlesUnites,
      retenueAppliqueeUnites: data.retenueAppliqueeUnites.present
          ? data.retenueAppliqueeUnites.value
          : this.retenueAppliqueeUnites,
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
          ..write('montantArticlesUnites: $montantArticlesUnites, ')
          ..write('retenueAppliqueeUnites: $retenueAppliqueeUnites, ')
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
    montantArticlesUnites,
    retenueAppliqueeUnites,
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
          other.montantArticlesUnites == this.montantArticlesUnites &&
          other.retenueAppliqueeUnites == this.retenueAppliqueeUnites &&
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
  final Value<int> montantArticlesUnites;
  final Value<int> retenueAppliqueeUnites;
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
    this.montantArticlesUnites = const Value.absent(),
    this.retenueAppliqueeUnites = const Value.absent(),
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
    this.montantArticlesUnites = const Value.absent(),
    this.retenueAppliqueeUnites = const Value.absent(),
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
    Expression<int>? montantArticlesUnites,
    Expression<int>? retenueAppliqueeUnites,
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
      if (montantArticlesUnites != null)
        'montant_articles_unites': montantArticlesUnites,
      if (retenueAppliqueeUnites != null)
        'retenue_appliquee_unites': retenueAppliqueeUnites,
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
    Value<int>? montantArticlesUnites,
    Value<int>? retenueAppliqueeUnites,
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
      montantArticlesUnites:
          montantArticlesUnites ?? this.montantArticlesUnites,
      retenueAppliqueeUnites:
          retenueAppliqueeUnites ?? this.retenueAppliqueeUnites,
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
    if (montantArticlesUnites.present) {
      map['montant_articles_unites'] = Variable<int>(
        montantArticlesUnites.value,
      );
    }
    if (retenueAppliqueeUnites.present) {
      map['retenue_appliquee_unites'] = Variable<int>(
        retenueAppliqueeUnites.value,
      );
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
          ..write('montantArticlesUnites: $montantArticlesUnites, ')
          ..write('retenueAppliqueeUnites: $retenueAppliqueeUnites, ')
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

class $CourseCacheTableTable extends CourseCacheTable
    with TableInfo<$CourseCacheTableTable, CourseCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CourseCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _livraisonIdMeta = const VerificationMeta(
    'livraisonId',
  );
  @override
  late final GeneratedColumn<String> livraisonId = GeneratedColumn<String>(
    'livraison_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _clientNomUsageMeta = const VerificationMeta(
    'clientNomUsage',
  );
  @override
  late final GeneratedColumn<String> clientNomUsage = GeneratedColumn<String>(
    'client_nom_usage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _clientTelephoneMeta = const VerificationMeta(
    'clientTelephone',
  );
  @override
  late final GeneratedColumn<String> clientTelephone = GeneratedColumn<String>(
    'client_telephone',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repereTexteMeta = const VerificationMeta(
    'repereTexte',
  );
  @override
  late final GeneratedColumn<String> repereTexte = GeneratedColumn<String>(
    'repere_texte',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repereVocalFichierMeta =
      const VerificationMeta('repereVocalFichier');
  @override
  late final GeneratedColumn<String> repereVocalFichier =
      GeneratedColumn<String>(
        'repere_vocal_fichier',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _repereVocalDureeSMeta = const VerificationMeta(
    'repereVocalDureeS',
  );
  @override
  late final GeneratedColumn<int> repereVocalDureeS = GeneratedColumn<int>(
    'repere_vocal_duree_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lieuLatMeta = const VerificationMeta(
    'lieuLat',
  );
  @override
  late final GeneratedColumn<double> lieuLat = GeneratedColumn<double>(
    'lieu_lat',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lieuLonMeta = const VerificationMeta(
    'lieuLon',
  );
  @override
  late final GeneratedColumn<double> lieuLon = GeneratedColumn<double>(
    'lieu_lon',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _depotAutoriseMeta = const VerificationMeta(
    'depotAutorise',
  );
  @override
  late final GeneratedColumn<bool> depotAutorise = GeneratedColumn<bool>(
    'depot_autorise',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("depot_autorise" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
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
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _essaisConsommesMeta = const VerificationMeta(
    'essaisConsommes',
  );
  @override
  late final GeneratedColumn<int> essaisConsommes = GeneratedColumn<int>(
    'essais_consommes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _essaisMaxMeta = const VerificationMeta(
    'essaisMax',
  );
  @override
  late final GeneratedColumn<int> essaisMax = GeneratedColumn<int>(
    'essais_max',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _codeBloqueMeta = const VerificationMeta(
    'codeBloque',
  );
  @override
  late final GeneratedColumn<bool> codeBloque = GeneratedColumn<bool>(
    'code_bloque',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("code_bloque" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _montantAEncaisserUnitesMeta =
      const VerificationMeta('montantAEncaisserUnites');
  @override
  late final GeneratedColumn<int> montantAEncaisserUnites =
      GeneratedColumn<int>(
        'montant_a_encaisser_unites',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _modePaiementMeta = const VerificationMeta(
    'modePaiement',
  );
  @override
  late final GeneratedColumn<String> modePaiement = GeneratedColumn<String>(
    'mode_paiement',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('cash'),
  );
  static const VerificationMeta _seuilsPreuvesJsonMeta = const VerificationMeta(
    'seuilsPreuvesJson',
  );
  @override
  late final GeneratedColumn<String> seuilsPreuvesJson =
      GeneratedColumn<String>(
        'seuils_preuves_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        defaultValue: const Constant('{}'),
      );
  static const VerificationMeta _arretRemiseIdMeta = const VerificationMeta(
    'arretRemiseId',
  );
  @override
  late final GeneratedColumn<String> arretRemiseId = GeneratedColumn<String>(
    'arret_remise_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _arretRemiseStatutMeta = const VerificationMeta(
    'arretRemiseStatut',
  );
  @override
  late final GeneratedColumn<String> arretRemiseStatut =
      GeneratedColumn<String>(
        'arret_remise_statut',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _arriveChezClientLeMeta =
      const VerificationMeta('arriveChezClientLe');
  @override
  late final GeneratedColumn<DateTime> arriveChezClientLe =
      GeneratedColumn<DateTime>(
        'arrive_chez_client_le',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _remiseValideeLocalementLeMeta =
      const VerificationMeta('remiseValideeLocalementLe');
  @override
  late final GeneratedColumn<DateTime> remiseValideeLocalementLe =
      GeneratedColumn<DateTime>(
        'remise_validee_localement_le',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
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
    livraisonId,
    commandeId,
    etat,
    devise,
    clientNomUsage,
    clientTelephone,
    repereTexte,
    repereVocalFichier,
    repereVocalDureeS,
    lieuLat,
    lieuLon,
    depotAutorise,
    empreinteCode,
    empreinteJeton,
    essaisConsommes,
    essaisMax,
    codeBloque,
    montantAEncaisserUnites,
    modePaiement,
    seuilsPreuvesJson,
    arretRemiseId,
    arretRemiseStatut,
    arriveChezClientLe,
    remiseValideeLocalementLe,
    majLeLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'course_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CourseCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('livraison_id')) {
      context.handle(
        _livraisonIdMeta,
        livraisonId.isAcceptableOrUnknown(
          data['livraison_id']!,
          _livraisonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_livraisonIdMeta);
    }
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
    if (data.containsKey('devise')) {
      context.handle(
        _deviseMeta,
        devise.isAcceptableOrUnknown(data['devise']!, _deviseMeta),
      );
    }
    if (data.containsKey('client_nom_usage')) {
      context.handle(
        _clientNomUsageMeta,
        clientNomUsage.isAcceptableOrUnknown(
          data['client_nom_usage']!,
          _clientNomUsageMeta,
        ),
      );
    }
    if (data.containsKey('client_telephone')) {
      context.handle(
        _clientTelephoneMeta,
        clientTelephone.isAcceptableOrUnknown(
          data['client_telephone']!,
          _clientTelephoneMeta,
        ),
      );
    }
    if (data.containsKey('repere_texte')) {
      context.handle(
        _repereTexteMeta,
        repereTexte.isAcceptableOrUnknown(
          data['repere_texte']!,
          _repereTexteMeta,
        ),
      );
    }
    if (data.containsKey('repere_vocal_fichier')) {
      context.handle(
        _repereVocalFichierMeta,
        repereVocalFichier.isAcceptableOrUnknown(
          data['repere_vocal_fichier']!,
          _repereVocalFichierMeta,
        ),
      );
    }
    if (data.containsKey('repere_vocal_duree_s')) {
      context.handle(
        _repereVocalDureeSMeta,
        repereVocalDureeS.isAcceptableOrUnknown(
          data['repere_vocal_duree_s']!,
          _repereVocalDureeSMeta,
        ),
      );
    }
    if (data.containsKey('lieu_lat')) {
      context.handle(
        _lieuLatMeta,
        lieuLat.isAcceptableOrUnknown(data['lieu_lat']!, _lieuLatMeta),
      );
    }
    if (data.containsKey('lieu_lon')) {
      context.handle(
        _lieuLonMeta,
        lieuLon.isAcceptableOrUnknown(data['lieu_lon']!, _lieuLonMeta),
      );
    }
    if (data.containsKey('depot_autorise')) {
      context.handle(
        _depotAutoriseMeta,
        depotAutorise.isAcceptableOrUnknown(
          data['depot_autorise']!,
          _depotAutoriseMeta,
        ),
      );
    }
    if (data.containsKey('empreinte_code')) {
      context.handle(
        _empreinteCodeMeta,
        empreinteCode.isAcceptableOrUnknown(
          data['empreinte_code']!,
          _empreinteCodeMeta,
        ),
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
    }
    if (data.containsKey('essais_consommes')) {
      context.handle(
        _essaisConsommesMeta,
        essaisConsommes.isAcceptableOrUnknown(
          data['essais_consommes']!,
          _essaisConsommesMeta,
        ),
      );
    }
    if (data.containsKey('essais_max')) {
      context.handle(
        _essaisMaxMeta,
        essaisMax.isAcceptableOrUnknown(data['essais_max']!, _essaisMaxMeta),
      );
    }
    if (data.containsKey('code_bloque')) {
      context.handle(
        _codeBloqueMeta,
        codeBloque.isAcceptableOrUnknown(data['code_bloque']!, _codeBloqueMeta),
      );
    }
    if (data.containsKey('montant_a_encaisser_unites')) {
      context.handle(
        _montantAEncaisserUnitesMeta,
        montantAEncaisserUnites.isAcceptableOrUnknown(
          data['montant_a_encaisser_unites']!,
          _montantAEncaisserUnitesMeta,
        ),
      );
    }
    if (data.containsKey('mode_paiement')) {
      context.handle(
        _modePaiementMeta,
        modePaiement.isAcceptableOrUnknown(
          data['mode_paiement']!,
          _modePaiementMeta,
        ),
      );
    }
    if (data.containsKey('seuils_preuves_json')) {
      context.handle(
        _seuilsPreuvesJsonMeta,
        seuilsPreuvesJson.isAcceptableOrUnknown(
          data['seuils_preuves_json']!,
          _seuilsPreuvesJsonMeta,
        ),
      );
    }
    if (data.containsKey('arret_remise_id')) {
      context.handle(
        _arretRemiseIdMeta,
        arretRemiseId.isAcceptableOrUnknown(
          data['arret_remise_id']!,
          _arretRemiseIdMeta,
        ),
      );
    }
    if (data.containsKey('arret_remise_statut')) {
      context.handle(
        _arretRemiseStatutMeta,
        arretRemiseStatut.isAcceptableOrUnknown(
          data['arret_remise_statut']!,
          _arretRemiseStatutMeta,
        ),
      );
    }
    if (data.containsKey('arrive_chez_client_le')) {
      context.handle(
        _arriveChezClientLeMeta,
        arriveChezClientLe.isAcceptableOrUnknown(
          data['arrive_chez_client_le']!,
          _arriveChezClientLeMeta,
        ),
      );
    }
    if (data.containsKey('remise_validee_localement_le')) {
      context.handle(
        _remiseValideeLocalementLeMeta,
        remiseValideeLocalementLe.isAcceptableOrUnknown(
          data['remise_validee_localement_le']!,
          _remiseValideeLocalementLeMeta,
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
  Set<GeneratedColumn> get $primaryKey => {livraisonId};
  @override
  CourseCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CourseCache(
      livraisonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}livraison_id'],
      )!,
      commandeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}commande_id'],
      )!,
      etat: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}etat'],
      )!,
      devise: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}devise'],
      )!,
      clientNomUsage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_nom_usage'],
      )!,
      clientTelephone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client_telephone'],
      ),
      repereTexte: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repere_texte'],
      ),
      repereVocalFichier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}repere_vocal_fichier'],
      ),
      repereVocalDureeS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}repere_vocal_duree_s'],
      ),
      lieuLat: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lieu_lat'],
      ),
      lieuLon: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lieu_lon'],
      ),
      depotAutorise: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}depot_autorise'],
      )!,
      empreinteCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empreinte_code'],
      )!,
      empreinteJeton: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}empreinte_jeton'],
      )!,
      essaisConsommes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}essais_consommes'],
      )!,
      essaisMax: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}essais_max'],
      )!,
      codeBloque: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}code_bloque'],
      )!,
      montantAEncaisserUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}montant_a_encaisser_unites'],
      )!,
      modePaiement: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mode_paiement'],
      )!,
      seuilsPreuvesJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seuils_preuves_json'],
      )!,
      arretRemiseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arret_remise_id'],
      ),
      arretRemiseStatut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arret_remise_statut'],
      ),
      arriveChezClientLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}arrive_chez_client_le'],
      ),
      remiseValideeLocalementLe: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}remise_validee_localement_le'],
      ),
      majLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}maj_le_local'],
      )!,
    );
  }

  @override
  $CourseCacheTableTable createAlias(String alias) {
    return $CourseCacheTableTable(attachedDatabase, alias);
  }
}

class CourseCache extends DataClass implements Insertable<CourseCache> {
  /// Livraison active — PK.
  final String livraisonId;

  /// Commande portée.
  final String commandeId;

  /// Dernier état connu de la livraison.
  final String etat;

  /// Devise ISO 4217.
  final String devise;

  /// Nom d'usage du client — jamais l'état civil.
  final String clientNomUsage;

  /// Contact du client. EFFACÉ à la clôture (R6).
  final String? clientTelephone;

  /// Repère écrit.
  final String? repereTexte;

  /// Chemin du fichier audio TÉLÉCHARGÉ — pas l'URL présignée, qui expire.
  /// C'est le fichier local qui rend la note jouable en mode avion (FR-024).
  final String? repereVocalFichier;

  /// Durée de la note vocale (s).
  final int? repereVocalDureeS;

  /// Point de livraison.
  final double? lieuLat;

  /// Point de livraison.
  final double? lieuLon;

  /// La voie « dépôt » est-elle ouverte sur CETTE commande (FR-039) ?
  final bool depotAutorise;

  /// Empreinte salée du code à 4 chiffres — jamais le code (FR-037).
  final String empreinteCode;

  /// Empreinte du jeton de réception — jamais le jeton.
  final String empreinteJeton;

  /// Essais faux déjà comptés côté SERVEUR au moment du cache.
  final int essaisConsommes;

  /// Seuil de zone (paramètre du cycle 008, `commande.essais_code_livraison`).
  final int essaisMax;

  /// Saisie du code bloquée côté serveur (K4-1d).
  final bool codeBloque;

  /// Total à encaisser chez le client (unités mineures).
  final int montantAEncaisserUnites;

  /// `cash` | `mobile_money` — décide s'il y a quelque chose à encaisser.
  final String modePaiement;

  /// Seuils de preuve de la zone, sérialisés — l'écran des preuves doit savoir
  /// compter hors ligne (le serveur revérifie de toute façon, FR-060).
  final String seuilsPreuvesJson;

  /// Arrêt de REMISE — la cible de « je suis arrivé chez le client » (FR-053).
  ///
  /// Il n'est pas dans `arrets_preprovisionnes`, qui ne porte que les collectes
  /// (c'est ce qui permet de savoir que tout est collecté). Sans lui, le bouton
  /// de K3-1c n'aurait rien à transitionner, hors ligne comme en ligne.
  final String? arretRemiseId;

  /// Statut de l'arrêt de remise (`a_collecter` | `en_route` | `arrive`).
  final String? arretRemiseStatut;

  /// Instant SERVEUR d'arrivée chez le client — affiché sur K4-1a (FR-052).
  final DateTime? arriveChezClientLe;

  /// Remise validée LOCALEMENT, en attente de synchronisation (FR-041).
  ///
  /// L'heure est celle de l'appareil, et c'est assumé : elle ne fonde aucun
  /// argent — le serveur réhorodate à la réconciliation. Elle ne sert qu'à une
  /// chose, que T087 a montrée manquante : dire à Yao que c'est fini. Sans
  /// elle, l'écran de remise restait ouvert après une confirmation hors ligne
  /// réussie, proposant encore de scanner — le seul écran du parcours qui ne
  /// suivait pas ce que Yao venait de faire.
  final DateTime? remiseValideeLocalementLe;

  /// Dernière mise en cache (local).
  final DateTime majLeLocal;
  const CourseCache({
    required this.livraisonId,
    required this.commandeId,
    required this.etat,
    required this.devise,
    required this.clientNomUsage,
    this.clientTelephone,
    this.repereTexte,
    this.repereVocalFichier,
    this.repereVocalDureeS,
    this.lieuLat,
    this.lieuLon,
    required this.depotAutorise,
    required this.empreinteCode,
    required this.empreinteJeton,
    required this.essaisConsommes,
    required this.essaisMax,
    required this.codeBloque,
    required this.montantAEncaisserUnites,
    required this.modePaiement,
    required this.seuilsPreuvesJson,
    this.arretRemiseId,
    this.arretRemiseStatut,
    this.arriveChezClientLe,
    this.remiseValideeLocalementLe,
    required this.majLeLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['livraison_id'] = Variable<String>(livraisonId);
    map['commande_id'] = Variable<String>(commandeId);
    map['etat'] = Variable<String>(etat);
    map['devise'] = Variable<String>(devise);
    map['client_nom_usage'] = Variable<String>(clientNomUsage);
    if (!nullToAbsent || clientTelephone != null) {
      map['client_telephone'] = Variable<String>(clientTelephone);
    }
    if (!nullToAbsent || repereTexte != null) {
      map['repere_texte'] = Variable<String>(repereTexte);
    }
    if (!nullToAbsent || repereVocalFichier != null) {
      map['repere_vocal_fichier'] = Variable<String>(repereVocalFichier);
    }
    if (!nullToAbsent || repereVocalDureeS != null) {
      map['repere_vocal_duree_s'] = Variable<int>(repereVocalDureeS);
    }
    if (!nullToAbsent || lieuLat != null) {
      map['lieu_lat'] = Variable<double>(lieuLat);
    }
    if (!nullToAbsent || lieuLon != null) {
      map['lieu_lon'] = Variable<double>(lieuLon);
    }
    map['depot_autorise'] = Variable<bool>(depotAutorise);
    map['empreinte_code'] = Variable<String>(empreinteCode);
    map['empreinte_jeton'] = Variable<String>(empreinteJeton);
    map['essais_consommes'] = Variable<int>(essaisConsommes);
    map['essais_max'] = Variable<int>(essaisMax);
    map['code_bloque'] = Variable<bool>(codeBloque);
    map['montant_a_encaisser_unites'] = Variable<int>(montantAEncaisserUnites);
    map['mode_paiement'] = Variable<String>(modePaiement);
    map['seuils_preuves_json'] = Variable<String>(seuilsPreuvesJson);
    if (!nullToAbsent || arretRemiseId != null) {
      map['arret_remise_id'] = Variable<String>(arretRemiseId);
    }
    if (!nullToAbsent || arretRemiseStatut != null) {
      map['arret_remise_statut'] = Variable<String>(arretRemiseStatut);
    }
    if (!nullToAbsent || arriveChezClientLe != null) {
      map['arrive_chez_client_le'] = Variable<DateTime>(arriveChezClientLe);
    }
    if (!nullToAbsent || remiseValideeLocalementLe != null) {
      map['remise_validee_localement_le'] = Variable<DateTime>(
        remiseValideeLocalementLe,
      );
    }
    map['maj_le_local'] = Variable<DateTime>(majLeLocal);
    return map;
  }

  CourseCacheTableCompanion toCompanion(bool nullToAbsent) {
    return CourseCacheTableCompanion(
      livraisonId: Value(livraisonId),
      commandeId: Value(commandeId),
      etat: Value(etat),
      devise: Value(devise),
      clientNomUsage: Value(clientNomUsage),
      clientTelephone: clientTelephone == null && nullToAbsent
          ? const Value.absent()
          : Value(clientTelephone),
      repereTexte: repereTexte == null && nullToAbsent
          ? const Value.absent()
          : Value(repereTexte),
      repereVocalFichier: repereVocalFichier == null && nullToAbsent
          ? const Value.absent()
          : Value(repereVocalFichier),
      repereVocalDureeS: repereVocalDureeS == null && nullToAbsent
          ? const Value.absent()
          : Value(repereVocalDureeS),
      lieuLat: lieuLat == null && nullToAbsent
          ? const Value.absent()
          : Value(lieuLat),
      lieuLon: lieuLon == null && nullToAbsent
          ? const Value.absent()
          : Value(lieuLon),
      depotAutorise: Value(depotAutorise),
      empreinteCode: Value(empreinteCode),
      empreinteJeton: Value(empreinteJeton),
      essaisConsommes: Value(essaisConsommes),
      essaisMax: Value(essaisMax),
      codeBloque: Value(codeBloque),
      montantAEncaisserUnites: Value(montantAEncaisserUnites),
      modePaiement: Value(modePaiement),
      seuilsPreuvesJson: Value(seuilsPreuvesJson),
      arretRemiseId: arretRemiseId == null && nullToAbsent
          ? const Value.absent()
          : Value(arretRemiseId),
      arretRemiseStatut: arretRemiseStatut == null && nullToAbsent
          ? const Value.absent()
          : Value(arretRemiseStatut),
      arriveChezClientLe: arriveChezClientLe == null && nullToAbsent
          ? const Value.absent()
          : Value(arriveChezClientLe),
      remiseValideeLocalementLe:
          remiseValideeLocalementLe == null && nullToAbsent
          ? const Value.absent()
          : Value(remiseValideeLocalementLe),
      majLeLocal: Value(majLeLocal),
    );
  }

  factory CourseCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CourseCache(
      livraisonId: serializer.fromJson<String>(json['livraisonId']),
      commandeId: serializer.fromJson<String>(json['commandeId']),
      etat: serializer.fromJson<String>(json['etat']),
      devise: serializer.fromJson<String>(json['devise']),
      clientNomUsage: serializer.fromJson<String>(json['clientNomUsage']),
      clientTelephone: serializer.fromJson<String?>(json['clientTelephone']),
      repereTexte: serializer.fromJson<String?>(json['repereTexte']),
      repereVocalFichier: serializer.fromJson<String?>(
        json['repereVocalFichier'],
      ),
      repereVocalDureeS: serializer.fromJson<int?>(json['repereVocalDureeS']),
      lieuLat: serializer.fromJson<double?>(json['lieuLat']),
      lieuLon: serializer.fromJson<double?>(json['lieuLon']),
      depotAutorise: serializer.fromJson<bool>(json['depotAutorise']),
      empreinteCode: serializer.fromJson<String>(json['empreinteCode']),
      empreinteJeton: serializer.fromJson<String>(json['empreinteJeton']),
      essaisConsommes: serializer.fromJson<int>(json['essaisConsommes']),
      essaisMax: serializer.fromJson<int>(json['essaisMax']),
      codeBloque: serializer.fromJson<bool>(json['codeBloque']),
      montantAEncaisserUnites: serializer.fromJson<int>(
        json['montantAEncaisserUnites'],
      ),
      modePaiement: serializer.fromJson<String>(json['modePaiement']),
      seuilsPreuvesJson: serializer.fromJson<String>(json['seuilsPreuvesJson']),
      arretRemiseId: serializer.fromJson<String?>(json['arretRemiseId']),
      arretRemiseStatut: serializer.fromJson<String?>(
        json['arretRemiseStatut'],
      ),
      arriveChezClientLe: serializer.fromJson<DateTime?>(
        json['arriveChezClientLe'],
      ),
      remiseValideeLocalementLe: serializer.fromJson<DateTime?>(
        json['remiseValideeLocalementLe'],
      ),
      majLeLocal: serializer.fromJson<DateTime>(json['majLeLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'livraisonId': serializer.toJson<String>(livraisonId),
      'commandeId': serializer.toJson<String>(commandeId),
      'etat': serializer.toJson<String>(etat),
      'devise': serializer.toJson<String>(devise),
      'clientNomUsage': serializer.toJson<String>(clientNomUsage),
      'clientTelephone': serializer.toJson<String?>(clientTelephone),
      'repereTexte': serializer.toJson<String?>(repereTexte),
      'repereVocalFichier': serializer.toJson<String?>(repereVocalFichier),
      'repereVocalDureeS': serializer.toJson<int?>(repereVocalDureeS),
      'lieuLat': serializer.toJson<double?>(lieuLat),
      'lieuLon': serializer.toJson<double?>(lieuLon),
      'depotAutorise': serializer.toJson<bool>(depotAutorise),
      'empreinteCode': serializer.toJson<String>(empreinteCode),
      'empreinteJeton': serializer.toJson<String>(empreinteJeton),
      'essaisConsommes': serializer.toJson<int>(essaisConsommes),
      'essaisMax': serializer.toJson<int>(essaisMax),
      'codeBloque': serializer.toJson<bool>(codeBloque),
      'montantAEncaisserUnites': serializer.toJson<int>(
        montantAEncaisserUnites,
      ),
      'modePaiement': serializer.toJson<String>(modePaiement),
      'seuilsPreuvesJson': serializer.toJson<String>(seuilsPreuvesJson),
      'arretRemiseId': serializer.toJson<String?>(arretRemiseId),
      'arretRemiseStatut': serializer.toJson<String?>(arretRemiseStatut),
      'arriveChezClientLe': serializer.toJson<DateTime?>(arriveChezClientLe),
      'remiseValideeLocalementLe': serializer.toJson<DateTime?>(
        remiseValideeLocalementLe,
      ),
      'majLeLocal': serializer.toJson<DateTime>(majLeLocal),
    };
  }

  CourseCache copyWith({
    String? livraisonId,
    String? commandeId,
    String? etat,
    String? devise,
    String? clientNomUsage,
    Value<String?> clientTelephone = const Value.absent(),
    Value<String?> repereTexte = const Value.absent(),
    Value<String?> repereVocalFichier = const Value.absent(),
    Value<int?> repereVocalDureeS = const Value.absent(),
    Value<double?> lieuLat = const Value.absent(),
    Value<double?> lieuLon = const Value.absent(),
    bool? depotAutorise,
    String? empreinteCode,
    String? empreinteJeton,
    int? essaisConsommes,
    int? essaisMax,
    bool? codeBloque,
    int? montantAEncaisserUnites,
    String? modePaiement,
    String? seuilsPreuvesJson,
    Value<String?> arretRemiseId = const Value.absent(),
    Value<String?> arretRemiseStatut = const Value.absent(),
    Value<DateTime?> arriveChezClientLe = const Value.absent(),
    Value<DateTime?> remiseValideeLocalementLe = const Value.absent(),
    DateTime? majLeLocal,
  }) => CourseCache(
    livraisonId: livraisonId ?? this.livraisonId,
    commandeId: commandeId ?? this.commandeId,
    etat: etat ?? this.etat,
    devise: devise ?? this.devise,
    clientNomUsage: clientNomUsage ?? this.clientNomUsage,
    clientTelephone: clientTelephone.present
        ? clientTelephone.value
        : this.clientTelephone,
    repereTexte: repereTexte.present ? repereTexte.value : this.repereTexte,
    repereVocalFichier: repereVocalFichier.present
        ? repereVocalFichier.value
        : this.repereVocalFichier,
    repereVocalDureeS: repereVocalDureeS.present
        ? repereVocalDureeS.value
        : this.repereVocalDureeS,
    lieuLat: lieuLat.present ? lieuLat.value : this.lieuLat,
    lieuLon: lieuLon.present ? lieuLon.value : this.lieuLon,
    depotAutorise: depotAutorise ?? this.depotAutorise,
    empreinteCode: empreinteCode ?? this.empreinteCode,
    empreinteJeton: empreinteJeton ?? this.empreinteJeton,
    essaisConsommes: essaisConsommes ?? this.essaisConsommes,
    essaisMax: essaisMax ?? this.essaisMax,
    codeBloque: codeBloque ?? this.codeBloque,
    montantAEncaisserUnites:
        montantAEncaisserUnites ?? this.montantAEncaisserUnites,
    modePaiement: modePaiement ?? this.modePaiement,
    seuilsPreuvesJson: seuilsPreuvesJson ?? this.seuilsPreuvesJson,
    arretRemiseId: arretRemiseId.present
        ? arretRemiseId.value
        : this.arretRemiseId,
    arretRemiseStatut: arretRemiseStatut.present
        ? arretRemiseStatut.value
        : this.arretRemiseStatut,
    arriveChezClientLe: arriveChezClientLe.present
        ? arriveChezClientLe.value
        : this.arriveChezClientLe,
    remiseValideeLocalementLe: remiseValideeLocalementLe.present
        ? remiseValideeLocalementLe.value
        : this.remiseValideeLocalementLe,
    majLeLocal: majLeLocal ?? this.majLeLocal,
  );
  CourseCache copyWithCompanion(CourseCacheTableCompanion data) {
    return CourseCache(
      livraisonId: data.livraisonId.present
          ? data.livraisonId.value
          : this.livraisonId,
      commandeId: data.commandeId.present
          ? data.commandeId.value
          : this.commandeId,
      etat: data.etat.present ? data.etat.value : this.etat,
      devise: data.devise.present ? data.devise.value : this.devise,
      clientNomUsage: data.clientNomUsage.present
          ? data.clientNomUsage.value
          : this.clientNomUsage,
      clientTelephone: data.clientTelephone.present
          ? data.clientTelephone.value
          : this.clientTelephone,
      repereTexte: data.repereTexte.present
          ? data.repereTexte.value
          : this.repereTexte,
      repereVocalFichier: data.repereVocalFichier.present
          ? data.repereVocalFichier.value
          : this.repereVocalFichier,
      repereVocalDureeS: data.repereVocalDureeS.present
          ? data.repereVocalDureeS.value
          : this.repereVocalDureeS,
      lieuLat: data.lieuLat.present ? data.lieuLat.value : this.lieuLat,
      lieuLon: data.lieuLon.present ? data.lieuLon.value : this.lieuLon,
      depotAutorise: data.depotAutorise.present
          ? data.depotAutorise.value
          : this.depotAutorise,
      empreinteCode: data.empreinteCode.present
          ? data.empreinteCode.value
          : this.empreinteCode,
      empreinteJeton: data.empreinteJeton.present
          ? data.empreinteJeton.value
          : this.empreinteJeton,
      essaisConsommes: data.essaisConsommes.present
          ? data.essaisConsommes.value
          : this.essaisConsommes,
      essaisMax: data.essaisMax.present ? data.essaisMax.value : this.essaisMax,
      codeBloque: data.codeBloque.present
          ? data.codeBloque.value
          : this.codeBloque,
      montantAEncaisserUnites: data.montantAEncaisserUnites.present
          ? data.montantAEncaisserUnites.value
          : this.montantAEncaisserUnites,
      modePaiement: data.modePaiement.present
          ? data.modePaiement.value
          : this.modePaiement,
      seuilsPreuvesJson: data.seuilsPreuvesJson.present
          ? data.seuilsPreuvesJson.value
          : this.seuilsPreuvesJson,
      arretRemiseId: data.arretRemiseId.present
          ? data.arretRemiseId.value
          : this.arretRemiseId,
      arretRemiseStatut: data.arretRemiseStatut.present
          ? data.arretRemiseStatut.value
          : this.arretRemiseStatut,
      arriveChezClientLe: data.arriveChezClientLe.present
          ? data.arriveChezClientLe.value
          : this.arriveChezClientLe,
      remiseValideeLocalementLe: data.remiseValideeLocalementLe.present
          ? data.remiseValideeLocalementLe.value
          : this.remiseValideeLocalementLe,
      majLeLocal: data.majLeLocal.present
          ? data.majLeLocal.value
          : this.majLeLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CourseCache(')
          ..write('livraisonId: $livraisonId, ')
          ..write('commandeId: $commandeId, ')
          ..write('etat: $etat, ')
          ..write('devise: $devise, ')
          ..write('clientNomUsage: $clientNomUsage, ')
          ..write('clientTelephone: $clientTelephone, ')
          ..write('repereTexte: $repereTexte, ')
          ..write('repereVocalFichier: $repereVocalFichier, ')
          ..write('repereVocalDureeS: $repereVocalDureeS, ')
          ..write('lieuLat: $lieuLat, ')
          ..write('lieuLon: $lieuLon, ')
          ..write('depotAutorise: $depotAutorise, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('essaisConsommes: $essaisConsommes, ')
          ..write('essaisMax: $essaisMax, ')
          ..write('codeBloque: $codeBloque, ')
          ..write('montantAEncaisserUnites: $montantAEncaisserUnites, ')
          ..write('modePaiement: $modePaiement, ')
          ..write('seuilsPreuvesJson: $seuilsPreuvesJson, ')
          ..write('arretRemiseId: $arretRemiseId, ')
          ..write('arretRemiseStatut: $arretRemiseStatut, ')
          ..write('arriveChezClientLe: $arriveChezClientLe, ')
          ..write('remiseValideeLocalementLe: $remiseValideeLocalementLe, ')
          ..write('majLeLocal: $majLeLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    livraisonId,
    commandeId,
    etat,
    devise,
    clientNomUsage,
    clientTelephone,
    repereTexte,
    repereVocalFichier,
    repereVocalDureeS,
    lieuLat,
    lieuLon,
    depotAutorise,
    empreinteCode,
    empreinteJeton,
    essaisConsommes,
    essaisMax,
    codeBloque,
    montantAEncaisserUnites,
    modePaiement,
    seuilsPreuvesJson,
    arretRemiseId,
    arretRemiseStatut,
    arriveChezClientLe,
    remiseValideeLocalementLe,
    majLeLocal,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CourseCache &&
          other.livraisonId == this.livraisonId &&
          other.commandeId == this.commandeId &&
          other.etat == this.etat &&
          other.devise == this.devise &&
          other.clientNomUsage == this.clientNomUsage &&
          other.clientTelephone == this.clientTelephone &&
          other.repereTexte == this.repereTexte &&
          other.repereVocalFichier == this.repereVocalFichier &&
          other.repereVocalDureeS == this.repereVocalDureeS &&
          other.lieuLat == this.lieuLat &&
          other.lieuLon == this.lieuLon &&
          other.depotAutorise == this.depotAutorise &&
          other.empreinteCode == this.empreinteCode &&
          other.empreinteJeton == this.empreinteJeton &&
          other.essaisConsommes == this.essaisConsommes &&
          other.essaisMax == this.essaisMax &&
          other.codeBloque == this.codeBloque &&
          other.montantAEncaisserUnites == this.montantAEncaisserUnites &&
          other.modePaiement == this.modePaiement &&
          other.seuilsPreuvesJson == this.seuilsPreuvesJson &&
          other.arretRemiseId == this.arretRemiseId &&
          other.arretRemiseStatut == this.arretRemiseStatut &&
          other.arriveChezClientLe == this.arriveChezClientLe &&
          other.remiseValideeLocalementLe == this.remiseValideeLocalementLe &&
          other.majLeLocal == this.majLeLocal);
}

class CourseCacheTableCompanion extends UpdateCompanion<CourseCache> {
  final Value<String> livraisonId;
  final Value<String> commandeId;
  final Value<String> etat;
  final Value<String> devise;
  final Value<String> clientNomUsage;
  final Value<String?> clientTelephone;
  final Value<String?> repereTexte;
  final Value<String?> repereVocalFichier;
  final Value<int?> repereVocalDureeS;
  final Value<double?> lieuLat;
  final Value<double?> lieuLon;
  final Value<bool> depotAutorise;
  final Value<String> empreinteCode;
  final Value<String> empreinteJeton;
  final Value<int> essaisConsommes;
  final Value<int> essaisMax;
  final Value<bool> codeBloque;
  final Value<int> montantAEncaisserUnites;
  final Value<String> modePaiement;
  final Value<String> seuilsPreuvesJson;
  final Value<String?> arretRemiseId;
  final Value<String?> arretRemiseStatut;
  final Value<DateTime?> arriveChezClientLe;
  final Value<DateTime?> remiseValideeLocalementLe;
  final Value<DateTime> majLeLocal;
  final Value<int> rowid;
  const CourseCacheTableCompanion({
    this.livraisonId = const Value.absent(),
    this.commandeId = const Value.absent(),
    this.etat = const Value.absent(),
    this.devise = const Value.absent(),
    this.clientNomUsage = const Value.absent(),
    this.clientTelephone = const Value.absent(),
    this.repereTexte = const Value.absent(),
    this.repereVocalFichier = const Value.absent(),
    this.repereVocalDureeS = const Value.absent(),
    this.lieuLat = const Value.absent(),
    this.lieuLon = const Value.absent(),
    this.depotAutorise = const Value.absent(),
    this.empreinteCode = const Value.absent(),
    this.empreinteJeton = const Value.absent(),
    this.essaisConsommes = const Value.absent(),
    this.essaisMax = const Value.absent(),
    this.codeBloque = const Value.absent(),
    this.montantAEncaisserUnites = const Value.absent(),
    this.modePaiement = const Value.absent(),
    this.seuilsPreuvesJson = const Value.absent(),
    this.arretRemiseId = const Value.absent(),
    this.arretRemiseStatut = const Value.absent(),
    this.arriveChezClientLe = const Value.absent(),
    this.remiseValideeLocalementLe = const Value.absent(),
    this.majLeLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CourseCacheTableCompanion.insert({
    required String livraisonId,
    required String commandeId,
    required String etat,
    this.devise = const Value.absent(),
    this.clientNomUsage = const Value.absent(),
    this.clientTelephone = const Value.absent(),
    this.repereTexte = const Value.absent(),
    this.repereVocalFichier = const Value.absent(),
    this.repereVocalDureeS = const Value.absent(),
    this.lieuLat = const Value.absent(),
    this.lieuLon = const Value.absent(),
    this.depotAutorise = const Value.absent(),
    this.empreinteCode = const Value.absent(),
    this.empreinteJeton = const Value.absent(),
    this.essaisConsommes = const Value.absent(),
    this.essaisMax = const Value.absent(),
    this.codeBloque = const Value.absent(),
    this.montantAEncaisserUnites = const Value.absent(),
    this.modePaiement = const Value.absent(),
    this.seuilsPreuvesJson = const Value.absent(),
    this.arretRemiseId = const Value.absent(),
    this.arretRemiseStatut = const Value.absent(),
    this.arriveChezClientLe = const Value.absent(),
    this.remiseValideeLocalementLe = const Value.absent(),
    required DateTime majLeLocal,
    this.rowid = const Value.absent(),
  }) : livraisonId = Value(livraisonId),
       commandeId = Value(commandeId),
       etat = Value(etat),
       majLeLocal = Value(majLeLocal);
  static Insertable<CourseCache> custom({
    Expression<String>? livraisonId,
    Expression<String>? commandeId,
    Expression<String>? etat,
    Expression<String>? devise,
    Expression<String>? clientNomUsage,
    Expression<String>? clientTelephone,
    Expression<String>? repereTexte,
    Expression<String>? repereVocalFichier,
    Expression<int>? repereVocalDureeS,
    Expression<double>? lieuLat,
    Expression<double>? lieuLon,
    Expression<bool>? depotAutorise,
    Expression<String>? empreinteCode,
    Expression<String>? empreinteJeton,
    Expression<int>? essaisConsommes,
    Expression<int>? essaisMax,
    Expression<bool>? codeBloque,
    Expression<int>? montantAEncaisserUnites,
    Expression<String>? modePaiement,
    Expression<String>? seuilsPreuvesJson,
    Expression<String>? arretRemiseId,
    Expression<String>? arretRemiseStatut,
    Expression<DateTime>? arriveChezClientLe,
    Expression<DateTime>? remiseValideeLocalementLe,
    Expression<DateTime>? majLeLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (livraisonId != null) 'livraison_id': livraisonId,
      if (commandeId != null) 'commande_id': commandeId,
      if (etat != null) 'etat': etat,
      if (devise != null) 'devise': devise,
      if (clientNomUsage != null) 'client_nom_usage': clientNomUsage,
      if (clientTelephone != null) 'client_telephone': clientTelephone,
      if (repereTexte != null) 'repere_texte': repereTexte,
      if (repereVocalFichier != null)
        'repere_vocal_fichier': repereVocalFichier,
      if (repereVocalDureeS != null) 'repere_vocal_duree_s': repereVocalDureeS,
      if (lieuLat != null) 'lieu_lat': lieuLat,
      if (lieuLon != null) 'lieu_lon': lieuLon,
      if (depotAutorise != null) 'depot_autorise': depotAutorise,
      if (empreinteCode != null) 'empreinte_code': empreinteCode,
      if (empreinteJeton != null) 'empreinte_jeton': empreinteJeton,
      if (essaisConsommes != null) 'essais_consommes': essaisConsommes,
      if (essaisMax != null) 'essais_max': essaisMax,
      if (codeBloque != null) 'code_bloque': codeBloque,
      if (montantAEncaisserUnites != null)
        'montant_a_encaisser_unites': montantAEncaisserUnites,
      if (modePaiement != null) 'mode_paiement': modePaiement,
      if (seuilsPreuvesJson != null) 'seuils_preuves_json': seuilsPreuvesJson,
      if (arretRemiseId != null) 'arret_remise_id': arretRemiseId,
      if (arretRemiseStatut != null) 'arret_remise_statut': arretRemiseStatut,
      if (arriveChezClientLe != null)
        'arrive_chez_client_le': arriveChezClientLe,
      if (remiseValideeLocalementLe != null)
        'remise_validee_localement_le': remiseValideeLocalementLe,
      if (majLeLocal != null) 'maj_le_local': majLeLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CourseCacheTableCompanion copyWith({
    Value<String>? livraisonId,
    Value<String>? commandeId,
    Value<String>? etat,
    Value<String>? devise,
    Value<String>? clientNomUsage,
    Value<String?>? clientTelephone,
    Value<String?>? repereTexte,
    Value<String?>? repereVocalFichier,
    Value<int?>? repereVocalDureeS,
    Value<double?>? lieuLat,
    Value<double?>? lieuLon,
    Value<bool>? depotAutorise,
    Value<String>? empreinteCode,
    Value<String>? empreinteJeton,
    Value<int>? essaisConsommes,
    Value<int>? essaisMax,
    Value<bool>? codeBloque,
    Value<int>? montantAEncaisserUnites,
    Value<String>? modePaiement,
    Value<String>? seuilsPreuvesJson,
    Value<String?>? arretRemiseId,
    Value<String?>? arretRemiseStatut,
    Value<DateTime?>? arriveChezClientLe,
    Value<DateTime?>? remiseValideeLocalementLe,
    Value<DateTime>? majLeLocal,
    Value<int>? rowid,
  }) {
    return CourseCacheTableCompanion(
      livraisonId: livraisonId ?? this.livraisonId,
      commandeId: commandeId ?? this.commandeId,
      etat: etat ?? this.etat,
      devise: devise ?? this.devise,
      clientNomUsage: clientNomUsage ?? this.clientNomUsage,
      clientTelephone: clientTelephone ?? this.clientTelephone,
      repereTexte: repereTexte ?? this.repereTexte,
      repereVocalFichier: repereVocalFichier ?? this.repereVocalFichier,
      repereVocalDureeS: repereVocalDureeS ?? this.repereVocalDureeS,
      lieuLat: lieuLat ?? this.lieuLat,
      lieuLon: lieuLon ?? this.lieuLon,
      depotAutorise: depotAutorise ?? this.depotAutorise,
      empreinteCode: empreinteCode ?? this.empreinteCode,
      empreinteJeton: empreinteJeton ?? this.empreinteJeton,
      essaisConsommes: essaisConsommes ?? this.essaisConsommes,
      essaisMax: essaisMax ?? this.essaisMax,
      codeBloque: codeBloque ?? this.codeBloque,
      montantAEncaisserUnites:
          montantAEncaisserUnites ?? this.montantAEncaisserUnites,
      modePaiement: modePaiement ?? this.modePaiement,
      seuilsPreuvesJson: seuilsPreuvesJson ?? this.seuilsPreuvesJson,
      arretRemiseId: arretRemiseId ?? this.arretRemiseId,
      arretRemiseStatut: arretRemiseStatut ?? this.arretRemiseStatut,
      arriveChezClientLe: arriveChezClientLe ?? this.arriveChezClientLe,
      remiseValideeLocalementLe:
          remiseValideeLocalementLe ?? this.remiseValideeLocalementLe,
      majLeLocal: majLeLocal ?? this.majLeLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (livraisonId.present) {
      map['livraison_id'] = Variable<String>(livraisonId.value);
    }
    if (commandeId.present) {
      map['commande_id'] = Variable<String>(commandeId.value);
    }
    if (etat.present) {
      map['etat'] = Variable<String>(etat.value);
    }
    if (devise.present) {
      map['devise'] = Variable<String>(devise.value);
    }
    if (clientNomUsage.present) {
      map['client_nom_usage'] = Variable<String>(clientNomUsage.value);
    }
    if (clientTelephone.present) {
      map['client_telephone'] = Variable<String>(clientTelephone.value);
    }
    if (repereTexte.present) {
      map['repere_texte'] = Variable<String>(repereTexte.value);
    }
    if (repereVocalFichier.present) {
      map['repere_vocal_fichier'] = Variable<String>(repereVocalFichier.value);
    }
    if (repereVocalDureeS.present) {
      map['repere_vocal_duree_s'] = Variable<int>(repereVocalDureeS.value);
    }
    if (lieuLat.present) {
      map['lieu_lat'] = Variable<double>(lieuLat.value);
    }
    if (lieuLon.present) {
      map['lieu_lon'] = Variable<double>(lieuLon.value);
    }
    if (depotAutorise.present) {
      map['depot_autorise'] = Variable<bool>(depotAutorise.value);
    }
    if (empreinteCode.present) {
      map['empreinte_code'] = Variable<String>(empreinteCode.value);
    }
    if (empreinteJeton.present) {
      map['empreinte_jeton'] = Variable<String>(empreinteJeton.value);
    }
    if (essaisConsommes.present) {
      map['essais_consommes'] = Variable<int>(essaisConsommes.value);
    }
    if (essaisMax.present) {
      map['essais_max'] = Variable<int>(essaisMax.value);
    }
    if (codeBloque.present) {
      map['code_bloque'] = Variable<bool>(codeBloque.value);
    }
    if (montantAEncaisserUnites.present) {
      map['montant_a_encaisser_unites'] = Variable<int>(
        montantAEncaisserUnites.value,
      );
    }
    if (modePaiement.present) {
      map['mode_paiement'] = Variable<String>(modePaiement.value);
    }
    if (seuilsPreuvesJson.present) {
      map['seuils_preuves_json'] = Variable<String>(seuilsPreuvesJson.value);
    }
    if (arretRemiseId.present) {
      map['arret_remise_id'] = Variable<String>(arretRemiseId.value);
    }
    if (arretRemiseStatut.present) {
      map['arret_remise_statut'] = Variable<String>(arretRemiseStatut.value);
    }
    if (arriveChezClientLe.present) {
      map['arrive_chez_client_le'] = Variable<DateTime>(
        arriveChezClientLe.value,
      );
    }
    if (remiseValideeLocalementLe.present) {
      map['remise_validee_localement_le'] = Variable<DateTime>(
        remiseValideeLocalementLe.value,
      );
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
    return (StringBuffer('CourseCacheTableCompanion(')
          ..write('livraisonId: $livraisonId, ')
          ..write('commandeId: $commandeId, ')
          ..write('etat: $etat, ')
          ..write('devise: $devise, ')
          ..write('clientNomUsage: $clientNomUsage, ')
          ..write('clientTelephone: $clientTelephone, ')
          ..write('repereTexte: $repereTexte, ')
          ..write('repereVocalFichier: $repereVocalFichier, ')
          ..write('repereVocalDureeS: $repereVocalDureeS, ')
          ..write('lieuLat: $lieuLat, ')
          ..write('lieuLon: $lieuLon, ')
          ..write('depotAutorise: $depotAutorise, ')
          ..write('empreinteCode: $empreinteCode, ')
          ..write('empreinteJeton: $empreinteJeton, ')
          ..write('essaisConsommes: $essaisConsommes, ')
          ..write('essaisMax: $essaisMax, ')
          ..write('codeBloque: $codeBloque, ')
          ..write('montantAEncaisserUnites: $montantAEncaisserUnites, ')
          ..write('modePaiement: $modePaiement, ')
          ..write('seuilsPreuvesJson: $seuilsPreuvesJson, ')
          ..write('arretRemiseId: $arretRemiseId, ')
          ..write('arretRemiseStatut: $arretRemiseStatut, ')
          ..write('arriveChezClientLe: $arriveChezClientLe, ')
          ..write('remiseValideeLocalementLe: $remiseValideeLocalementLe, ')
          ..write('majLeLocal: $majLeLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LignesChecklistTable extends LignesChecklist
    with TableInfo<$LignesChecklistTable, LigneChecklist> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LignesChecklistTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ligneIdMeta = const VerificationMeta(
    'ligneId',
  );
  @override
  late final GeneratedColumn<String> ligneId = GeneratedColumn<String>(
    'ligne_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
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
  static const VerificationMeta _libelleMeta = const VerificationMeta(
    'libelle',
  );
  @override
  late final GeneratedColumn<String> libelle = GeneratedColumn<String>(
    'libelle',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantiteMeta = const VerificationMeta(
    'quantite',
  );
  @override
  late final GeneratedColumn<int> quantite = GeneratedColumn<int>(
    'quantite',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _prixUnitaireUnitesMeta =
      const VerificationMeta('prixUnitaireUnites');
  @override
  late final GeneratedColumn<int> prixUnitaireUnites = GeneratedColumn<int>(
    'prix_unitaire_unites',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _preferenceMeta = const VerificationMeta(
    'preference',
  );
  @override
  late final GeneratedColumn<String> preference = GeneratedColumn<String>(
    'preference',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('appeler'),
  );
  static const VerificationMeta _statutMeta = const VerificationMeta('statut');
  @override
  late final GeneratedColumn<String> statut = GeneratedColumn<String>(
    'statut',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('presente'),
  );
  static const VerificationMeta _cocheeMeta = const VerificationMeta('cochee');
  @override
  late final GeneratedColumn<bool> cochee = GeneratedColumn<bool>(
    'cochee',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("cochee" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _ordreMeta = const VerificationMeta('ordre');
  @override
  late final GeneratedColumn<int> ordre = GeneratedColumn<int>(
    'ordre',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    ligneId,
    arretId,
    libelle,
    quantite,
    prixUnitaireUnites,
    preference,
    statut,
    cochee,
    ordre,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lignes_checklist';
  @override
  VerificationContext validateIntegrity(
    Insertable<LigneChecklist> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('ligne_id')) {
      context.handle(
        _ligneIdMeta,
        ligneId.isAcceptableOrUnknown(data['ligne_id']!, _ligneIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ligneIdMeta);
    }
    if (data.containsKey('arret_id')) {
      context.handle(
        _arretIdMeta,
        arretId.isAcceptableOrUnknown(data['arret_id']!, _arretIdMeta),
      );
    } else if (isInserting) {
      context.missing(_arretIdMeta);
    }
    if (data.containsKey('libelle')) {
      context.handle(
        _libelleMeta,
        libelle.isAcceptableOrUnknown(data['libelle']!, _libelleMeta),
      );
    } else if (isInserting) {
      context.missing(_libelleMeta);
    }
    if (data.containsKey('quantite')) {
      context.handle(
        _quantiteMeta,
        quantite.isAcceptableOrUnknown(data['quantite']!, _quantiteMeta),
      );
    }
    if (data.containsKey('prix_unitaire_unites')) {
      context.handle(
        _prixUnitaireUnitesMeta,
        prixUnitaireUnites.isAcceptableOrUnknown(
          data['prix_unitaire_unites']!,
          _prixUnitaireUnitesMeta,
        ),
      );
    }
    if (data.containsKey('preference')) {
      context.handle(
        _preferenceMeta,
        preference.isAcceptableOrUnknown(data['preference']!, _preferenceMeta),
      );
    }
    if (data.containsKey('statut')) {
      context.handle(
        _statutMeta,
        statut.isAcceptableOrUnknown(data['statut']!, _statutMeta),
      );
    }
    if (data.containsKey('cochee')) {
      context.handle(
        _cocheeMeta,
        cochee.isAcceptableOrUnknown(data['cochee']!, _cocheeMeta),
      );
    }
    if (data.containsKey('ordre')) {
      context.handle(
        _ordreMeta,
        ordre.isAcceptableOrUnknown(data['ordre']!, _ordreMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ligneId};
  @override
  LigneChecklist map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LigneChecklist(
      ligneId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ligne_id'],
      )!,
      arretId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}arret_id'],
      )!,
      libelle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}libelle'],
      )!,
      quantite: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quantite'],
      )!,
      prixUnitaireUnites: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}prix_unitaire_unites'],
      )!,
      preference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preference'],
      )!,
      statut: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statut'],
      )!,
      cochee: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}cochee'],
      )!,
      ordre: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordre'],
      )!,
    );
  }

  @override
  $LignesChecklistTable createAlias(String alias) {
    return $LignesChecklistTable(attachedDatabase, alias);
  }
}

class LigneChecklist extends DataClass implements Insertable<LigneChecklist> {
  /// Ligne de commande — PK.
  final String ligneId;

  /// Arrêt auquel elle appartient.
  final String arretId;

  /// Libellé figé à la création de la commande.
  final String libelle;

  /// Quantité commandée.
  final int quantite;

  /// Prix unitaire VERROUILLÉ (unités mineures).
  final int prixUnitaireUnites;

  /// Ce que le client a choisi si l'article manque
  /// (`remplacer` | `appeler` | `retirer`).
  final String preference;

  /// Statut SERVEUR (`presente` | `remplacee` | `retiree`).
  final String statut;

  /// Coche LOCALE — jamais synchronisée.
  final bool cochee;

  /// Rang d'affichage dans l'arrêt.
  final int ordre;
  const LigneChecklist({
    required this.ligneId,
    required this.arretId,
    required this.libelle,
    required this.quantite,
    required this.prixUnitaireUnites,
    required this.preference,
    required this.statut,
    required this.cochee,
    required this.ordre,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['ligne_id'] = Variable<String>(ligneId);
    map['arret_id'] = Variable<String>(arretId);
    map['libelle'] = Variable<String>(libelle);
    map['quantite'] = Variable<int>(quantite);
    map['prix_unitaire_unites'] = Variable<int>(prixUnitaireUnites);
    map['preference'] = Variable<String>(preference);
    map['statut'] = Variable<String>(statut);
    map['cochee'] = Variable<bool>(cochee);
    map['ordre'] = Variable<int>(ordre);
    return map;
  }

  LignesChecklistCompanion toCompanion(bool nullToAbsent) {
    return LignesChecklistCompanion(
      ligneId: Value(ligneId),
      arretId: Value(arretId),
      libelle: Value(libelle),
      quantite: Value(quantite),
      prixUnitaireUnites: Value(prixUnitaireUnites),
      preference: Value(preference),
      statut: Value(statut),
      cochee: Value(cochee),
      ordre: Value(ordre),
    );
  }

  factory LigneChecklist.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LigneChecklist(
      ligneId: serializer.fromJson<String>(json['ligneId']),
      arretId: serializer.fromJson<String>(json['arretId']),
      libelle: serializer.fromJson<String>(json['libelle']),
      quantite: serializer.fromJson<int>(json['quantite']),
      prixUnitaireUnites: serializer.fromJson<int>(json['prixUnitaireUnites']),
      preference: serializer.fromJson<String>(json['preference']),
      statut: serializer.fromJson<String>(json['statut']),
      cochee: serializer.fromJson<bool>(json['cochee']),
      ordre: serializer.fromJson<int>(json['ordre']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ligneId': serializer.toJson<String>(ligneId),
      'arretId': serializer.toJson<String>(arretId),
      'libelle': serializer.toJson<String>(libelle),
      'quantite': serializer.toJson<int>(quantite),
      'prixUnitaireUnites': serializer.toJson<int>(prixUnitaireUnites),
      'preference': serializer.toJson<String>(preference),
      'statut': serializer.toJson<String>(statut),
      'cochee': serializer.toJson<bool>(cochee),
      'ordre': serializer.toJson<int>(ordre),
    };
  }

  LigneChecklist copyWith({
    String? ligneId,
    String? arretId,
    String? libelle,
    int? quantite,
    int? prixUnitaireUnites,
    String? preference,
    String? statut,
    bool? cochee,
    int? ordre,
  }) => LigneChecklist(
    ligneId: ligneId ?? this.ligneId,
    arretId: arretId ?? this.arretId,
    libelle: libelle ?? this.libelle,
    quantite: quantite ?? this.quantite,
    prixUnitaireUnites: prixUnitaireUnites ?? this.prixUnitaireUnites,
    preference: preference ?? this.preference,
    statut: statut ?? this.statut,
    cochee: cochee ?? this.cochee,
    ordre: ordre ?? this.ordre,
  );
  LigneChecklist copyWithCompanion(LignesChecklistCompanion data) {
    return LigneChecklist(
      ligneId: data.ligneId.present ? data.ligneId.value : this.ligneId,
      arretId: data.arretId.present ? data.arretId.value : this.arretId,
      libelle: data.libelle.present ? data.libelle.value : this.libelle,
      quantite: data.quantite.present ? data.quantite.value : this.quantite,
      prixUnitaireUnites: data.prixUnitaireUnites.present
          ? data.prixUnitaireUnites.value
          : this.prixUnitaireUnites,
      preference: data.preference.present
          ? data.preference.value
          : this.preference,
      statut: data.statut.present ? data.statut.value : this.statut,
      cochee: data.cochee.present ? data.cochee.value : this.cochee,
      ordre: data.ordre.present ? data.ordre.value : this.ordre,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LigneChecklist(')
          ..write('ligneId: $ligneId, ')
          ..write('arretId: $arretId, ')
          ..write('libelle: $libelle, ')
          ..write('quantite: $quantite, ')
          ..write('prixUnitaireUnites: $prixUnitaireUnites, ')
          ..write('preference: $preference, ')
          ..write('statut: $statut, ')
          ..write('cochee: $cochee, ')
          ..write('ordre: $ordre')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    ligneId,
    arretId,
    libelle,
    quantite,
    prixUnitaireUnites,
    preference,
    statut,
    cochee,
    ordre,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LigneChecklist &&
          other.ligneId == this.ligneId &&
          other.arretId == this.arretId &&
          other.libelle == this.libelle &&
          other.quantite == this.quantite &&
          other.prixUnitaireUnites == this.prixUnitaireUnites &&
          other.preference == this.preference &&
          other.statut == this.statut &&
          other.cochee == this.cochee &&
          other.ordre == this.ordre);
}

class LignesChecklistCompanion extends UpdateCompanion<LigneChecklist> {
  final Value<String> ligneId;
  final Value<String> arretId;
  final Value<String> libelle;
  final Value<int> quantite;
  final Value<int> prixUnitaireUnites;
  final Value<String> preference;
  final Value<String> statut;
  final Value<bool> cochee;
  final Value<int> ordre;
  final Value<int> rowid;
  const LignesChecklistCompanion({
    this.ligneId = const Value.absent(),
    this.arretId = const Value.absent(),
    this.libelle = const Value.absent(),
    this.quantite = const Value.absent(),
    this.prixUnitaireUnites = const Value.absent(),
    this.preference = const Value.absent(),
    this.statut = const Value.absent(),
    this.cochee = const Value.absent(),
    this.ordre = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LignesChecklistCompanion.insert({
    required String ligneId,
    required String arretId,
    required String libelle,
    this.quantite = const Value.absent(),
    this.prixUnitaireUnites = const Value.absent(),
    this.preference = const Value.absent(),
    this.statut = const Value.absent(),
    this.cochee = const Value.absent(),
    this.ordre = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : ligneId = Value(ligneId),
       arretId = Value(arretId),
       libelle = Value(libelle);
  static Insertable<LigneChecklist> custom({
    Expression<String>? ligneId,
    Expression<String>? arretId,
    Expression<String>? libelle,
    Expression<int>? quantite,
    Expression<int>? prixUnitaireUnites,
    Expression<String>? preference,
    Expression<String>? statut,
    Expression<bool>? cochee,
    Expression<int>? ordre,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ligneId != null) 'ligne_id': ligneId,
      if (arretId != null) 'arret_id': arretId,
      if (libelle != null) 'libelle': libelle,
      if (quantite != null) 'quantite': quantite,
      if (prixUnitaireUnites != null)
        'prix_unitaire_unites': prixUnitaireUnites,
      if (preference != null) 'preference': preference,
      if (statut != null) 'statut': statut,
      if (cochee != null) 'cochee': cochee,
      if (ordre != null) 'ordre': ordre,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LignesChecklistCompanion copyWith({
    Value<String>? ligneId,
    Value<String>? arretId,
    Value<String>? libelle,
    Value<int>? quantite,
    Value<int>? prixUnitaireUnites,
    Value<String>? preference,
    Value<String>? statut,
    Value<bool>? cochee,
    Value<int>? ordre,
    Value<int>? rowid,
  }) {
    return LignesChecklistCompanion(
      ligneId: ligneId ?? this.ligneId,
      arretId: arretId ?? this.arretId,
      libelle: libelle ?? this.libelle,
      quantite: quantite ?? this.quantite,
      prixUnitaireUnites: prixUnitaireUnites ?? this.prixUnitaireUnites,
      preference: preference ?? this.preference,
      statut: statut ?? this.statut,
      cochee: cochee ?? this.cochee,
      ordre: ordre ?? this.ordre,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ligneId.present) {
      map['ligne_id'] = Variable<String>(ligneId.value);
    }
    if (arretId.present) {
      map['arret_id'] = Variable<String>(arretId.value);
    }
    if (libelle.present) {
      map['libelle'] = Variable<String>(libelle.value);
    }
    if (quantite.present) {
      map['quantite'] = Variable<int>(quantite.value);
    }
    if (prixUnitaireUnites.present) {
      map['prix_unitaire_unites'] = Variable<int>(prixUnitaireUnites.value);
    }
    if (preference.present) {
      map['preference'] = Variable<String>(preference.value);
    }
    if (statut.present) {
      map['statut'] = Variable<String>(statut.value);
    }
    if (cochee.present) {
      map['cochee'] = Variable<bool>(cochee.value);
    }
    if (ordre.present) {
      map['ordre'] = Variable<int>(ordre.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LignesChecklistCompanion(')
          ..write('ligneId: $ligneId, ')
          ..write('arretId: $arretId, ')
          ..write('libelle: $libelle, ')
          ..write('quantite: $quantite, ')
          ..write('prixUnitaireUnites: $prixUnitaireUnites, ')
          ..write('preference: $preference, ')
          ..write('statut: $statut, ')
          ..write('cochee: $cochee, ')
          ..write('ordre: $ordre, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EssaisRemiseTable extends EssaisRemise
    with TableInfo<$EssaisRemiseTable, EssaiRemise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EssaisRemiseTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _livraisonIdMeta = const VerificationMeta(
    'livraisonId',
  );
  @override
  late final GeneratedColumn<String> livraisonId = GeneratedColumn<String>(
    'livraison_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _essaisHorsLigneMeta = const VerificationMeta(
    'essaisHorsLigne',
  );
  @override
  late final GeneratedColumn<int> essaisHorsLigne = GeneratedColumn<int>(
    'essais_hors_ligne',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _dernierEssaiLocalMeta = const VerificationMeta(
    'dernierEssaiLocal',
  );
  @override
  late final GeneratedColumn<DateTime> dernierEssaiLocal =
      GeneratedColumn<DateTime>(
        'dernier_essai_local',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    livraisonId,
    essaisHorsLigne,
    dernierEssaiLocal,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'essais_remise';
  @override
  VerificationContext validateIntegrity(
    Insertable<EssaiRemise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('livraison_id')) {
      context.handle(
        _livraisonIdMeta,
        livraisonId.isAcceptableOrUnknown(
          data['livraison_id']!,
          _livraisonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_livraisonIdMeta);
    }
    if (data.containsKey('essais_hors_ligne')) {
      context.handle(
        _essaisHorsLigneMeta,
        essaisHorsLigne.isAcceptableOrUnknown(
          data['essais_hors_ligne']!,
          _essaisHorsLigneMeta,
        ),
      );
    }
    if (data.containsKey('dernier_essai_local')) {
      context.handle(
        _dernierEssaiLocalMeta,
        dernierEssaiLocal.isAcceptableOrUnknown(
          data['dernier_essai_local']!,
          _dernierEssaiLocalMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {livraisonId};
  @override
  EssaiRemise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EssaiRemise(
      livraisonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}livraison_id'],
      )!,
      essaisHorsLigne: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}essais_hors_ligne'],
      )!,
      dernierEssaiLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}dernier_essai_local'],
      ),
    );
  }

  @override
  $EssaisRemiseTable createAlias(String alias) {
    return $EssaisRemiseTable(attachedDatabase, alias);
  }
}

class EssaiRemise extends DataClass implements Insertable<EssaiRemise> {
  /// Livraison — PK.
  final String livraisonId;

  /// Essais faux comptés localement depuis la dernière consolidation.
  final int essaisHorsLigne;

  /// Dernier essai (local).
  final DateTime? dernierEssaiLocal;
  const EssaiRemise({
    required this.livraisonId,
    required this.essaisHorsLigne,
    this.dernierEssaiLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['livraison_id'] = Variable<String>(livraisonId);
    map['essais_hors_ligne'] = Variable<int>(essaisHorsLigne);
    if (!nullToAbsent || dernierEssaiLocal != null) {
      map['dernier_essai_local'] = Variable<DateTime>(dernierEssaiLocal);
    }
    return map;
  }

  EssaisRemiseCompanion toCompanion(bool nullToAbsent) {
    return EssaisRemiseCompanion(
      livraisonId: Value(livraisonId),
      essaisHorsLigne: Value(essaisHorsLigne),
      dernierEssaiLocal: dernierEssaiLocal == null && nullToAbsent
          ? const Value.absent()
          : Value(dernierEssaiLocal),
    );
  }

  factory EssaiRemise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EssaiRemise(
      livraisonId: serializer.fromJson<String>(json['livraisonId']),
      essaisHorsLigne: serializer.fromJson<int>(json['essaisHorsLigne']),
      dernierEssaiLocal: serializer.fromJson<DateTime?>(
        json['dernierEssaiLocal'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'livraisonId': serializer.toJson<String>(livraisonId),
      'essaisHorsLigne': serializer.toJson<int>(essaisHorsLigne),
      'dernierEssaiLocal': serializer.toJson<DateTime?>(dernierEssaiLocal),
    };
  }

  EssaiRemise copyWith({
    String? livraisonId,
    int? essaisHorsLigne,
    Value<DateTime?> dernierEssaiLocal = const Value.absent(),
  }) => EssaiRemise(
    livraisonId: livraisonId ?? this.livraisonId,
    essaisHorsLigne: essaisHorsLigne ?? this.essaisHorsLigne,
    dernierEssaiLocal: dernierEssaiLocal.present
        ? dernierEssaiLocal.value
        : this.dernierEssaiLocal,
  );
  EssaiRemise copyWithCompanion(EssaisRemiseCompanion data) {
    return EssaiRemise(
      livraisonId: data.livraisonId.present
          ? data.livraisonId.value
          : this.livraisonId,
      essaisHorsLigne: data.essaisHorsLigne.present
          ? data.essaisHorsLigne.value
          : this.essaisHorsLigne,
      dernierEssaiLocal: data.dernierEssaiLocal.present
          ? data.dernierEssaiLocal.value
          : this.dernierEssaiLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EssaiRemise(')
          ..write('livraisonId: $livraisonId, ')
          ..write('essaisHorsLigne: $essaisHorsLigne, ')
          ..write('dernierEssaiLocal: $dernierEssaiLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(livraisonId, essaisHorsLigne, dernierEssaiLocal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EssaiRemise &&
          other.livraisonId == this.livraisonId &&
          other.essaisHorsLigne == this.essaisHorsLigne &&
          other.dernierEssaiLocal == this.dernierEssaiLocal);
}

class EssaisRemiseCompanion extends UpdateCompanion<EssaiRemise> {
  final Value<String> livraisonId;
  final Value<int> essaisHorsLigne;
  final Value<DateTime?> dernierEssaiLocal;
  final Value<int> rowid;
  const EssaisRemiseCompanion({
    this.livraisonId = const Value.absent(),
    this.essaisHorsLigne = const Value.absent(),
    this.dernierEssaiLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EssaisRemiseCompanion.insert({
    required String livraisonId,
    this.essaisHorsLigne = const Value.absent(),
    this.dernierEssaiLocal = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : livraisonId = Value(livraisonId);
  static Insertable<EssaiRemise> custom({
    Expression<String>? livraisonId,
    Expression<int>? essaisHorsLigne,
    Expression<DateTime>? dernierEssaiLocal,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (livraisonId != null) 'livraison_id': livraisonId,
      if (essaisHorsLigne != null) 'essais_hors_ligne': essaisHorsLigne,
      if (dernierEssaiLocal != null) 'dernier_essai_local': dernierEssaiLocal,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EssaisRemiseCompanion copyWith({
    Value<String>? livraisonId,
    Value<int>? essaisHorsLigne,
    Value<DateTime?>? dernierEssaiLocal,
    Value<int>? rowid,
  }) {
    return EssaisRemiseCompanion(
      livraisonId: livraisonId ?? this.livraisonId,
      essaisHorsLigne: essaisHorsLigne ?? this.essaisHorsLigne,
      dernierEssaiLocal: dernierEssaiLocal ?? this.dernierEssaiLocal,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (livraisonId.present) {
      map['livraison_id'] = Variable<String>(livraisonId.value);
    }
    if (essaisHorsLigne.present) {
      map['essais_hors_ligne'] = Variable<int>(essaisHorsLigne.value);
    }
    if (dernierEssaiLocal.present) {
      map['dernier_essai_local'] = Variable<DateTime>(dernierEssaiLocal.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EssaisRemiseCompanion(')
          ..write('livraisonId: $livraisonId, ')
          ..write('essaisHorsLigne: $essaisHorsLigne, ')
          ..write('dernierEssaiLocal: $dernierEssaiLocal, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $RelevesPresenceLocauxTable extends RelevesPresenceLocaux
    with TableInfo<$RelevesPresenceLocauxTable, RelevePresenceLocal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RelevesPresenceLocauxTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _livraisonIdMeta = const VerificationMeta(
    'livraisonId',
  );
  @override
  late final GeneratedColumn<String> livraisonId = GeneratedColumn<String>(
    'livraison_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _distanceMMeta = const VerificationMeta(
    'distanceM',
  );
  @override
  late final GeneratedColumn<int> distanceM = GeneratedColumn<int>(
    'distance_m',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _releveLeLocalMeta = const VerificationMeta(
    'releveLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> releveLeLocal =
      GeneratedColumn<DateTime>(
        'releve_le_local',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _envoyeMeta = const VerificationMeta('envoye');
  @override
  late final GeneratedColumn<bool> envoye = GeneratedColumn<bool>(
    'envoye',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("envoye" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    uuidClient,
    livraisonId,
    distanceM,
    releveLeLocal,
    envoye,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'releves_presence_locaux';
  @override
  VerificationContext validateIntegrity(
    Insertable<RelevePresenceLocal> instance, {
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
    if (data.containsKey('livraison_id')) {
      context.handle(
        _livraisonIdMeta,
        livraisonId.isAcceptableOrUnknown(
          data['livraison_id']!,
          _livraisonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_livraisonIdMeta);
    }
    if (data.containsKey('distance_m')) {
      context.handle(
        _distanceMMeta,
        distanceM.isAcceptableOrUnknown(data['distance_m']!, _distanceMMeta),
      );
    } else if (isInserting) {
      context.missing(_distanceMMeta);
    }
    if (data.containsKey('releve_le_local')) {
      context.handle(
        _releveLeLocalMeta,
        releveLeLocal.isAcceptableOrUnknown(
          data['releve_le_local']!,
          _releveLeLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_releveLeLocalMeta);
    }
    if (data.containsKey('envoye')) {
      context.handle(
        _envoyeMeta,
        envoye.isAcceptableOrUnknown(data['envoye']!, _envoyeMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuidClient};
  @override
  RelevePresenceLocal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RelevePresenceLocal(
      uuidClient: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid_client'],
      )!,
      livraisonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}livraison_id'],
      )!,
      distanceM: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}distance_m'],
      )!,
      releveLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}releve_le_local'],
      )!,
      envoye: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}envoye'],
      )!,
    );
  }

  @override
  $RelevesPresenceLocauxTable createAlias(String alias) {
    return $RelevesPresenceLocauxTable(attachedDatabase, alias);
  }
}

class RelevePresenceLocal extends DataClass
    implements Insertable<RelevePresenceLocal> {
  /// Clé d'idempotence de l'échantillon (UUIDv7) — PK.
  final String uuidClient;

  /// Livraison concernée.
  final String livraisonId;

  /// Distance ARRONDIE au point de livraison (m).
  final int distanceM;

  /// Horodatage local de l'échantillon.
  final DateTime releveLeLocal;

  /// Envoyé et accepté par le serveur — la ligne peut être purgée.
  final bool envoye;
  const RelevePresenceLocal({
    required this.uuidClient,
    required this.livraisonId,
    required this.distanceM,
    required this.releveLeLocal,
    required this.envoye,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uuid_client'] = Variable<String>(uuidClient);
    map['livraison_id'] = Variable<String>(livraisonId);
    map['distance_m'] = Variable<int>(distanceM);
    map['releve_le_local'] = Variable<DateTime>(releveLeLocal);
    map['envoye'] = Variable<bool>(envoye);
    return map;
  }

  RelevesPresenceLocauxCompanion toCompanion(bool nullToAbsent) {
    return RelevesPresenceLocauxCompanion(
      uuidClient: Value(uuidClient),
      livraisonId: Value(livraisonId),
      distanceM: Value(distanceM),
      releveLeLocal: Value(releveLeLocal),
      envoye: Value(envoye),
    );
  }

  factory RelevePresenceLocal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RelevePresenceLocal(
      uuidClient: serializer.fromJson<String>(json['uuidClient']),
      livraisonId: serializer.fromJson<String>(json['livraisonId']),
      distanceM: serializer.fromJson<int>(json['distanceM']),
      releveLeLocal: serializer.fromJson<DateTime>(json['releveLeLocal']),
      envoye: serializer.fromJson<bool>(json['envoye']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuidClient': serializer.toJson<String>(uuidClient),
      'livraisonId': serializer.toJson<String>(livraisonId),
      'distanceM': serializer.toJson<int>(distanceM),
      'releveLeLocal': serializer.toJson<DateTime>(releveLeLocal),
      'envoye': serializer.toJson<bool>(envoye),
    };
  }

  RelevePresenceLocal copyWith({
    String? uuidClient,
    String? livraisonId,
    int? distanceM,
    DateTime? releveLeLocal,
    bool? envoye,
  }) => RelevePresenceLocal(
    uuidClient: uuidClient ?? this.uuidClient,
    livraisonId: livraisonId ?? this.livraisonId,
    distanceM: distanceM ?? this.distanceM,
    releveLeLocal: releveLeLocal ?? this.releveLeLocal,
    envoye: envoye ?? this.envoye,
  );
  RelevePresenceLocal copyWithCompanion(RelevesPresenceLocauxCompanion data) {
    return RelevePresenceLocal(
      uuidClient: data.uuidClient.present
          ? data.uuidClient.value
          : this.uuidClient,
      livraisonId: data.livraisonId.present
          ? data.livraisonId.value
          : this.livraisonId,
      distanceM: data.distanceM.present ? data.distanceM.value : this.distanceM,
      releveLeLocal: data.releveLeLocal.present
          ? data.releveLeLocal.value
          : this.releveLeLocal,
      envoye: data.envoye.present ? data.envoye.value : this.envoye,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RelevePresenceLocal(')
          ..write('uuidClient: $uuidClient, ')
          ..write('livraisonId: $livraisonId, ')
          ..write('distanceM: $distanceM, ')
          ..write('releveLeLocal: $releveLeLocal, ')
          ..write('envoye: $envoye')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uuidClient, livraisonId, distanceM, releveLeLocal, envoye);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RelevePresenceLocal &&
          other.uuidClient == this.uuidClient &&
          other.livraisonId == this.livraisonId &&
          other.distanceM == this.distanceM &&
          other.releveLeLocal == this.releveLeLocal &&
          other.envoye == this.envoye);
}

class RelevesPresenceLocauxCompanion
    extends UpdateCompanion<RelevePresenceLocal> {
  final Value<String> uuidClient;
  final Value<String> livraisonId;
  final Value<int> distanceM;
  final Value<DateTime> releveLeLocal;
  final Value<bool> envoye;
  final Value<int> rowid;
  const RelevesPresenceLocauxCompanion({
    this.uuidClient = const Value.absent(),
    this.livraisonId = const Value.absent(),
    this.distanceM = const Value.absent(),
    this.releveLeLocal = const Value.absent(),
    this.envoye = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RelevesPresenceLocauxCompanion.insert({
    required String uuidClient,
    required String livraisonId,
    required int distanceM,
    required DateTime releveLeLocal,
    this.envoye = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuidClient = Value(uuidClient),
       livraisonId = Value(livraisonId),
       distanceM = Value(distanceM),
       releveLeLocal = Value(releveLeLocal);
  static Insertable<RelevePresenceLocal> custom({
    Expression<String>? uuidClient,
    Expression<String>? livraisonId,
    Expression<int>? distanceM,
    Expression<DateTime>? releveLeLocal,
    Expression<bool>? envoye,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuidClient != null) 'uuid_client': uuidClient,
      if (livraisonId != null) 'livraison_id': livraisonId,
      if (distanceM != null) 'distance_m': distanceM,
      if (releveLeLocal != null) 'releve_le_local': releveLeLocal,
      if (envoye != null) 'envoye': envoye,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RelevesPresenceLocauxCompanion copyWith({
    Value<String>? uuidClient,
    Value<String>? livraisonId,
    Value<int>? distanceM,
    Value<DateTime>? releveLeLocal,
    Value<bool>? envoye,
    Value<int>? rowid,
  }) {
    return RelevesPresenceLocauxCompanion(
      uuidClient: uuidClient ?? this.uuidClient,
      livraisonId: livraisonId ?? this.livraisonId,
      distanceM: distanceM ?? this.distanceM,
      releveLeLocal: releveLeLocal ?? this.releveLeLocal,
      envoye: envoye ?? this.envoye,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuidClient.present) {
      map['uuid_client'] = Variable<String>(uuidClient.value);
    }
    if (livraisonId.present) {
      map['livraison_id'] = Variable<String>(livraisonId.value);
    }
    if (distanceM.present) {
      map['distance_m'] = Variable<int>(distanceM.value);
    }
    if (releveLeLocal.present) {
      map['releve_le_local'] = Variable<DateTime>(releveLeLocal.value);
    }
    if (envoye.present) {
      map['envoye'] = Variable<bool>(envoye.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RelevesPresenceLocauxCompanion(')
          ..write('uuidClient: $uuidClient, ')
          ..write('livraisonId: $livraisonId, ')
          ..write('distanceM: $distanceM, ')
          ..write('releveLeLocal: $releveLeLocal, ')
          ..write('envoye: $envoye, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CaisseCacheTableTable extends CaisseCacheTable
    with TableInfo<$CaisseCacheTableTable, CaisseCache> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CaisseCacheTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _vueJsonMeta = const VerificationMeta(
    'vueJson',
  );
  @override
  late final GeneratedColumn<String> vueJson = GeneratedColumn<String>(
    'vue_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _luLeLocalMeta = const VerificationMeta(
    'luLeLocal',
  );
  @override
  late final GeneratedColumn<DateTime> luLeLocal = GeneratedColumn<DateTime>(
    'lu_le_local',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, vueJson, luLeLocal];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caisse_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaisseCache> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('vue_json')) {
      context.handle(
        _vueJsonMeta,
        vueJson.isAcceptableOrUnknown(data['vue_json']!, _vueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_vueJsonMeta);
    }
    if (data.containsKey('lu_le_local')) {
      context.handle(
        _luLeLocalMeta,
        luLeLocal.isAcceptableOrUnknown(data['lu_le_local']!, _luLeLocalMeta),
      );
    } else if (isInserting) {
      context.missing(_luLeLocalMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaisseCache map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaisseCache(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      vueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vue_json'],
      )!,
      luLeLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}lu_le_local'],
      )!,
    );
  }

  @override
  $CaisseCacheTableTable createAlias(String alias) {
    return $CaisseCacheTableTable(attachedDatabase, alias);
  }
}

class CaisseCache extends DataClass implements Insertable<CaisseCache> {
  /// Ligne unique — même patron que [CourseCacheTable].
  final int id;

  /// La vue de caisse sérialisée, telle que `GET /moi/caisse` l'a rendue.
  final String vueJson;

  /// Instant de la dernière lecture RÉUSSIE (local) — c'est ce que l'écran
  /// annonce quand il sert ce cache.
  final DateTime luLeLocal;
  const CaisseCache({
    required this.id,
    required this.vueJson,
    required this.luLeLocal,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['vue_json'] = Variable<String>(vueJson);
    map['lu_le_local'] = Variable<DateTime>(luLeLocal);
    return map;
  }

  CaisseCacheTableCompanion toCompanion(bool nullToAbsent) {
    return CaisseCacheTableCompanion(
      id: Value(id),
      vueJson: Value(vueJson),
      luLeLocal: Value(luLeLocal),
    );
  }

  factory CaisseCache.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaisseCache(
      id: serializer.fromJson<int>(json['id']),
      vueJson: serializer.fromJson<String>(json['vueJson']),
      luLeLocal: serializer.fromJson<DateTime>(json['luLeLocal']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'vueJson': serializer.toJson<String>(vueJson),
      'luLeLocal': serializer.toJson<DateTime>(luLeLocal),
    };
  }

  CaisseCache copyWith({int? id, String? vueJson, DateTime? luLeLocal}) =>
      CaisseCache(
        id: id ?? this.id,
        vueJson: vueJson ?? this.vueJson,
        luLeLocal: luLeLocal ?? this.luLeLocal,
      );
  CaisseCache copyWithCompanion(CaisseCacheTableCompanion data) {
    return CaisseCache(
      id: data.id.present ? data.id.value : this.id,
      vueJson: data.vueJson.present ? data.vueJson.value : this.vueJson,
      luLeLocal: data.luLeLocal.present ? data.luLeLocal.value : this.luLeLocal,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaisseCache(')
          ..write('id: $id, ')
          ..write('vueJson: $vueJson, ')
          ..write('luLeLocal: $luLeLocal')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, vueJson, luLeLocal);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaisseCache &&
          other.id == this.id &&
          other.vueJson == this.vueJson &&
          other.luLeLocal == this.luLeLocal);
}

class CaisseCacheTableCompanion extends UpdateCompanion<CaisseCache> {
  final Value<int> id;
  final Value<String> vueJson;
  final Value<DateTime> luLeLocal;
  const CaisseCacheTableCompanion({
    this.id = const Value.absent(),
    this.vueJson = const Value.absent(),
    this.luLeLocal = const Value.absent(),
  });
  CaisseCacheTableCompanion.insert({
    this.id = const Value.absent(),
    required String vueJson,
    required DateTime luLeLocal,
  }) : vueJson = Value(vueJson),
       luLeLocal = Value(luLeLocal);
  static Insertable<CaisseCache> custom({
    Expression<int>? id,
    Expression<String>? vueJson,
    Expression<DateTime>? luLeLocal,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (vueJson != null) 'vue_json': vueJson,
      if (luLeLocal != null) 'lu_le_local': luLeLocal,
    });
  }

  CaisseCacheTableCompanion copyWith({
    Value<int>? id,
    Value<String>? vueJson,
    Value<DateTime>? luLeLocal,
  }) {
    return CaisseCacheTableCompanion(
      id: id ?? this.id,
      vueJson: vueJson ?? this.vueJson,
      luLeLocal: luLeLocal ?? this.luLeLocal,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (vueJson.present) {
      map['vue_json'] = Variable<String>(vueJson.value);
    }
    if (luLeLocal.present) {
      map['lu_le_local'] = Variable<DateTime>(luLeLocal.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaisseCacheTableCompanion(')
          ..write('id: $id, ')
          ..write('vueJson: $vueJson, ')
          ..write('luLeLocal: $luLeLocal')
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
  late final $CourseCacheTableTable courseCacheTable = $CourseCacheTableTable(
    this,
  );
  late final $LignesChecklistTable lignesChecklist = $LignesChecklistTable(
    this,
  );
  late final $EssaisRemiseTable essaisRemise = $EssaisRemiseTable(this);
  late final $RelevesPresenceLocauxTable relevesPresenceLocaux =
      $RelevesPresenceLocauxTable(this);
  late final $CaisseCacheTableTable caisseCacheTable = $CaisseCacheTableTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    actionsEnAttente,
    arretsPreprovisionnes,
    brouillonsPanier,
    commandesCache,
    courseCacheTable,
    lignesChecklist,
    essaisRemise,
    relevesPresenceLocaux,
    caisseCacheTable,
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
      Value<bool> multipart,
      Value<String> statut,
      Value<DateTime?> refuseLeLocal,
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
      Value<bool> multipart,
      Value<String> statut,
      Value<DateTime?> refuseLeLocal,
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

  ColumnFilters<bool> get multipart => $composableBuilder(
    column: $table.multipart,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get refuseLeLocal => $composableBuilder(
    column: $table.refuseLeLocal,
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

  ColumnOrderings<bool> get multipart => $composableBuilder(
    column: $table.multipart,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get refuseLeLocal => $composableBuilder(
    column: $table.refuseLeLocal,
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

  GeneratedColumn<bool> get multipart =>
      $composableBuilder(column: $table.multipart, builder: (column) => column);

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<DateTime> get refuseLeLocal => $composableBuilder(
    column: $table.refuseLeLocal,
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
                Value<bool> multipart = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime?> refuseLeLocal = const Value.absent(),
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
                multipart: multipart,
                statut: statut,
                refuseLeLocal: refuseLeLocal,
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
                Value<bool> multipart = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<DateTime?> refuseLeLocal = const Value.absent(),
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
                multipart: multipart,
                statut: statut,
                refuseLeLocal: refuseLeLocal,
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
      Value<int> montantArticlesUnites,
      Value<int> retenueAppliqueeUnites,
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
      Value<int> montantArticlesUnites,
      Value<int> retenueAppliqueeUnites,
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

  ColumnFilters<int> get montantArticlesUnites => $composableBuilder(
    column: $table.montantArticlesUnites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retenueAppliqueeUnites => $composableBuilder(
    column: $table.retenueAppliqueeUnites,
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

  ColumnOrderings<int> get montantArticlesUnites => $composableBuilder(
    column: $table.montantArticlesUnites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retenueAppliqueeUnites => $composableBuilder(
    column: $table.retenueAppliqueeUnites,
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

  GeneratedColumn<int> get montantArticlesUnites => $composableBuilder(
    column: $table.montantArticlesUnites,
    builder: (column) => column,
  );

  GeneratedColumn<int> get retenueAppliqueeUnites => $composableBuilder(
    column: $table.retenueAppliqueeUnites,
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
                Value<int> montantArticlesUnites = const Value.absent(),
                Value<int> retenueAppliqueeUnites = const Value.absent(),
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
                montantArticlesUnites: montantArticlesUnites,
                retenueAppliqueeUnites: retenueAppliqueeUnites,
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
                Value<int> montantArticlesUnites = const Value.absent(),
                Value<int> retenueAppliqueeUnites = const Value.absent(),
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
                montantArticlesUnites: montantArticlesUnites,
                retenueAppliqueeUnites: retenueAppliqueeUnites,
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
typedef $$CourseCacheTableTableCreateCompanionBuilder =
    CourseCacheTableCompanion Function({
      required String livraisonId,
      required String commandeId,
      required String etat,
      Value<String> devise,
      Value<String> clientNomUsage,
      Value<String?> clientTelephone,
      Value<String?> repereTexte,
      Value<String?> repereVocalFichier,
      Value<int?> repereVocalDureeS,
      Value<double?> lieuLat,
      Value<double?> lieuLon,
      Value<bool> depotAutorise,
      Value<String> empreinteCode,
      Value<String> empreinteJeton,
      Value<int> essaisConsommes,
      Value<int> essaisMax,
      Value<bool> codeBloque,
      Value<int> montantAEncaisserUnites,
      Value<String> modePaiement,
      Value<String> seuilsPreuvesJson,
      Value<String?> arretRemiseId,
      Value<String?> arretRemiseStatut,
      Value<DateTime?> arriveChezClientLe,
      Value<DateTime?> remiseValideeLocalementLe,
      required DateTime majLeLocal,
      Value<int> rowid,
    });
typedef $$CourseCacheTableTableUpdateCompanionBuilder =
    CourseCacheTableCompanion Function({
      Value<String> livraisonId,
      Value<String> commandeId,
      Value<String> etat,
      Value<String> devise,
      Value<String> clientNomUsage,
      Value<String?> clientTelephone,
      Value<String?> repereTexte,
      Value<String?> repereVocalFichier,
      Value<int?> repereVocalDureeS,
      Value<double?> lieuLat,
      Value<double?> lieuLon,
      Value<bool> depotAutorise,
      Value<String> empreinteCode,
      Value<String> empreinteJeton,
      Value<int> essaisConsommes,
      Value<int> essaisMax,
      Value<bool> codeBloque,
      Value<int> montantAEncaisserUnites,
      Value<String> modePaiement,
      Value<String> seuilsPreuvesJson,
      Value<String?> arretRemiseId,
      Value<String?> arretRemiseStatut,
      Value<DateTime?> arriveChezClientLe,
      Value<DateTime?> remiseValideeLocalementLe,
      Value<DateTime> majLeLocal,
      Value<int> rowid,
    });

class $$CourseCacheTableTableFilterComposer
    extends Composer<_$BaseOffline, $CourseCacheTableTable> {
  $$CourseCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get etat => $composableBuilder(
    column: $table.etat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientNomUsage => $composableBuilder(
    column: $table.clientNomUsage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clientTelephone => $composableBuilder(
    column: $table.clientTelephone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repereTexte => $composableBuilder(
    column: $table.repereTexte,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get repereVocalFichier => $composableBuilder(
    column: $table.repereVocalFichier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get repereVocalDureeS => $composableBuilder(
    column: $table.repereVocalDureeS,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lieuLat => $composableBuilder(
    column: $table.lieuLat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lieuLon => $composableBuilder(
    column: $table.lieuLon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get depotAutorise => $composableBuilder(
    column: $table.depotAutorise,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get essaisConsommes => $composableBuilder(
    column: $table.essaisConsommes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get essaisMax => $composableBuilder(
    column: $table.essaisMax,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get codeBloque => $composableBuilder(
    column: $table.codeBloque,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get montantAEncaisserUnites => $composableBuilder(
    column: $table.montantAEncaisserUnites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get seuilsPreuvesJson => $composableBuilder(
    column: $table.seuilsPreuvesJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arretRemiseId => $composableBuilder(
    column: $table.arretRemiseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arretRemiseStatut => $composableBuilder(
    column: $table.arretRemiseStatut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get arriveChezClientLe => $composableBuilder(
    column: $table.arriveChezClientLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get remiseValideeLocalementLe => $composableBuilder(
    column: $table.remiseValideeLocalementLe,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CourseCacheTableTableOrderingComposer
    extends Composer<_$BaseOffline, $CourseCacheTableTable> {
  $$CourseCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get etat => $composableBuilder(
    column: $table.etat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get devise => $composableBuilder(
    column: $table.devise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientNomUsage => $composableBuilder(
    column: $table.clientNomUsage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clientTelephone => $composableBuilder(
    column: $table.clientTelephone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repereTexte => $composableBuilder(
    column: $table.repereTexte,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get repereVocalFichier => $composableBuilder(
    column: $table.repereVocalFichier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get repereVocalDureeS => $composableBuilder(
    column: $table.repereVocalDureeS,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lieuLat => $composableBuilder(
    column: $table.lieuLat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lieuLon => $composableBuilder(
    column: $table.lieuLon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get depotAutorise => $composableBuilder(
    column: $table.depotAutorise,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get essaisConsommes => $composableBuilder(
    column: $table.essaisConsommes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get essaisMax => $composableBuilder(
    column: $table.essaisMax,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get codeBloque => $composableBuilder(
    column: $table.codeBloque,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get montantAEncaisserUnites => $composableBuilder(
    column: $table.montantAEncaisserUnites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get seuilsPreuvesJson => $composableBuilder(
    column: $table.seuilsPreuvesJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arretRemiseId => $composableBuilder(
    column: $table.arretRemiseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arretRemiseStatut => $composableBuilder(
    column: $table.arretRemiseStatut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get arriveChezClientLe => $composableBuilder(
    column: $table.arriveChezClientLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get remiseValideeLocalementLe => $composableBuilder(
    column: $table.remiseValideeLocalementLe,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CourseCacheTableTableAnnotationComposer
    extends Composer<_$BaseOffline, $CourseCacheTableTable> {
  $$CourseCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get commandeId => $composableBuilder(
    column: $table.commandeId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get etat =>
      $composableBuilder(column: $table.etat, builder: (column) => column);

  GeneratedColumn<String> get devise =>
      $composableBuilder(column: $table.devise, builder: (column) => column);

  GeneratedColumn<String> get clientNomUsage => $composableBuilder(
    column: $table.clientNomUsage,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clientTelephone => $composableBuilder(
    column: $table.clientTelephone,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repereTexte => $composableBuilder(
    column: $table.repereTexte,
    builder: (column) => column,
  );

  GeneratedColumn<String> get repereVocalFichier => $composableBuilder(
    column: $table.repereVocalFichier,
    builder: (column) => column,
  );

  GeneratedColumn<int> get repereVocalDureeS => $composableBuilder(
    column: $table.repereVocalDureeS,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lieuLat =>
      $composableBuilder(column: $table.lieuLat, builder: (column) => column);

  GeneratedColumn<double> get lieuLon =>
      $composableBuilder(column: $table.lieuLon, builder: (column) => column);

  GeneratedColumn<bool> get depotAutorise => $composableBuilder(
    column: $table.depotAutorise,
    builder: (column) => column,
  );

  GeneratedColumn<String> get empreinteCode => $composableBuilder(
    column: $table.empreinteCode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get empreinteJeton => $composableBuilder(
    column: $table.empreinteJeton,
    builder: (column) => column,
  );

  GeneratedColumn<int> get essaisConsommes => $composableBuilder(
    column: $table.essaisConsommes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get essaisMax =>
      $composableBuilder(column: $table.essaisMax, builder: (column) => column);

  GeneratedColumn<bool> get codeBloque => $composableBuilder(
    column: $table.codeBloque,
    builder: (column) => column,
  );

  GeneratedColumn<int> get montantAEncaisserUnites => $composableBuilder(
    column: $table.montantAEncaisserUnites,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modePaiement => $composableBuilder(
    column: $table.modePaiement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get seuilsPreuvesJson => $composableBuilder(
    column: $table.seuilsPreuvesJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arretRemiseId => $composableBuilder(
    column: $table.arretRemiseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get arretRemiseStatut => $composableBuilder(
    column: $table.arretRemiseStatut,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get arriveChezClientLe => $composableBuilder(
    column: $table.arriveChezClientLe,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get remiseValideeLocalementLe => $composableBuilder(
    column: $table.remiseValideeLocalementLe,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get majLeLocal => $composableBuilder(
    column: $table.majLeLocal,
    builder: (column) => column,
  );
}

class $$CourseCacheTableTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $CourseCacheTableTable,
          CourseCache,
          $$CourseCacheTableTableFilterComposer,
          $$CourseCacheTableTableOrderingComposer,
          $$CourseCacheTableTableAnnotationComposer,
          $$CourseCacheTableTableCreateCompanionBuilder,
          $$CourseCacheTableTableUpdateCompanionBuilder,
          (
            CourseCache,
            BaseReferences<_$BaseOffline, $CourseCacheTableTable, CourseCache>,
          ),
          CourseCache,
          PrefetchHooks Function()
        > {
  $$CourseCacheTableTableTableManager(
    _$BaseOffline db,
    $CourseCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CourseCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CourseCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CourseCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> livraisonId = const Value.absent(),
                Value<String> commandeId = const Value.absent(),
                Value<String> etat = const Value.absent(),
                Value<String> devise = const Value.absent(),
                Value<String> clientNomUsage = const Value.absent(),
                Value<String?> clientTelephone = const Value.absent(),
                Value<String?> repereTexte = const Value.absent(),
                Value<String?> repereVocalFichier = const Value.absent(),
                Value<int?> repereVocalDureeS = const Value.absent(),
                Value<double?> lieuLat = const Value.absent(),
                Value<double?> lieuLon = const Value.absent(),
                Value<bool> depotAutorise = const Value.absent(),
                Value<String> empreinteCode = const Value.absent(),
                Value<String> empreinteJeton = const Value.absent(),
                Value<int> essaisConsommes = const Value.absent(),
                Value<int> essaisMax = const Value.absent(),
                Value<bool> codeBloque = const Value.absent(),
                Value<int> montantAEncaisserUnites = const Value.absent(),
                Value<String> modePaiement = const Value.absent(),
                Value<String> seuilsPreuvesJson = const Value.absent(),
                Value<String?> arretRemiseId = const Value.absent(),
                Value<String?> arretRemiseStatut = const Value.absent(),
                Value<DateTime?> arriveChezClientLe = const Value.absent(),
                Value<DateTime?> remiseValideeLocalementLe =
                    const Value.absent(),
                Value<DateTime> majLeLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CourseCacheTableCompanion(
                livraisonId: livraisonId,
                commandeId: commandeId,
                etat: etat,
                devise: devise,
                clientNomUsage: clientNomUsage,
                clientTelephone: clientTelephone,
                repereTexte: repereTexte,
                repereVocalFichier: repereVocalFichier,
                repereVocalDureeS: repereVocalDureeS,
                lieuLat: lieuLat,
                lieuLon: lieuLon,
                depotAutorise: depotAutorise,
                empreinteCode: empreinteCode,
                empreinteJeton: empreinteJeton,
                essaisConsommes: essaisConsommes,
                essaisMax: essaisMax,
                codeBloque: codeBloque,
                montantAEncaisserUnites: montantAEncaisserUnites,
                modePaiement: modePaiement,
                seuilsPreuvesJson: seuilsPreuvesJson,
                arretRemiseId: arretRemiseId,
                arretRemiseStatut: arretRemiseStatut,
                arriveChezClientLe: arriveChezClientLe,
                remiseValideeLocalementLe: remiseValideeLocalementLe,
                majLeLocal: majLeLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String livraisonId,
                required String commandeId,
                required String etat,
                Value<String> devise = const Value.absent(),
                Value<String> clientNomUsage = const Value.absent(),
                Value<String?> clientTelephone = const Value.absent(),
                Value<String?> repereTexte = const Value.absent(),
                Value<String?> repereVocalFichier = const Value.absent(),
                Value<int?> repereVocalDureeS = const Value.absent(),
                Value<double?> lieuLat = const Value.absent(),
                Value<double?> lieuLon = const Value.absent(),
                Value<bool> depotAutorise = const Value.absent(),
                Value<String> empreinteCode = const Value.absent(),
                Value<String> empreinteJeton = const Value.absent(),
                Value<int> essaisConsommes = const Value.absent(),
                Value<int> essaisMax = const Value.absent(),
                Value<bool> codeBloque = const Value.absent(),
                Value<int> montantAEncaisserUnites = const Value.absent(),
                Value<String> modePaiement = const Value.absent(),
                Value<String> seuilsPreuvesJson = const Value.absent(),
                Value<String?> arretRemiseId = const Value.absent(),
                Value<String?> arretRemiseStatut = const Value.absent(),
                Value<DateTime?> arriveChezClientLe = const Value.absent(),
                Value<DateTime?> remiseValideeLocalementLe =
                    const Value.absent(),
                required DateTime majLeLocal,
                Value<int> rowid = const Value.absent(),
              }) => CourseCacheTableCompanion.insert(
                livraisonId: livraisonId,
                commandeId: commandeId,
                etat: etat,
                devise: devise,
                clientNomUsage: clientNomUsage,
                clientTelephone: clientTelephone,
                repereTexte: repereTexte,
                repereVocalFichier: repereVocalFichier,
                repereVocalDureeS: repereVocalDureeS,
                lieuLat: lieuLat,
                lieuLon: lieuLon,
                depotAutorise: depotAutorise,
                empreinteCode: empreinteCode,
                empreinteJeton: empreinteJeton,
                essaisConsommes: essaisConsommes,
                essaisMax: essaisMax,
                codeBloque: codeBloque,
                montantAEncaisserUnites: montantAEncaisserUnites,
                modePaiement: modePaiement,
                seuilsPreuvesJson: seuilsPreuvesJson,
                arretRemiseId: arretRemiseId,
                arretRemiseStatut: arretRemiseStatut,
                arriveChezClientLe: arriveChezClientLe,
                remiseValideeLocalementLe: remiseValideeLocalementLe,
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

typedef $$CourseCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $CourseCacheTableTable,
      CourseCache,
      $$CourseCacheTableTableFilterComposer,
      $$CourseCacheTableTableOrderingComposer,
      $$CourseCacheTableTableAnnotationComposer,
      $$CourseCacheTableTableCreateCompanionBuilder,
      $$CourseCacheTableTableUpdateCompanionBuilder,
      (
        CourseCache,
        BaseReferences<_$BaseOffline, $CourseCacheTableTable, CourseCache>,
      ),
      CourseCache,
      PrefetchHooks Function()
    >;
typedef $$LignesChecklistTableCreateCompanionBuilder =
    LignesChecklistCompanion Function({
      required String ligneId,
      required String arretId,
      required String libelle,
      Value<int> quantite,
      Value<int> prixUnitaireUnites,
      Value<String> preference,
      Value<String> statut,
      Value<bool> cochee,
      Value<int> ordre,
      Value<int> rowid,
    });
typedef $$LignesChecklistTableUpdateCompanionBuilder =
    LignesChecklistCompanion Function({
      Value<String> ligneId,
      Value<String> arretId,
      Value<String> libelle,
      Value<int> quantite,
      Value<int> prixUnitaireUnites,
      Value<String> preference,
      Value<String> statut,
      Value<bool> cochee,
      Value<int> ordre,
      Value<int> rowid,
    });

class $$LignesChecklistTableFilterComposer
    extends Composer<_$BaseOffline, $LignesChecklistTable> {
  $$LignesChecklistTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ligneId => $composableBuilder(
    column: $table.ligneId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get arretId => $composableBuilder(
    column: $table.arretId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quantite => $composableBuilder(
    column: $table.quantite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get prixUnitaireUnites => $composableBuilder(
    column: $table.prixUnitaireUnites,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get preference => $composableBuilder(
    column: $table.preference,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get cochee => $composableBuilder(
    column: $table.cochee,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LignesChecklistTableOrderingComposer
    extends Composer<_$BaseOffline, $LignesChecklistTable> {
  $$LignesChecklistTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ligneId => $composableBuilder(
    column: $table.ligneId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get arretId => $composableBuilder(
    column: $table.arretId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get libelle => $composableBuilder(
    column: $table.libelle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quantite => $composableBuilder(
    column: $table.quantite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get prixUnitaireUnites => $composableBuilder(
    column: $table.prixUnitaireUnites,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get preference => $composableBuilder(
    column: $table.preference,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get statut => $composableBuilder(
    column: $table.statut,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get cochee => $composableBuilder(
    column: $table.cochee,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ordre => $composableBuilder(
    column: $table.ordre,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LignesChecklistTableAnnotationComposer
    extends Composer<_$BaseOffline, $LignesChecklistTable> {
  $$LignesChecklistTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ligneId =>
      $composableBuilder(column: $table.ligneId, builder: (column) => column);

  GeneratedColumn<String> get arretId =>
      $composableBuilder(column: $table.arretId, builder: (column) => column);

  GeneratedColumn<String> get libelle =>
      $composableBuilder(column: $table.libelle, builder: (column) => column);

  GeneratedColumn<int> get quantite =>
      $composableBuilder(column: $table.quantite, builder: (column) => column);

  GeneratedColumn<int> get prixUnitaireUnites => $composableBuilder(
    column: $table.prixUnitaireUnites,
    builder: (column) => column,
  );

  GeneratedColumn<String> get preference => $composableBuilder(
    column: $table.preference,
    builder: (column) => column,
  );

  GeneratedColumn<String> get statut =>
      $composableBuilder(column: $table.statut, builder: (column) => column);

  GeneratedColumn<bool> get cochee =>
      $composableBuilder(column: $table.cochee, builder: (column) => column);

  GeneratedColumn<int> get ordre =>
      $composableBuilder(column: $table.ordre, builder: (column) => column);
}

class $$LignesChecklistTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $LignesChecklistTable,
          LigneChecklist,
          $$LignesChecklistTableFilterComposer,
          $$LignesChecklistTableOrderingComposer,
          $$LignesChecklistTableAnnotationComposer,
          $$LignesChecklistTableCreateCompanionBuilder,
          $$LignesChecklistTableUpdateCompanionBuilder,
          (
            LigneChecklist,
            BaseReferences<
              _$BaseOffline,
              $LignesChecklistTable,
              LigneChecklist
            >,
          ),
          LigneChecklist,
          PrefetchHooks Function()
        > {
  $$LignesChecklistTableTableManager(
    _$BaseOffline db,
    $LignesChecklistTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LignesChecklistTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LignesChecklistTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LignesChecklistTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ligneId = const Value.absent(),
                Value<String> arretId = const Value.absent(),
                Value<String> libelle = const Value.absent(),
                Value<int> quantite = const Value.absent(),
                Value<int> prixUnitaireUnites = const Value.absent(),
                Value<String> preference = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<bool> cochee = const Value.absent(),
                Value<int> ordre = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LignesChecklistCompanion(
                ligneId: ligneId,
                arretId: arretId,
                libelle: libelle,
                quantite: quantite,
                prixUnitaireUnites: prixUnitaireUnites,
                preference: preference,
                statut: statut,
                cochee: cochee,
                ordre: ordre,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ligneId,
                required String arretId,
                required String libelle,
                Value<int> quantite = const Value.absent(),
                Value<int> prixUnitaireUnites = const Value.absent(),
                Value<String> preference = const Value.absent(),
                Value<String> statut = const Value.absent(),
                Value<bool> cochee = const Value.absent(),
                Value<int> ordre = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LignesChecklistCompanion.insert(
                ligneId: ligneId,
                arretId: arretId,
                libelle: libelle,
                quantite: quantite,
                prixUnitaireUnites: prixUnitaireUnites,
                preference: preference,
                statut: statut,
                cochee: cochee,
                ordre: ordre,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LignesChecklistTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $LignesChecklistTable,
      LigneChecklist,
      $$LignesChecklistTableFilterComposer,
      $$LignesChecklistTableOrderingComposer,
      $$LignesChecklistTableAnnotationComposer,
      $$LignesChecklistTableCreateCompanionBuilder,
      $$LignesChecklistTableUpdateCompanionBuilder,
      (
        LigneChecklist,
        BaseReferences<_$BaseOffline, $LignesChecklistTable, LigneChecklist>,
      ),
      LigneChecklist,
      PrefetchHooks Function()
    >;
typedef $$EssaisRemiseTableCreateCompanionBuilder =
    EssaisRemiseCompanion Function({
      required String livraisonId,
      Value<int> essaisHorsLigne,
      Value<DateTime?> dernierEssaiLocal,
      Value<int> rowid,
    });
typedef $$EssaisRemiseTableUpdateCompanionBuilder =
    EssaisRemiseCompanion Function({
      Value<String> livraisonId,
      Value<int> essaisHorsLigne,
      Value<DateTime?> dernierEssaiLocal,
      Value<int> rowid,
    });

class $$EssaisRemiseTableFilterComposer
    extends Composer<_$BaseOffline, $EssaisRemiseTable> {
  $$EssaisRemiseTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get essaisHorsLigne => $composableBuilder(
    column: $table.essaisHorsLigne,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dernierEssaiLocal => $composableBuilder(
    column: $table.dernierEssaiLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EssaisRemiseTableOrderingComposer
    extends Composer<_$BaseOffline, $EssaisRemiseTable> {
  $$EssaisRemiseTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get essaisHorsLigne => $composableBuilder(
    column: $table.essaisHorsLigne,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dernierEssaiLocal => $composableBuilder(
    column: $table.dernierEssaiLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EssaisRemiseTableAnnotationComposer
    extends Composer<_$BaseOffline, $EssaisRemiseTable> {
  $$EssaisRemiseTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get essaisHorsLigne => $composableBuilder(
    column: $table.essaisHorsLigne,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dernierEssaiLocal => $composableBuilder(
    column: $table.dernierEssaiLocal,
    builder: (column) => column,
  );
}

class $$EssaisRemiseTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $EssaisRemiseTable,
          EssaiRemise,
          $$EssaisRemiseTableFilterComposer,
          $$EssaisRemiseTableOrderingComposer,
          $$EssaisRemiseTableAnnotationComposer,
          $$EssaisRemiseTableCreateCompanionBuilder,
          $$EssaisRemiseTableUpdateCompanionBuilder,
          (
            EssaiRemise,
            BaseReferences<_$BaseOffline, $EssaisRemiseTable, EssaiRemise>,
          ),
          EssaiRemise,
          PrefetchHooks Function()
        > {
  $$EssaisRemiseTableTableManager(_$BaseOffline db, $EssaisRemiseTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EssaisRemiseTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EssaisRemiseTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EssaisRemiseTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> livraisonId = const Value.absent(),
                Value<int> essaisHorsLigne = const Value.absent(),
                Value<DateTime?> dernierEssaiLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EssaisRemiseCompanion(
                livraisonId: livraisonId,
                essaisHorsLigne: essaisHorsLigne,
                dernierEssaiLocal: dernierEssaiLocal,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String livraisonId,
                Value<int> essaisHorsLigne = const Value.absent(),
                Value<DateTime?> dernierEssaiLocal = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EssaisRemiseCompanion.insert(
                livraisonId: livraisonId,
                essaisHorsLigne: essaisHorsLigne,
                dernierEssaiLocal: dernierEssaiLocal,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EssaisRemiseTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $EssaisRemiseTable,
      EssaiRemise,
      $$EssaisRemiseTableFilterComposer,
      $$EssaisRemiseTableOrderingComposer,
      $$EssaisRemiseTableAnnotationComposer,
      $$EssaisRemiseTableCreateCompanionBuilder,
      $$EssaisRemiseTableUpdateCompanionBuilder,
      (
        EssaiRemise,
        BaseReferences<_$BaseOffline, $EssaisRemiseTable, EssaiRemise>,
      ),
      EssaiRemise,
      PrefetchHooks Function()
    >;
typedef $$RelevesPresenceLocauxTableCreateCompanionBuilder =
    RelevesPresenceLocauxCompanion Function({
      required String uuidClient,
      required String livraisonId,
      required int distanceM,
      required DateTime releveLeLocal,
      Value<bool> envoye,
      Value<int> rowid,
    });
typedef $$RelevesPresenceLocauxTableUpdateCompanionBuilder =
    RelevesPresenceLocauxCompanion Function({
      Value<String> uuidClient,
      Value<String> livraisonId,
      Value<int> distanceM,
      Value<DateTime> releveLeLocal,
      Value<bool> envoye,
      Value<int> rowid,
    });

class $$RelevesPresenceLocauxTableFilterComposer
    extends Composer<_$BaseOffline, $RelevesPresenceLocauxTable> {
  $$RelevesPresenceLocauxTableFilterComposer({
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

  ColumnFilters<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get releveLeLocal => $composableBuilder(
    column: $table.releveLeLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get envoye => $composableBuilder(
    column: $table.envoye,
    builder: (column) => ColumnFilters(column),
  );
}

class $$RelevesPresenceLocauxTableOrderingComposer
    extends Composer<_$BaseOffline, $RelevesPresenceLocauxTable> {
  $$RelevesPresenceLocauxTableOrderingComposer({
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

  ColumnOrderings<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get distanceM => $composableBuilder(
    column: $table.distanceM,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get releveLeLocal => $composableBuilder(
    column: $table.releveLeLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get envoye => $composableBuilder(
    column: $table.envoye,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$RelevesPresenceLocauxTableAnnotationComposer
    extends Composer<_$BaseOffline, $RelevesPresenceLocauxTable> {
  $$RelevesPresenceLocauxTableAnnotationComposer({
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

  GeneratedColumn<String> get livraisonId => $composableBuilder(
    column: $table.livraisonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get distanceM =>
      $composableBuilder(column: $table.distanceM, builder: (column) => column);

  GeneratedColumn<DateTime> get releveLeLocal => $composableBuilder(
    column: $table.releveLeLocal,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get envoye =>
      $composableBuilder(column: $table.envoye, builder: (column) => column);
}

class $$RelevesPresenceLocauxTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $RelevesPresenceLocauxTable,
          RelevePresenceLocal,
          $$RelevesPresenceLocauxTableFilterComposer,
          $$RelevesPresenceLocauxTableOrderingComposer,
          $$RelevesPresenceLocauxTableAnnotationComposer,
          $$RelevesPresenceLocauxTableCreateCompanionBuilder,
          $$RelevesPresenceLocauxTableUpdateCompanionBuilder,
          (
            RelevePresenceLocal,
            BaseReferences<
              _$BaseOffline,
              $RelevesPresenceLocauxTable,
              RelevePresenceLocal
            >,
          ),
          RelevePresenceLocal,
          PrefetchHooks Function()
        > {
  $$RelevesPresenceLocauxTableTableManager(
    _$BaseOffline db,
    $RelevesPresenceLocauxTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RelevesPresenceLocauxTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$RelevesPresenceLocauxTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$RelevesPresenceLocauxTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uuidClient = const Value.absent(),
                Value<String> livraisonId = const Value.absent(),
                Value<int> distanceM = const Value.absent(),
                Value<DateTime> releveLeLocal = const Value.absent(),
                Value<bool> envoye = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelevesPresenceLocauxCompanion(
                uuidClient: uuidClient,
                livraisonId: livraisonId,
                distanceM: distanceM,
                releveLeLocal: releveLeLocal,
                envoye: envoye,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uuidClient,
                required String livraisonId,
                required int distanceM,
                required DateTime releveLeLocal,
                Value<bool> envoye = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RelevesPresenceLocauxCompanion.insert(
                uuidClient: uuidClient,
                livraisonId: livraisonId,
                distanceM: distanceM,
                releveLeLocal: releveLeLocal,
                envoye: envoye,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$RelevesPresenceLocauxTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $RelevesPresenceLocauxTable,
      RelevePresenceLocal,
      $$RelevesPresenceLocauxTableFilterComposer,
      $$RelevesPresenceLocauxTableOrderingComposer,
      $$RelevesPresenceLocauxTableAnnotationComposer,
      $$RelevesPresenceLocauxTableCreateCompanionBuilder,
      $$RelevesPresenceLocauxTableUpdateCompanionBuilder,
      (
        RelevePresenceLocal,
        BaseReferences<
          _$BaseOffline,
          $RelevesPresenceLocauxTable,
          RelevePresenceLocal
        >,
      ),
      RelevePresenceLocal,
      PrefetchHooks Function()
    >;
typedef $$CaisseCacheTableTableCreateCompanionBuilder =
    CaisseCacheTableCompanion Function({
      Value<int> id,
      required String vueJson,
      required DateTime luLeLocal,
    });
typedef $$CaisseCacheTableTableUpdateCompanionBuilder =
    CaisseCacheTableCompanion Function({
      Value<int> id,
      Value<String> vueJson,
      Value<DateTime> luLeLocal,
    });

class $$CaisseCacheTableTableFilterComposer
    extends Composer<_$BaseOffline, $CaisseCacheTableTable> {
  $$CaisseCacheTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get vueJson => $composableBuilder(
    column: $table.vueJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get luLeLocal => $composableBuilder(
    column: $table.luLeLocal,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CaisseCacheTableTableOrderingComposer
    extends Composer<_$BaseOffline, $CaisseCacheTableTable> {
  $$CaisseCacheTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get vueJson => $composableBuilder(
    column: $table.vueJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get luLeLocal => $composableBuilder(
    column: $table.luLeLocal,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CaisseCacheTableTableAnnotationComposer
    extends Composer<_$BaseOffline, $CaisseCacheTableTable> {
  $$CaisseCacheTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get vueJson =>
      $composableBuilder(column: $table.vueJson, builder: (column) => column);

  GeneratedColumn<DateTime> get luLeLocal =>
      $composableBuilder(column: $table.luLeLocal, builder: (column) => column);
}

class $$CaisseCacheTableTableTableManager
    extends
        RootTableManager<
          _$BaseOffline,
          $CaisseCacheTableTable,
          CaisseCache,
          $$CaisseCacheTableTableFilterComposer,
          $$CaisseCacheTableTableOrderingComposer,
          $$CaisseCacheTableTableAnnotationComposer,
          $$CaisseCacheTableTableCreateCompanionBuilder,
          $$CaisseCacheTableTableUpdateCompanionBuilder,
          (
            CaisseCache,
            BaseReferences<_$BaseOffline, $CaisseCacheTableTable, CaisseCache>,
          ),
          CaisseCache,
          PrefetchHooks Function()
        > {
  $$CaisseCacheTableTableTableManager(
    _$BaseOffline db,
    $CaisseCacheTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CaisseCacheTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CaisseCacheTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CaisseCacheTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> vueJson = const Value.absent(),
                Value<DateTime> luLeLocal = const Value.absent(),
              }) => CaisseCacheTableCompanion(
                id: id,
                vueJson: vueJson,
                luLeLocal: luLeLocal,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String vueJson,
                required DateTime luLeLocal,
              }) => CaisseCacheTableCompanion.insert(
                id: id,
                vueJson: vueJson,
                luLeLocal: luLeLocal,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CaisseCacheTableTableProcessedTableManager =
    ProcessedTableManager<
      _$BaseOffline,
      $CaisseCacheTableTable,
      CaisseCache,
      $$CaisseCacheTableTableFilterComposer,
      $$CaisseCacheTableTableOrderingComposer,
      $$CaisseCacheTableTableAnnotationComposer,
      $$CaisseCacheTableTableCreateCompanionBuilder,
      $$CaisseCacheTableTableUpdateCompanionBuilder,
      (
        CaisseCache,
        BaseReferences<_$BaseOffline, $CaisseCacheTableTable, CaisseCache>,
      ),
      CaisseCache,
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
  $$CourseCacheTableTableTableManager get courseCacheTable =>
      $$CourseCacheTableTableTableManager(_db, _db.courseCacheTable);
  $$LignesChecklistTableTableManager get lignesChecklist =>
      $$LignesChecklistTableTableManager(_db, _db.lignesChecklist);
  $$EssaisRemiseTableTableManager get essaisRemise =>
      $$EssaisRemiseTableTableManager(_db, _db.essaisRemise);
  $$RelevesPresenceLocauxTableTableManager get relevesPresenceLocaux =>
      $$RelevesPresenceLocauxTableTableManager(_db, _db.relevesPresenceLocaux);
  $$CaisseCacheTableTableTableManager get caisseCacheTable =>
      $$CaisseCacheTableTableTableManager(_db, _db.caisseCacheTable);
}
