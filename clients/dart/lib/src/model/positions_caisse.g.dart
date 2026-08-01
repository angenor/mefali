// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'positions_caisse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PositionsCaisse extends PositionsCaisse {
  @override
  final int avanceNonRecupereeUnites;
  @override
  final int detenuPourMefaliUnites;
  @override
  final int duParMefaliUnites;

  factory _$PositionsCaisse([void Function(PositionsCaisseBuilder)? updates]) =>
      (PositionsCaisseBuilder()..update(updates))._build();

  _$PositionsCaisse._(
      {required this.avanceNonRecupereeUnites,
      required this.detenuPourMefaliUnites,
      required this.duParMefaliUnites})
      : super._();
  @override
  PositionsCaisse rebuild(void Function(PositionsCaisseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PositionsCaisseBuilder toBuilder() => PositionsCaisseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PositionsCaisse &&
        avanceNonRecupereeUnites == other.avanceNonRecupereeUnites &&
        detenuPourMefaliUnites == other.detenuPourMefaliUnites &&
        duParMefaliUnites == other.duParMefaliUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, avanceNonRecupereeUnites.hashCode);
    _$hash = $jc(_$hash, detenuPourMefaliUnites.hashCode);
    _$hash = $jc(_$hash, duParMefaliUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PositionsCaisse')
          ..add('avanceNonRecupereeUnites', avanceNonRecupereeUnites)
          ..add('detenuPourMefaliUnites', detenuPourMefaliUnites)
          ..add('duParMefaliUnites', duParMefaliUnites))
        .toString();
  }
}

class PositionsCaisseBuilder
    implements Builder<PositionsCaisse, PositionsCaisseBuilder> {
  _$PositionsCaisse? _$v;

  int? _avanceNonRecupereeUnites;
  int? get avanceNonRecupereeUnites => _$this._avanceNonRecupereeUnites;
  set avanceNonRecupereeUnites(int? avanceNonRecupereeUnites) =>
      _$this._avanceNonRecupereeUnites = avanceNonRecupereeUnites;

  int? _detenuPourMefaliUnites;
  int? get detenuPourMefaliUnites => _$this._detenuPourMefaliUnites;
  set detenuPourMefaliUnites(int? detenuPourMefaliUnites) =>
      _$this._detenuPourMefaliUnites = detenuPourMefaliUnites;

  int? _duParMefaliUnites;
  int? get duParMefaliUnites => _$this._duParMefaliUnites;
  set duParMefaliUnites(int? duParMefaliUnites) =>
      _$this._duParMefaliUnites = duParMefaliUnites;

  PositionsCaisseBuilder() {
    PositionsCaisse._defaults(this);
  }

  PositionsCaisseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _avanceNonRecupereeUnites = $v.avanceNonRecupereeUnites;
      _detenuPourMefaliUnites = $v.detenuPourMefaliUnites;
      _duParMefaliUnites = $v.duParMefaliUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PositionsCaisse other) {
    _$v = other as _$PositionsCaisse;
  }

  @override
  void update(void Function(PositionsCaisseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PositionsCaisse build() => _build();

  _$PositionsCaisse _build() {
    final _$result = _$v ??
        _$PositionsCaisse._(
          avanceNonRecupereeUnites: BuiltValueNullFieldError.checkNotNull(
              avanceNonRecupereeUnites,
              r'PositionsCaisse',
              'avanceNonRecupereeUnites'),
          detenuPourMefaliUnites: BuiltValueNullFieldError.checkNotNull(
              detenuPourMefaliUnites,
              r'PositionsCaisse',
              'detenuPourMefaliUnites'),
          duParMefaliUnites: BuiltValueNullFieldError.checkNotNull(
              duParMefaliUnites, r'PositionsCaisse', 'duParMefaliUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
