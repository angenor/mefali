// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exposition_cash.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ExpositionCash extends ExpositionCash {
  @override
  final DateTime au;
  @override
  final String devise;
  @override
  final BuiltList<LigneExposition> parCoursier;
  @override
  final int totalUnites;

  factory _$ExpositionCash([void Function(ExpositionCashBuilder)? updates]) =>
      (ExpositionCashBuilder()..update(updates))._build();

  _$ExpositionCash._(
      {required this.au,
      required this.devise,
      required this.parCoursier,
      required this.totalUnites})
      : super._();
  @override
  ExpositionCash rebuild(void Function(ExpositionCashBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ExpositionCashBuilder toBuilder() => ExpositionCashBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ExpositionCash &&
        au == other.au &&
        devise == other.devise &&
        parCoursier == other.parCoursier &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, au.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, parCoursier.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ExpositionCash')
          ..add('au', au)
          ..add('devise', devise)
          ..add('parCoursier', parCoursier)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class ExpositionCashBuilder
    implements Builder<ExpositionCash, ExpositionCashBuilder> {
  _$ExpositionCash? _$v;

  DateTime? _au;
  DateTime? get au => _$this._au;
  set au(DateTime? au) => _$this._au = au;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  ListBuilder<LigneExposition>? _parCoursier;
  ListBuilder<LigneExposition> get parCoursier =>
      _$this._parCoursier ??= ListBuilder<LigneExposition>();
  set parCoursier(ListBuilder<LigneExposition>? parCoursier) =>
      _$this._parCoursier = parCoursier;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  ExpositionCashBuilder() {
    ExpositionCash._defaults(this);
  }

  ExpositionCashBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _au = $v.au;
      _devise = $v.devise;
      _parCoursier = $v.parCoursier.toBuilder();
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ExpositionCash other) {
    _$v = other as _$ExpositionCash;
  }

  @override
  void update(void Function(ExpositionCashBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ExpositionCash build() => _build();

  _$ExpositionCash _build() {
    _$ExpositionCash _$result;
    try {
      _$result = _$v ??
          _$ExpositionCash._(
            au: BuiltValueNullFieldError.checkNotNull(
                au, r'ExpositionCash', 'au'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'ExpositionCash', 'devise'),
            parCoursier: parCoursier.build(),
            totalUnites: BuiltValueNullFieldError.checkNotNull(
                totalUnites, r'ExpositionCash', 'totalUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'parCoursier';
        parCoursier.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ExpositionCash', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
