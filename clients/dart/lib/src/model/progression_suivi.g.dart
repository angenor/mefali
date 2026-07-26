// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'progression_suivi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ProgressionSuivi extends ProgressionSuivi {
  @override
  final ArretCourantSuivi? arretCourant;
  @override
  final int collectesFaites;
  @override
  final int collectesTotal;

  factory _$ProgressionSuivi(
          [void Function(ProgressionSuiviBuilder)? updates]) =>
      (ProgressionSuiviBuilder()..update(updates))._build();

  _$ProgressionSuivi._(
      {this.arretCourant,
      required this.collectesFaites,
      required this.collectesTotal})
      : super._();
  @override
  ProgressionSuivi rebuild(void Function(ProgressionSuiviBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ProgressionSuiviBuilder toBuilder() =>
      ProgressionSuiviBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ProgressionSuivi &&
        arretCourant == other.arretCourant &&
        collectesFaites == other.collectesFaites &&
        collectesTotal == other.collectesTotal;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretCourant.hashCode);
    _$hash = $jc(_$hash, collectesFaites.hashCode);
    _$hash = $jc(_$hash, collectesTotal.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ProgressionSuivi')
          ..add('arretCourant', arretCourant)
          ..add('collectesFaites', collectesFaites)
          ..add('collectesTotal', collectesTotal))
        .toString();
  }
}

class ProgressionSuiviBuilder
    implements Builder<ProgressionSuivi, ProgressionSuiviBuilder> {
  _$ProgressionSuivi? _$v;

  ArretCourantSuiviBuilder? _arretCourant;
  ArretCourantSuiviBuilder get arretCourant =>
      _$this._arretCourant ??= ArretCourantSuiviBuilder();
  set arretCourant(ArretCourantSuiviBuilder? arretCourant) =>
      _$this._arretCourant = arretCourant;

  int? _collectesFaites;
  int? get collectesFaites => _$this._collectesFaites;
  set collectesFaites(int? collectesFaites) =>
      _$this._collectesFaites = collectesFaites;

  int? _collectesTotal;
  int? get collectesTotal => _$this._collectesTotal;
  set collectesTotal(int? collectesTotal) =>
      _$this._collectesTotal = collectesTotal;

  ProgressionSuiviBuilder() {
    ProgressionSuivi._defaults(this);
  }

  ProgressionSuiviBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretCourant = $v.arretCourant?.toBuilder();
      _collectesFaites = $v.collectesFaites;
      _collectesTotal = $v.collectesTotal;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ProgressionSuivi other) {
    _$v = other as _$ProgressionSuivi;
  }

  @override
  void update(void Function(ProgressionSuiviBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ProgressionSuivi build() => _build();

  _$ProgressionSuivi _build() {
    _$ProgressionSuivi _$result;
    try {
      _$result = _$v ??
          _$ProgressionSuivi._(
            arretCourant: _arretCourant?.build(),
            collectesFaites: BuiltValueNullFieldError.checkNotNull(
                collectesFaites, r'ProgressionSuivi', 'collectesFaites'),
            collectesTotal: BuiltValueNullFieldError.checkNotNull(
                collectesTotal, r'ProgressionSuivi', 'collectesTotal'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'arretCourant';
        _arretCourant?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ProgressionSuivi', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
