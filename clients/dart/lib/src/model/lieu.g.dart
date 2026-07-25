// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lieu.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Lieu extends Lieu {
  @override
  final double lat;
  @override
  final double lon;

  factory _$Lieu([void Function(LieuBuilder)? updates]) =>
      (LieuBuilder()..update(updates))._build();

  _$Lieu._({required this.lat, required this.lon}) : super._();
  @override
  Lieu rebuild(void Function(LieuBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LieuBuilder toBuilder() => LieuBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Lieu && lat == other.lat && lon == other.lon;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Lieu')
          ..add('lat', lat)
          ..add('lon', lon))
        .toString();
  }
}

class LieuBuilder implements Builder<Lieu, LieuBuilder> {
  _$Lieu? _$v;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  LieuBuilder() {
    Lieu._defaults(this);
  }

  LieuBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lat = $v.lat;
      _lon = $v.lon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Lieu other) {
    _$v = other as _$Lieu;
  }

  @override
  void update(void Function(LieuBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Lieu build() => _build();

  _$Lieu _build() {
    final _$result = _$v ??
        _$Lieu._(
          lat: BuiltValueNullFieldError.checkNotNull(lat, r'Lieu', 'lat'),
          lon: BuiltValueNullFieldError.checkNotNull(lon, r'Lieu', 'lon'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
