// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dossier_coursier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DossierCoursier extends DossierCoursier {
  @override
  final String? motif;
  @override
  final String referentNom;
  @override
  final String referentTelephoneE164;
  @override
  final DateTime soumisLe;
  @override
  final String statut;
  @override
  final BuiltList<VehiculeDeclare> vehicules;

  factory _$DossierCoursier([void Function(DossierCoursierBuilder)? updates]) =>
      (DossierCoursierBuilder()..update(updates))._build();

  _$DossierCoursier._(
      {this.motif,
      required this.referentNom,
      required this.referentTelephoneE164,
      required this.soumisLe,
      required this.statut,
      required this.vehicules})
      : super._();
  @override
  DossierCoursier rebuild(void Function(DossierCoursierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DossierCoursierBuilder toBuilder() => DossierCoursierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DossierCoursier &&
        motif == other.motif &&
        referentNom == other.referentNom &&
        referentTelephoneE164 == other.referentTelephoneE164 &&
        soumisLe == other.soumisLe &&
        statut == other.statut &&
        vehicules == other.vehicules;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, referentNom.hashCode);
    _$hash = $jc(_$hash, referentTelephoneE164.hashCode);
    _$hash = $jc(_$hash, soumisLe.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jc(_$hash, vehicules.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DossierCoursier')
          ..add('motif', motif)
          ..add('referentNom', referentNom)
          ..add('referentTelephoneE164', referentTelephoneE164)
          ..add('soumisLe', soumisLe)
          ..add('statut', statut)
          ..add('vehicules', vehicules))
        .toString();
  }
}

class DossierCoursierBuilder
    implements Builder<DossierCoursier, DossierCoursierBuilder> {
  _$DossierCoursier? _$v;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  String? _referentNom;
  String? get referentNom => _$this._referentNom;
  set referentNom(String? referentNom) => _$this._referentNom = referentNom;

  String? _referentTelephoneE164;
  String? get referentTelephoneE164 => _$this._referentTelephoneE164;
  set referentTelephoneE164(String? referentTelephoneE164) =>
      _$this._referentTelephoneE164 = referentTelephoneE164;

  DateTime? _soumisLe;
  DateTime? get soumisLe => _$this._soumisLe;
  set soumisLe(DateTime? soumisLe) => _$this._soumisLe = soumisLe;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  ListBuilder<VehiculeDeclare>? _vehicules;
  ListBuilder<VehiculeDeclare> get vehicules =>
      _$this._vehicules ??= ListBuilder<VehiculeDeclare>();
  set vehicules(ListBuilder<VehiculeDeclare>? vehicules) =>
      _$this._vehicules = vehicules;

  DossierCoursierBuilder() {
    DossierCoursier._defaults(this);
  }

  DossierCoursierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motif = $v.motif;
      _referentNom = $v.referentNom;
      _referentTelephoneE164 = $v.referentTelephoneE164;
      _soumisLe = $v.soumisLe;
      _statut = $v.statut;
      _vehicules = $v.vehicules.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DossierCoursier other) {
    _$v = other as _$DossierCoursier;
  }

  @override
  void update(void Function(DossierCoursierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DossierCoursier build() => _build();

  _$DossierCoursier _build() {
    _$DossierCoursier _$result;
    try {
      _$result = _$v ??
          _$DossierCoursier._(
            motif: motif,
            referentNom: BuiltValueNullFieldError.checkNotNull(
                referentNom, r'DossierCoursier', 'referentNom'),
            referentTelephoneE164: BuiltValueNullFieldError.checkNotNull(
                referentTelephoneE164,
                r'DossierCoursier',
                'referentTelephoneE164'),
            soumisLe: BuiltValueNullFieldError.checkNotNull(
                soumisLe, r'DossierCoursier', 'soumisLe'),
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'DossierCoursier', 'statut'),
            vehicules: vehicules.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicules';
        vehicules.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DossierCoursier', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
