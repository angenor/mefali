// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arret_course.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArretCourse extends ArretCourse {
  @override
  final String arretId;
  @override
  final DateTime? arriveLe;
  @override
  final DateTime? collecteLe;
  @override
  final int distanceMaxM;
  @override
  final int? distancePrecedentM;
  @override
  final String empreinteCode;
  @override
  final String empreinteJeton;
  @override
  final DateTime? enRouteLe;
  @override
  final BuiltList<LigneArret> lignes;
  @override
  final int montantAvance;
  @override
  final String nom;
  @override
  final int ordre;
  @override
  final bool photoExigee;
  @override
  final String prestataireId;
  @override
  final double siteLat;
  @override
  final double siteLon;
  @override
  final String statut;
  @override
  final String? telephoneVendeur;

  factory _$ArretCourse([void Function(ArretCourseBuilder)? updates]) =>
      (ArretCourseBuilder()..update(updates))._build();

  _$ArretCourse._(
      {required this.arretId,
      this.arriveLe,
      this.collecteLe,
      required this.distanceMaxM,
      this.distancePrecedentM,
      required this.empreinteCode,
      required this.empreinteJeton,
      this.enRouteLe,
      required this.lignes,
      required this.montantAvance,
      required this.nom,
      required this.ordre,
      required this.photoExigee,
      required this.prestataireId,
      required this.siteLat,
      required this.siteLon,
      required this.statut,
      this.telephoneVendeur})
      : super._();
  @override
  ArretCourse rebuild(void Function(ArretCourseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArretCourseBuilder toBuilder() => ArretCourseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArretCourse &&
        arretId == other.arretId &&
        arriveLe == other.arriveLe &&
        collecteLe == other.collecteLe &&
        distanceMaxM == other.distanceMaxM &&
        distancePrecedentM == other.distancePrecedentM &&
        empreinteCode == other.empreinteCode &&
        empreinteJeton == other.empreinteJeton &&
        enRouteLe == other.enRouteLe &&
        lignes == other.lignes &&
        montantAvance == other.montantAvance &&
        nom == other.nom &&
        ordre == other.ordre &&
        photoExigee == other.photoExigee &&
        prestataireId == other.prestataireId &&
        siteLat == other.siteLat &&
        siteLon == other.siteLon &&
        statut == other.statut &&
        telephoneVendeur == other.telephoneVendeur;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, arriveLe.hashCode);
    _$hash = $jc(_$hash, collecteLe.hashCode);
    _$hash = $jc(_$hash, distanceMaxM.hashCode);
    _$hash = $jc(_$hash, distancePrecedentM.hashCode);
    _$hash = $jc(_$hash, empreinteCode.hashCode);
    _$hash = $jc(_$hash, empreinteJeton.hashCode);
    _$hash = $jc(_$hash, enRouteLe.hashCode);
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, montantAvance.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, ordre.hashCode);
    _$hash = $jc(_$hash, photoExigee.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, siteLat.hashCode);
    _$hash = $jc(_$hash, siteLon.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jc(_$hash, telephoneVendeur.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArretCourse')
          ..add('arretId', arretId)
          ..add('arriveLe', arriveLe)
          ..add('collecteLe', collecteLe)
          ..add('distanceMaxM', distanceMaxM)
          ..add('distancePrecedentM', distancePrecedentM)
          ..add('empreinteCode', empreinteCode)
          ..add('empreinteJeton', empreinteJeton)
          ..add('enRouteLe', enRouteLe)
          ..add('lignes', lignes)
          ..add('montantAvance', montantAvance)
          ..add('nom', nom)
          ..add('ordre', ordre)
          ..add('photoExigee', photoExigee)
          ..add('prestataireId', prestataireId)
          ..add('siteLat', siteLat)
          ..add('siteLon', siteLon)
          ..add('statut', statut)
          ..add('telephoneVendeur', telephoneVendeur))
        .toString();
  }
}

class ArretCourseBuilder implements Builder<ArretCourse, ArretCourseBuilder> {
  _$ArretCourse? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  DateTime? _arriveLe;
  DateTime? get arriveLe => _$this._arriveLe;
  set arriveLe(DateTime? arriveLe) => _$this._arriveLe = arriveLe;

  DateTime? _collecteLe;
  DateTime? get collecteLe => _$this._collecteLe;
  set collecteLe(DateTime? collecteLe) => _$this._collecteLe = collecteLe;

  int? _distanceMaxM;
  int? get distanceMaxM => _$this._distanceMaxM;
  set distanceMaxM(int? distanceMaxM) => _$this._distanceMaxM = distanceMaxM;

