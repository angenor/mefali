// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'adresse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Adresse extends Adresse {
  @override
  final bool aRepereVocal;
  @override
  final DateTime creeLe;
  @override
  final DateTime derniereUtilisationLe;
  @override
  final String id;
  @override
  final double lat;
  @override
  final String libelle;
  @override
  final double lng;
  @override
  final String? repereTexte;
  @override
  final int? repereVocalDureeS;
  @override
  final String zoneId;

  factory _$Adresse([void Function(AdresseBuilder)? updates]) =>
      (AdresseBuilder()..update(updates))._build();

  _$Adresse._(
      {required this.aRepereVocal,
      required this.creeLe,
      required this.derniereUtilisationLe,
      required this.id,
      required this.lat,
      required this.libelle,
      required this.lng,
      this.repereTexte,
      this.repereVocalDureeS,
      required this.zoneId})
      : super._();
  @override
  Adresse rebuild(void Function(AdresseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AdresseBuilder toBuilder() => AdresseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Adresse &&
        aRepereVocal == other.aRepereVocal &&
        creeLe == other.creeLe &&
        derniereUtilisationLe == other.derniereUtilisationLe &&
        id == other.id &&
        lat == other.lat &&
        libelle == other.libelle &&
        lng == other.lng &&
        repereTexte == other.repereTexte &&
        repereVocalDureeS == other.repereVocalDureeS &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, aRepereVocal.hashCode);
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, derniereUtilisationLe.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, libelle.hashCode);
    _$hash = $jc(_$hash, lng.hashCode);
    _$hash = $jc(_$hash, repereTexte.hashCode);
    _$hash = $jc(_$hash, repereVocalDureeS.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Adresse')
          ..add('aRepereVocal', aRepereVocal)
          ..add('creeLe', creeLe)
          ..add('derniereUtilisationLe', derniereUtilisationLe)
          ..add('id', id)
          ..add('lat', lat)
          ..add('libelle', libelle)
          ..add('lng', lng)
          ..add('repereTexte', repereTexte)
          ..add('repereVocalDureeS', repereVocalDureeS)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class AdresseBuilder implements Builder<Adresse, AdresseBuilder> {
  _$Adresse? _$v;

  bool? _aRepereVocal;
  bool? get aRepereVocal => _$this._aRepereVocal;
  set aRepereVocal(bool? aRepereVocal) => _$this._aRepereVocal = aRepereVocal;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  DateTime? _derniereUtilisationLe;
  DateTime? get derniereUtilisationLe => _$this._derniereUtilisationLe;
  set derniereUtilisationLe(DateTime? derniereUtilisationLe) =>
      _$this._derniereUtilisationLe = derniereUtilisationLe;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  String? _libelle;
  String? get libelle => _$this._libelle;
  set libelle(String? libelle) => _$this._libelle = libelle;

  double? _lng;
  double? get lng => _$this._lng;
  set lng(double? lng) => _$this._lng = lng;

  String? _repereTexte;
  String? get repereTexte => _$this._repereTexte;
  set repereTexte(String? repereTexte) => _$this._repereTexte = repereTexte;

  int? _repereVocalDureeS;
  int? get repereVocalDureeS => _$this._repereVocalDureeS;
  set repereVocalDureeS(int? repereVocalDureeS) =>
      _$this._repereVocalDureeS = repereVocalDureeS;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  AdresseBuilder() {
    Adresse._defaults(this);
  }

  AdresseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _aRepereVocal = $v.aRepereVocal;
      _creeLe = $v.creeLe;
      _derniereUtilisationLe = $v.derniereUtilisationLe;
      _id = $v.id;
      _lat = $v.lat;
      _libelle = $v.libelle;
      _lng = $v.lng;
      _repereTexte = $v.repereTexte;
      _repereVocalDureeS = $v.repereVocalDureeS;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Adresse other) {
    _$v = other as _$Adresse;
  }

  @override
  void update(void Function(AdresseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Adresse build() => _build();

  _$Adresse _build() {
    final _$result = _$v ??
        _$Adresse._(
          aRepereVocal: BuiltValueNullFieldError.checkNotNull(
              aRepereVocal, r'Adresse', 'aRepereVocal'),
          creeLe: BuiltValueNullFieldError.checkNotNull(
              creeLe, r'Adresse', 'creeLe'),
          derniereUtilisationLe: BuiltValueNullFieldError.checkNotNull(
              derniereUtilisationLe, r'Adresse', 'derniereUtilisationLe'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'Adresse', 'id'),
          lat: BuiltValueNullFieldError.checkNotNull(lat, r'Adresse', 'lat'),
          libelle: BuiltValueNullFieldError.checkNotNull(
              libelle, r'Adresse', 'libelle'),
          lng: BuiltValueNullFieldError.checkNotNull(lng, r'Adresse', 'lng'),
          repereTexte: repereTexte,
          repereVocalDureeS: repereVocalDureeS,
          zoneId: BuiltValueNullFieldError.checkNotNull(
              zoneId, r'Adresse', 'zoneId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
