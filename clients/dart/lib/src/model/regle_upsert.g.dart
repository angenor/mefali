// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regle_upsert.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegleUpsert extends RegleUpsert {
  @override
  final bool actif;
  @override
  final String? categorieSlug;
  @override
  final String devise;
  @override
  final int? distanceMaxM;
  @override
  final int distanceMinM;
  @override
  final int? joursMasque;
  @override
  final int marge;
  @override
  final int partCoursierBase;
  @override
  final int? plageDebutMin;
  @override
  final int? plageFinMin;
  @override
  final int priorite;
  @override
  final int prixParKm;
  @override
  final int? prixPlafond;
  @override
  final int seuilKmM;
  @override
  final String transportSlug;

  factory _$RegleUpsert([void Function(RegleUpsertBuilder)? updates]) =>
      (RegleUpsertBuilder()..update(updates))._build();

  _$RegleUpsert._(
      {required this.actif,
      this.categorieSlug,
      required this.devise,
      this.distanceMaxM,
      required this.distanceMinM,
      this.joursMasque,
      required this.marge,
      required this.partCoursierBase,
      this.plageDebutMin,
      this.plageFinMin,
      required this.priorite,
      required this.prixParKm,
      this.prixPlafond,
      required this.seuilKmM,
      required this.transportSlug})
      : super._();
  @override
  RegleUpsert rebuild(void Function(RegleUpsertBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegleUpsertBuilder toBuilder() => RegleUpsertBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegleUpsert &&
        actif == other.actif &&
        categorieSlug == other.categorieSlug &&
        devise == other.devise &&
        distanceMaxM == other.distanceMaxM &&
        distanceMinM == other.distanceMinM &&
        joursMasque == other.joursMasque &&
        marge == other.marge &&
        partCoursierBase == other.partCoursierBase &&
        plageDebutMin == other.plageDebutMin &&
        plageFinMin == other.plageFinMin &&
        priorite == other.priorite &&
        prixParKm == other.prixParKm &&
        prixPlafond == other.prixPlafond &&
        seuilKmM == other.seuilKmM &&
        transportSlug == other.transportSlug;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actif.hashCode);
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, distanceMaxM.hashCode);
    _$hash = $jc(_$hash, distanceMinM.hashCode);
    _$hash = $jc(_$hash, joursMasque.hashCode);
    _$hash = $jc(_$hash, marge.hashCode);
    _$hash = $jc(_$hash, partCoursierBase.hashCode);
    _$hash = $jc(_$hash, plageDebutMin.hashCode);
    _$hash = $jc(_$hash, plageFinMin.hashCode);
    _$hash = $jc(_$hash, priorite.hashCode);
    _$hash = $jc(_$hash, prixParKm.hashCode);
    _$hash = $jc(_$hash, prixPlafond.hashCode);
    _$hash = $jc(_$hash, seuilKmM.hashCode);
    _$hash = $jc(_$hash, transportSlug.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegleUpsert')
          ..add('actif', actif)
          ..add('categorieSlug', categorieSlug)
          ..add('devise', devise)
          ..add('distanceMaxM', distanceMaxM)
          ..add('distanceMinM', distanceMinM)
          ..add('joursMasque', joursMasque)
          ..add('marge', marge)
          ..add('partCoursierBase', partCoursierBase)
          ..add('plageDebutMin', plageDebutMin)
          ..add('plageFinMin', plageFinMin)
          ..add('priorite', priorite)
          ..add('prixParKm', prixParKm)
          ..add('prixPlafond', prixPlafond)
          ..add('seuilKmM', seuilKmM)
          ..add('transportSlug', transportSlug))
        .toString();
  }
}

class RegleUpsertBuilder implements Builder<RegleUpsert, RegleUpsertBuilder> {
  _$RegleUpsert? _$v;

  bool? _actif;
  bool? get actif => _$this._actif;
  set actif(bool? actif) => _$this._actif = actif;

  String? _categorieSlug;
  String? get categorieSlug => _$this._categorieSlug;
  set categorieSlug(String? categorieSlug) =>
      _$this._categorieSlug = categorieSlug;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _distanceMaxM;
  int? get distanceMaxM => _$this._distanceMaxM;
  set distanceMaxM(int? distanceMaxM) => _$this._distanceMaxM = distanceMaxM;

