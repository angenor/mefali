// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gain_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GainOffre extends GainOffre {
  @override
  final int arretsUnites;
  @override
  final int deplacementUnites;
  @override
  final String devise;
  @override
  final int effortUnites;
  @override
  final int totalUnites;

  factory _$GainOffre([void Function(GainOffreBuilder)? updates]) =>
      (GainOffreBuilder()..update(updates))._build();

  _$GainOffre._(
      {required this.arretsUnites,
      required this.deplacementUnites,
      required this.devise,
      required this.effortUnites,
      required this.totalUnites})
      : super._();
  @override
  GainOffre rebuild(void Function(GainOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GainOffreBuilder toBuilder() => GainOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GainOffre &&
        arretsUnites == other.arretsUnites &&
        deplacementUnites == other.deplacementUnites &&
        devise == other.devise &&
        effortUnites == other.effortUnites &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretsUnites.hashCode);
    _$hash = $jc(_$hash, deplacementUnites.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, effortUnites.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GainOffre')
          ..add('arretsUnites', arretsUnites)
          ..add('deplacementUnites', deplacementUnites)
          ..add('devise', devise)
          ..add('effortUnites', effortUnites)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class GainOffreBuilder implements Builder<GainOffre, GainOffreBuilder> {
  _$GainOffre? _$v;

  int? _arretsUnites;
  int? get arretsUnites => _$this._arretsUnites;
  set arretsUnites(int? arretsUnites) => _$this._arretsUnites = arretsUnites;

  int? _deplacementUnites;
  int? get deplacementUnites => _$this._deplacementUnites;
  set deplacementUnites(int? deplacementUnites) =>
      _$this._deplacementUnites = deplacementUnites;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _effortUnites;
  int? get effortUnites => _$this._effortUnites;
  set effortUnites(int? effortUnites) => _$this._effortUnites = effortUnites;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  GainOffreBuilder() {
    GainOffre._defaults(this);
  }

  GainOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretsUnites = $v.arretsUnites;
      _deplacementUnites = $v.deplacementUnites;
      _devise = $v.devise;
      _effortUnites = $v.effortUnites;
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GainOffre other) {
    _$v = other as _$GainOffre;
  }

  @override
  void update(void Function(GainOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GainOffre build() => _build();

  _$GainOffre _build() {
    final _$result = _$v ??
        _$GainOffre._(
          arretsUnites: BuiltValueNullFieldError.checkNotNull(
              arretsUnites, r'GainOffre', 'arretsUnites'),
          deplacementUnites: BuiltValueNullFieldError.checkNotNull(
              deplacementUnites, r'GainOffre', 'deplacementUnites'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'GainOffre', 'devise'),
          effortUnites: BuiltValueNullFieldError.checkNotNull(
              effortUnites, r'GainOffre', 'effortUnites'),
          totalUnites: BuiltValueNullFieldError.checkNotNull(
              totalUnites, r'GainOffre', 'totalUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
