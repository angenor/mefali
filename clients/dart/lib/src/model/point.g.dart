// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'point.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Point extends Point {
  @override
  final double lat;
  @override
  final double lon;

  factory _$Point([void Function(PointBuilder)? updates]) =>
      (PointBuilder()..update(updates))._build();

  _$Point._({required this.lat, required this.lon}) : super._();
  @override
  Point rebuild(void Function(PointBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PointBuilder toBuilder() => PointBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Point && lat == other.lat && lon == other.lon;
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
    return (newBuiltValueToStringHelper(r'Point')
          ..add('lat', lat)
          ..add('lon', lon))
        .toString();
  }
}

class PointBuilder implements Builder<Point, PointBuilder> {
  _$Point? _$v;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  PointBuilder() {
    Point._defaults(this);
  }

  PointBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lat = $v.lat;
      _lon = $v.lon;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Point other) {
    _$v = other as _$Point;
  }

  @override
  void update(void Function(PointBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Point build() => _build();

  _$Point _build() {
    final _$result = _$v ??
        _$Point._(
          lat: BuiltValueNullFieldError.checkNotNull(lat, r'Point', 'lat'),
          lon: BuiltValueNullFieldError.checkNotNull(lon, r'Point', 'lon'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
