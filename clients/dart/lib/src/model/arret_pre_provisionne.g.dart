// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arret_pre_provisionne.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArretPreProvisionne extends ArretPreProvisionne {
  @override
  final String arretId;
  @override
  final String devise;
  @override
  final int distanceMaxM;
  @override
  final String empreinteCode;
  @override
  final String empreinteJeton;
  @override
  final int montantAvance;
  @override
  final String nom;
  @override
  final bool photoExigee;
  @override
  final String prestataireId;
  @override
  final double siteLat;
  @override
  final double siteLon;

  factory _$ArretPreProvisionne(
          [void Function(ArretPreProvisionneBuilder)? updates]) =>
      (ArretPreProvisionneBuilder()..update(updates))._build();

  _$ArretPreProvisionne._(
      {required this.arretId,
      required this.devise,
      required this.distanceMaxM,
      required this.empreinteCode,
      required this.empreinteJeton,
      required this.montantAvance,
      required this.nom,
      required this.photoExigee,
      required this.prestataireId,
      required this.siteLat,
      required this.siteLon})
      : super._();
  @override
  ArretPreProvisionne rebuild(
          void Function(ArretPreProvisionneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArretPreProvisionneBuilder toBuilder() =>
      ArretPreProvisionneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArretPreProvisionne &&
        arretId == other.arretId &&
        devise == other.devise &&
        distanceMaxM == other.distanceMaxM &&
        empreinteCode == other.empreinteCode &&
        empreinteJeton == other.empreinteJeton &&
        montantAvance == other.montantAvance &&
        nom == other.nom &&
        photoExigee == other.photoExigee &&
        prestataireId == other.prestataireId &&
        siteLat == other.siteLat &&
        siteLon == other.siteLon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, distanceMaxM.hashCode);
    _$hash = $jc(_$hash, empreinteCode.hashCode);
    _$hash = $jc(_$hash, empreinteJeton.hashCode);
    _$hash = $jc(_$hash, montantAvance.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, photoExigee.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, siteLat.hashCode);
    _$hash = $jc(_$hash, siteLon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArretPreProvisionne')
          ..add('arretId', arretId)
          ..add('devise', devise)
          ..add('distanceMaxM', distanceMaxM)
          ..add('empreinteCode', empreinteCode)
          ..add('empreinteJeton', empreinteJeton)
          ..add('montantAvance', montantAvance)
          ..add('nom', nom)
          ..add('photoExigee', photoExigee)
          ..add('prestataireId', prestataireId)
          ..add('siteLat', siteLat)
          ..add('siteLon', siteLon))
        .toString();
  }
}

class ArretPreProvisionneBuilder
    implements Builder<ArretPreProvisionne, ArretPreProvisionneBuilder> {
  _$ArretPreProvisionne? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _distanceMaxM;
  int? get distanceMaxM => _$this._distanceMaxM;
  set distanceMaxM(int? distanceMaxM) => _$this._distanceMaxM = distanceMaxM;

  String? _empreinteCode;
  String? get empreinteCode => _$this._empreinteCode;
  set empreinteCode(String? empreinteCode) =>
      _$this._empreinteCode = empreinteCode;

  String? _empreinteJeton;
  String? get empreinteJeton => _$this._empreinteJeton;
  set empreinteJeton(String? empreinteJeton) =>
      _$this._empreinteJeton = empreinteJeton;

  int? _montantAvance;
  int? get montantAvance => _$this._montantAvance;
  set montantAvance(int? montantAvance) =>
      _$this._montantAvance = montantAvance;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  bool? _photoExigee;
  bool? get photoExigee => _$this._photoExigee;
  set photoExigee(bool? photoExigee) => _$this._photoExigee = photoExigee;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  double? _siteLat;
  double? get siteLat => _$this._siteLat;
  set siteLat(double? siteLat) => _$this._siteLat = siteLat;

  double? _siteLon;
  double? get siteLon => _$this._siteLon;
  set siteLon(double? siteLon) => _$this._siteLon = siteLon;

  ArretPreProvisionneBuilder() {
    ArretPreProvisionne._defaults(this);
  }

  ArretPreProvisionneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _devise = $v.devise;
      _distanceMaxM = $v.distanceMaxM;
      _empreinteCode = $v.empreinteCode;
      _empreinteJeton = $v.empreinteJeton;
      _montantAvance = $v.montantAvance;
      _nom = $v.nom;
      _photoExigee = $v.photoExigee;
      _prestataireId = $v.prestataireId;
      _siteLat = $v.siteLat;
      _siteLon = $v.siteLon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArretPreProvisionne other) {
    _$v = other as _$ArretPreProvisionne;
  }

  @override
  void update(void Function(ArretPreProvisionneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArretPreProvisionne build() => _build();

  _$ArretPreProvisionne _build() {
    final _$result = _$v ??
        _$ArretPreProvisionne._(
          arretId: BuiltValueNullFieldError.checkNotNull(
              arretId, r'ArretPreProvisionne', 'arretId'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'ArretPreProvisionne', 'devise'),
          distanceMaxM: BuiltValueNullFieldError.checkNotNull(
              distanceMaxM, r'ArretPreProvisionne', 'distanceMaxM'),
          empreinteCode: BuiltValueNullFieldError.checkNotNull(
              empreinteCode, r'ArretPreProvisionne', 'empreinteCode'),
          empreinteJeton: BuiltValueNullFieldError.checkNotNull(
              empreinteJeton, r'ArretPreProvisionne', 'empreinteJeton'),
          montantAvance: BuiltValueNullFieldError.checkNotNull(
              montantAvance, r'ArretPreProvisionne', 'montantAvance'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'ArretPreProvisionne', 'nom'),
          photoExigee: BuiltValueNullFieldError.checkNotNull(
              photoExigee, r'ArretPreProvisionne', 'photoExigee'),
          prestataireId: BuiltValueNullFieldError.checkNotNull(
              prestataireId, r'ArretPreProvisionne', 'prestataireId'),
          siteLat: BuiltValueNullFieldError.checkNotNull(
              siteLat, r'ArretPreProvisionne', 'siteLat'),
          siteLon: BuiltValueNullFieldError.checkNotNull(
              siteLon, r'ArretPreProvisionne', 'siteLon'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