  int? _distanceMinM;
  int? get distanceMinM => _$this._distanceMinM;
  set distanceMinM(int? distanceMinM) => _$this._distanceMinM = distanceMinM;

  int? _joursMasque;
  int? get joursMasque => _$this._joursMasque;
  set joursMasque(int? joursMasque) => _$this._joursMasque = joursMasque;

  int? _marge;
  int? get marge => _$this._marge;
  set marge(int? marge) => _$this._marge = marge;

  int? _partCoursierBase;
  int? get partCoursierBase => _$this._partCoursierBase;
  set partCoursierBase(int? partCoursierBase) =>
      _$this._partCoursierBase = partCoursierBase;

  int? _plageDebutMin;
  int? get plageDebutMin => _$this._plageDebutMin;
  set plageDebutMin(int? plageDebutMin) =>
      _$this._plageDebutMin = plageDebutMin;

  int? _plageFinMin;
  int? get plageFinMin => _$this._plageFinMin;
  set plageFinMin(int? plageFinMin) => _$this._plageFinMin = plageFinMin;

  int? _priorite;
  int? get priorite => _$this._priorite;
  set priorite(int? priorite) => _$this._priorite = priorite;

  int? _prixParKm;
  int? get prixParKm => _$this._prixParKm;
  set prixParKm(int? prixParKm) => _$this._prixParKm = prixParKm;

  int? _prixPlafond;
  int? get prixPlafond => _$this._prixPlafond;
  set prixPlafond(int? prixPlafond) => _$this._prixPlafond = prixPlafond;

  int? _seuilKmM;
  int? get seuilKmM => _$this._seuilKmM;
  set seuilKmM(int? seuilKmM) => _$this._seuilKmM = seuilKmM;

  String? _transportSlug;
  String? get transportSlug => _$this._transportSlug;
  set transportSlug(String? transportSlug) =>
      _$this._transportSlug = transportSlug;

  RegleUpsertBuilder() {
    RegleUpsert._defaults(this);
  }

  RegleUpsertBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actif = $v.actif;
      _categorieSlug = $v.categorieSlug;
      _devise = $v.devise;
      _distanceMaxM = $v.distanceMaxM;
      _distanceMinM = $v.distanceMinM;
      _joursMasque = $v.joursMasque;
      _marge = $v.marge;
      _partCoursierBase = $v.partCoursierBase;
      _plageDebutMin = $v.plageDebutMin;
      _plageFinMin = $v.plageFinMin;
      _priorite = $v.priorite;
      _prixParKm = $v.prixParKm;
      _prixPlafond = $v.prixPlafond;
      _seuilKmM = $v.seuilKmM;
      _transportSlug = $v.transportSlug;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegleUpsert other) {
    _$v = other as _$RegleUpsert;
  }

  @override
  void update(void Function(RegleUpsertBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegleUpsert build() => _build();

  _$RegleUpsert _build() {
    final _$result = _$v ??
        _$RegleUpsert._(
          actif: BuiltValueNullFieldError.checkNotNull(
              actif, r'RegleUpsert', 'actif'),
          categorieSlug: categorieSlug,
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'RegleUpsert', 'devise'),
          distanceMaxM: distanceMaxM,
          distanceMinM: BuiltValueNullFieldError.checkNotNull(
              distanceMinM, r'RegleUpsert', 'distanceMinM'),
          joursMasque: joursMasque,
          marge: BuiltValueNullFieldError.checkNotNull(
              marge, r'RegleUpsert', 'marge'),
          partCoursierBase: BuiltValueNullFieldError.checkNotNull(
              partCoursierBase, r'RegleUpsert', 'partCoursierBase'),
          plageDebutMin: plageDebutMin,
          plageFinMin: plageFinMin,
          priorite: BuiltValueNullFieldError.checkNotNull(
              priorite, r'RegleUpsert', 'priorite'),
          prixParKm: BuiltValueNullFieldError.checkNotNull(
              prixParKm, r'RegleUpsert', 'prixParKm'),
          prixPlafond: prixPlafond,
          seuilKmM: BuiltValueNullFieldError.checkNotNull(
              seuilKmM, r'RegleUpsert', 'seuilKmM'),
          transportSlug: BuiltValueNullFieldError.checkNotNull(
              transportSlug, r'RegleUpsert', 'transportSlug'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