  int? _distancePrecedentM;
  int? get distancePrecedentM => _$this._distancePrecedentM;
  set distancePrecedentM(int? distancePrecedentM) =>
      _$this._distancePrecedentM = distancePrecedentM;

  String? _empreinteCode;
  String? get empreinteCode => _$this._empreinteCode;
  set empreinteCode(String? empreinteCode) =>
      _$this._empreinteCode = empreinteCode;

  String? _empreinteJeton;
  String? get empreinteJeton => _$this._empreinteJeton;
  set empreinteJeton(String? empreinteJeton) =>
      _$this._empreinteJeton = empreinteJeton;

  DateTime? _enRouteLe;
  DateTime? get enRouteLe => _$this._enRouteLe;
  set enRouteLe(DateTime? enRouteLe) => _$this._enRouteLe = enRouteLe;

  ListBuilder<LigneArret>? _lignes;
  ListBuilder<LigneArret> get lignes =>
      _$this._lignes ??= ListBuilder<LigneArret>();
  set lignes(ListBuilder<LigneArret>? lignes) => _$this._lignes = lignes;

  int? _montantAvance;
  int? get montantAvance => _$this._montantAvance;
  set montantAvance(int? montantAvance) =>
      _$this._montantAvance = montantAvance;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  int? _ordre;
  int? get ordre => _$this._ordre;
  set ordre(int? ordre) => _$this._ordre = ordre;

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

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  String? _telephoneVendeur;
  String? get telephoneVendeur => _$this._telephoneVendeur;
  set telephoneVendeur(String? telephoneVendeur) =>
      _$this._telephoneVendeur = telephoneVendeur;

  ArretCourseBuilder() {
    ArretCourse._defaults(this);
  }

  ArretCourseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _arriveLe = $v.arriveLe;
      _collecteLe = $v.collecteLe;
      _distanceMaxM = $v.distanceMaxM;
      _distancePrecedentM = $v.distancePrecedentM;
      _empreinteCode = $v.empreinteCode;
      _empreinteJeton = $v.empreinteJeton;
      _enRouteLe = $v.enRouteLe;
      _lignes = $v.lignes.toBuilder();
      _montantAvance = $v.montantAvance;
      _nom = $v.nom;
      _ordre = $v.ordre;
      _photoExigee = $v.photoExigee;
      _prestataireId = $v.prestataireId;
      _siteLat = $v.siteLat;
      _siteLon = $v.siteLon;
      _statut = $v.statut;
      _telephoneVendeur = $v.telephoneVendeur;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArretCourse other) {
    _$v = other as _$ArretCourse;
  }

  @override
  void update(void Function(ArretCourseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArretCourse build() => _build();

  _$ArretCourse _build() {
    _$ArretCourse _$result;
    try {
      _$result = _$v ??
          _$ArretCourse._(
            arretId: BuiltValueNullFieldError.checkNotNull(
                arretId, r'ArretCourse', 'arretId'),
            arriveLe: arriveLe,
            collecteLe: collecteLe,
            distanceMaxM: BuiltValueNullFieldError.checkNotNull(
                distanceMaxM, r'ArretCourse', 'distanceMaxM'),
            distancePrecedentM: distancePrecedentM,
            empreinteCode: BuiltValueNullFieldError.checkNotNull(
                empreinteCode, r'ArretCourse', 'empreinteCode'),
            empreinteJeton: BuiltValueNullFieldError.checkNotNull(
                empreinteJeton, r'ArretCourse', 'empreinteJeton'),
            enRouteLe: enRouteLe,
            lignes: lignes.build(),
            montantAvance: BuiltValueNullFieldError.checkNotNull(
                montantAvance, r'ArretCourse', 'montantAvance'),
            nom: BuiltValueNullFieldError.checkNotNull(
                nom, r'ArretCourse', 'nom'),
            ordre: BuiltValueNullFieldError.checkNotNull(
                ordre, r'ArretCourse', 'ordre'),
            photoExigee: BuiltValueNullFieldError.checkNotNull(
                photoExigee, r'ArretCourse', 'photoExigee'),
            prestataireId: BuiltValueNullFieldError.checkNotNull(
                prestataireId, r'ArretCourse', 'prestataireId'),
            siteLat: BuiltValueNullFieldError.checkNotNull(
                siteLat, r'ArretCourse', 'siteLat'),
            siteLon: BuiltValueNullFieldError.checkNotNull(
                siteLon, r'ArretCourse', 'siteLon'),
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'ArretCourse', 'statut'),
            telephoneVendeur: telephoneVendeur,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ArretCourse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
