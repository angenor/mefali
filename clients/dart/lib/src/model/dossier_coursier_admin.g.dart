// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dossier_coursier_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DossierCoursierAdmin extends DossierCoursierAdmin {
  @override
  final String compteId;
  @override
  final String? motif;
  @override
  final String? pieceUrl;
  @override
  final String referentNom;
  @override
  final String referentTelephoneE164;
  @override
  final DateTime soumisLe;
  @override
  final String statut;
  @override
  final String telephoneE164;
  @override
  final BuiltList<VehiculeDeclare> vehicules;

  factory _$DossierCoursierAdmin(
          [void Function(DossierCoursierAdminBuilder)? updates]) =>
      (DossierCoursierAdminBuilder()..update(updates))._build();

  _$DossierCoursierAdmin._(
      {required this.compteId,
      this.motif,
      this.pieceUrl,
      required this.referentNom,
      required this.referentTelephoneE164,
      required this.soumisLe,
      required this.statut,
      required this.telephoneE164,
      required this.vehicules})
      : super._();
  @override
  DossierCoursierAdmin rebuild(
          void Function(DossierCoursierAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DossierCoursierAdminBuilder toBuilder() =>
      DossierCoursierAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DossierCoursierAdmin &&
        compteId == other.compteId &&
        motif == other.motif &&
        pieceUrl == other.pieceUrl &&
        referentNom == other.referentNom &&
        referentTelephoneE164 == other.referentTelephoneE164 &&
        soumisLe == other.soumisLe &&
        statut == other.statut &&
        telephoneE164 == other.telephoneE164 &&
        vehicules == other.vehicules;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compteId.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, pieceUrl.hashCode);
    _$hash = $jc(_$hash, referentNom.hashCode);
    _$hash = $jc(_$hash, referentTelephoneE164.hashCode);
    _$hash = $jc(_$hash, soumisLe.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jc(_$hash, telephoneE164.hashCode);
    _$hash = $jc(_$hash, vehicules.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DossierCoursierAdmin')
          ..add('compteId', compteId)
          ..add('motif', motif)
          ..add('pieceUrl', pieceUrl)
          ..add('referentNom', referentNom)
          ..add('referentTelephoneE164', referentTelephoneE164)
          ..add('soumisLe', soumisLe)
          ..add('statut', statut)
          ..add('telephoneE164', telephoneE164)
          ..add('vehicules', vehicules))
        .toString();
  }
}

class DossierCoursierAdminBuilder
    implements Builder<DossierCoursierAdmin, DossierCoursierAdminBuilder> {
  _$DossierCoursierAdmin? _$v;

  String? _compteId;
  String? get compteId => _$this._compteId;
  set compteId(String? compteId) => _$this._compteId = compteId;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  String? _pieceUrl;
  String? get pieceUrl => _$this._pieceUrl;
  set pieceUrl(String? pieceUrl) => _$this._pieceUrl = pieceUrl;

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

  String? _telephoneE164;
  String? get telephoneE164 => _$this._telephoneE164;
  set telephoneE164(String? telephoneE164) =>
      _$this._telephoneE164 = telephoneE164;

  ListBuilder<VehiculeDeclare>? _vehicules;
  ListBuilder<VehiculeDeclare> get vehicules =>
      _$this._vehicules ??= ListBuilder<VehiculeDeclare>();
  set vehicules(ListBuilder<VehiculeDeclare>? vehicules) =>
      _$this._vehicules = vehicules;

  DossierCoursierAdminBuilder() {
    DossierCoursierAdmin._defaults(this);
  }

  DossierCoursierAdminBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compteId = $v.compteId;
      _motif = $v.motif;
      _pieceUrl = $v.pieceUrl;
      _referentNom = $v.referentNom;
      _referentTelephoneE164 = $v.referentTelephoneE164;
      _soumisLe = $v.soumisLe;
      _statut = $v.statut;
      _telephoneE164 = $v.telephoneE164;
      _vehicules = $v.vehicules.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DossierCoursierAdmin other) {
    _$v = other as _$DossierCoursierAdmin;
  }

  @override
  void update(void Function(DossierCoursierAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DossierCoursierAdmin build() => _build();

  _$DossierCoursierAdmin _build() {
    _$DossierCoursierAdmin _$result;
    try {
      _$result = _$v ??
          _$DossierCoursierAdmin._(
            compteId: BuiltValueNullFieldError.checkNotNull(
                compteId, r'DossierCoursierAdmin', 'compteId'),
            motif: motif,
            pieceUrl: pieceUrl,
            referentNom: BuiltValueNullFieldError.checkNotNull(
                referentNom, r'DossierCoursierAdmin', 'referentNom'),
            referentTelephoneE164: BuiltValueNullFieldError.checkNotNull(
                referentTelephoneE164,
                r'DossierCoursierAdmin',
                'referentTelephoneE164'),
            soumisLe: BuiltValueNullFieldError.checkNotNull(
                soumisLe, r'DossierCoursierAdmin', 'soumisLe'),
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'DossierCoursierAdmin', 'statut'),
            telephoneE164: BuiltValueNullFieldError.checkNotNull(
                telephoneE164, r'DossierCoursierAdmin', 'telephoneE164'),
            vehicules: vehicules.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicules';
        vehicules.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DossierCoursierAdmin', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
