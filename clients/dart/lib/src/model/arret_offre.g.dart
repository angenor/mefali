// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arret_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArretOffre extends ArretOffre {
  @override
  final int distanceM;
  @override
  final String nom;
  @override
  final int ordre;
  @override
  final String? prestataireId;

  factory _$ArretOffre([void Function(ArretOffreBuilder)? updates]) =>
      (ArretOffreBuilder()..update(updates))._build();

  _$ArretOffre._(
      {required this.distanceM,
      required this.nom,
      required this.ordre,
      this.prestataireId})
      : super._();
  @override
  ArretOffre rebuild(void Function(ArretOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArretOffreBuilder toBuilder() => ArretOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArretOffre &&
        distanceM == other.distanceM &&
        nom == other.nom &&
        ordre == other.ordre &&
        prestataireId == other.prestataireId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, ordre.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArretOffre')
          ..add('distanceM', distanceM)
          ..add('nom', nom)
          ..add('ordre', ordre)
          ..add('prestataireId', prestataireId))
        .toString();
  }
}

class ArretOffreBuilder implements Builder<ArretOffre, ArretOffreBuilder> {
  _$ArretOffre? _$v;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  int? _ordre;
  int? get ordre => _$this._ordre;
  set ordre(int? ordre) => _$this._ordre = ordre;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  ArretOffreBuilder() {
    ArretOffre._defaults(this);
  }

  ArretOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _distanceM = $v.distanceM;
      _nom = $v.nom;
      _ordre = $v.ordre;
      _prestataireId = $v.prestataireId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArretOffre other) {
    _$v = other as _$ArretOffre;
  }

  @override
  void update(void Function(ArretOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArretOffre build() => _build();

  _$ArretOffre _build() {
    final _$result = _$v ??
        _$ArretOffre._(
          distanceM: BuiltValueNullFieldError.checkNotNull(
              distanceM, r'ArretOffre', 'distanceM'),
          nom: BuiltValueNullFieldError.checkNotNull(nom, r'ArretOffre', 'nom'),
          ordre: BuiltValueNullFieldError.checkNotNull(
              ordre, r'ArretOffre', 'ordre'),
          prestataireId: prestataireId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
