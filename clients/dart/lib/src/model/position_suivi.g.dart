// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'position_suivi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PositionSuivi extends PositionSuivi {
  @override
  final int ageS;
  @override
  final double lat;
  @override
  final double lon;

  factory _$PositionSuivi([void Function(PositionSuiviBuilder)? updates]) =>
      (PositionSuiviBuilder()..update(updates))._build();

  _$PositionSuivi._({required this.ageS, required this.lat, required this.lon})
      : super._();
  @override
  PositionSuivi rebuild(void Function(PositionSuiviBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PositionSuiviBuilder toBuilder() => PositionSuiviBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PositionSuivi &&
        ageS == other.ageS &&
        lat == other.lat &&
        lon == other.lon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ageS.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PositionSuivi')
          ..add('ageS', ageS)
          ..add('lat', lat)
          ..add('lon', lon))
        .toString();
  }
}

class PositionSuiviBuilder
    implements Builder<PositionSuivi, PositionSuiviBuilder> {
  _$PositionSuivi? _$v;

  int? _ageS;
  int? get ageS => _$this._ageS;
  set ageS(int? ageS) => _$this._ageS = ageS;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  PositionSuiviBuilder() {
    PositionSuivi._defaults(this);
  }

  PositionSuiviBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ageS = $v.ageS;
      _lat = $v.lat;
      _lon = $v.lon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PositionSuivi other) {
    _$v = other as _$PositionSuivi;
  }

  @override
  void update(void Function(PositionSuiviBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PositionSuivi build() => _build();

  _$PositionSuivi _build() {
    final _$result = _$v ??
        _$PositionSuivi._(
          ageS: BuiltValueNullFieldError.checkNotNull(
              ageS, r'PositionSuivi', 'ageS'),
          lat: BuiltValueNullFieldError.checkNotNull(
              lat, r'PositionSuivi', 'lat'),
          lon: BuiltValueNullFieldError.checkNotNull(
              lon, r'PositionSuivi', 'lon'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
