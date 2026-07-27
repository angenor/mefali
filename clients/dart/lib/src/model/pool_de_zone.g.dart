// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool_de_zone.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PoolDeZone extends PoolDeZone {
  @override
  final BuiltList<CoursierDuPool> coursiers;
  @override
  final String zoneId;

  factory _$PoolDeZone([void Function(PoolDeZoneBuilder)? updates]) =>
      (PoolDeZoneBuilder()..update(updates))._build();

  _$PoolDeZone._({required this.coursiers, required this.zoneId}) : super._();
  @override
  PoolDeZone rebuild(void Function(PoolDeZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PoolDeZoneBuilder toBuilder() => PoolDeZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PoolDeZone &&
        coursiers == other.coursiers &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, coursiers.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PoolDeZone')
          ..add('coursiers', coursiers)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class PoolDeZoneBuilder implements Builder<PoolDeZone, PoolDeZoneBuilder> {
  _$PoolDeZone? _$v;

  ListBuilder<CoursierDuPool>? _coursiers;
  ListBuilder<CoursierDuPool> get coursiers =>
      _$this._coursiers ??= ListBuilder<CoursierDuPool>();
  set coursiers(ListBuilder<CoursierDuPool>? coursiers) =>
      _$this._coursiers = coursiers;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  PoolDeZoneBuilder() {
    PoolDeZone._defaults(this);
  }

  PoolDeZoneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _coursiers = $v.coursiers.toBuilder();
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PoolDeZone other) {
    _$v = other as _$PoolDeZone;
  }

  @override
  void update(void Function(PoolDeZoneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PoolDeZone build() => _build();

  _$PoolDeZone _build() {
    _$PoolDeZone _$result;
    try {
      _$result = _$v ??
          _$PoolDeZone._(
            coursiers: coursiers.build(),
            zoneId: BuiltValueNullFieldError.checkNotNull(
                zoneId, r'PoolDeZone', 'zoneId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'coursiers';
        coursiers.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PoolDeZone', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
