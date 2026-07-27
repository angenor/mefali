// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coursier_du_pool.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CoursierDuPool extends CoursierDuPool {
  @override
  final int ageS;
  @override
  final BuiltList<String> capacites;
  @override
  final String? courseActive;
  @override
  final String coursierId;
  @override
  final String devise;
  @override
  final double lat;
  @override
  final double lon;
  @override
  final int plafondUnites;

  factory _$CoursierDuPool([void Function(CoursierDuPoolBuilder)? updates]) =>
      (CoursierDuPoolBuilder()..update(updates))._build();

  _$CoursierDuPool._(
      {required this.ageS,
      required this.capacites,
      this.courseActive,
      required this.coursierId,
      required this.devise,
      required this.lat,
      required this.lon,
      required this.plafondUnites})
      : super._();
  @override
  CoursierDuPool rebuild(void Function(CoursierDuPoolBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CoursierDuPoolBuilder toBuilder() => CoursierDuPoolBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CoursierDuPool &&
        ageS == other.ageS &&
        capacites == other.capacites &&
        courseActive == other.courseActive &&
        coursierId == other.coursierId &&
        devise == other.devise &&
        lat == other.lat &&
        lon == other.lon &&
        plafondUnites == other.plafondUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ageS.hashCode);
    _$hash = $jc(_$hash, capacites.hashCode);
    _$hash = $jc(_$hash, courseActive.hashCode);
    _$hash = $jc(_$hash, coursierId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jc(_$hash, plafondUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CoursierDuPool')
          ..add('ageS', ageS)
          ..add('capacites', capacites)
          ..add('courseActive', courseActive)
          ..add('coursierId', coursierId)
          ..add('devise', devise)
          ..add('lat', lat)
          ..add('lon', lon)
          ..add('plafondUnites', plafondUnites))
        .toString();
  }
}

class CoursierDuPoolBuilder
    implements Builder<CoursierDuPool, CoursierDuPoolBuilder> {
  _$CoursierDuPool? _$v;

  int? _ageS;
  int? get ageS => _$this._ageS;
  set ageS(int? ageS) => _$this._ageS = ageS;

  ListBuilder<String>? _capacites;
  ListBuilder<String> get capacites =>
      _$this._capacites ??= ListBuilder<String>();
  set capacites(ListBuilder<String>? capacites) =>
      _$this._capacites = capacites;

  String? _courseActive;
  String? get courseActive => _$this._courseActive;
  set courseActive(String? courseActive) => _$this._courseActive = courseActive;

  String? _coursierId;
  String? get coursierId => _$this._coursierId;
  set coursierId(String? coursierId) => _$this._coursierId = coursierId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  int? _plafondUnites;
  int? get plafondUnites => _$this._plafondUnites;
  set plafondUnites(int? plafondUnites) =>
      _$this._plafondUnites = plafondUnites;

  CoursierDuPoolBuilder() {
    CoursierDuPool._defaults(this);
  }

  CoursierDuPoolBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ageS = $v.ageS;
      _capacites = $v.capacites.toBuilder();
      _courseActive = $v.courseActive;
      _coursierId = $v.coursierId;
      _devise = $v.devise;
      _lat = $v.lat;
      _lon = $v.lon;
      _plafondUnites = $v.plafondUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CoursierDuPool other) {
    _$v = other as _$CoursierDuPool;
  }

  @override
  void update(void Function(CoursierDuPoolBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CoursierDuPool build() => _build();

  _$CoursierDuPool _build() {
    _$CoursierDuPool _$result;
    try {
      _$result = _$v ??
          _$CoursierDuPool._(
            ageS: BuiltValueNullFieldError.checkNotNull(
                ageS, r'CoursierDuPool', 'ageS'),
            capacites: capacites.build(),
            courseActive: courseActive,
            coursierId: BuiltValueNullFieldError.checkNotNull(
                coursierId, r'CoursierDuPool', 'coursierId'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'CoursierDuPool', 'devise'),
            lat: BuiltValueNullFieldError.checkNotNull(
                lat, r'CoursierDuPool', 'lat'),
            lon: BuiltValueNullFieldError.checkNotNull(
                lon, r'CoursierDuPool', 'lon'),
            plafondUnites: BuiltValueNullFieldError.checkNotNull(
                plafondUnites, r'CoursierDuPool', 'plafondUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'capacites';
        capacites.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CoursierDuPool', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
