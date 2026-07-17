// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicule_declare.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VehiculeDeclare extends VehiculeDeclare {
  @override
  final bool actifZone;
  @override
  final String slug;
  @override
  final String typeTransportId;

  factory _$VehiculeDeclare([void Function(VehiculeDeclareBuilder)? updates]) =>
      (VehiculeDeclareBuilder()..update(updates))._build();

  _$VehiculeDeclare._(
      {required this.actifZone,
      required this.slug,
      required this.typeTransportId})
      : super._();
  @override
  VehiculeDeclare rebuild(void Function(VehiculeDeclareBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VehiculeDeclareBuilder toBuilder() => VehiculeDeclareBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VehiculeDeclare &&
        actifZone == other.actifZone &&
        slug == other.slug &&
        typeTransportId == other.typeTransportId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actifZone.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jc(_$hash, typeTransportId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VehiculeDeclare')
          ..add('actifZone', actifZone)
          ..add('slug', slug)
          ..add('typeTransportId', typeTransportId))
        .toString();
  }
}

class VehiculeDeclareBuilder
    implements Builder<VehiculeDeclare, VehiculeDeclareBuilder> {
  _$VehiculeDeclare? _$v;

  bool? _actifZone;
  bool? get actifZone => _$this._actifZone;
  set actifZone(bool? actifZone) => _$this._actifZone = actifZone;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  String? _typeTransportId;
  String? get typeTransportId => _$this._typeTransportId;
  set typeTransportId(String? typeTransportId) =>
      _$this._typeTransportId = typeTransportId;

  VehiculeDeclareBuilder() {
    VehiculeDeclare._defaults(this);
  }

  VehiculeDeclareBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actifZone = $v.actifZone;
      _slug = $v.slug;
      _typeTransportId = $v.typeTransportId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VehiculeDeclare other) {
    _$v = other as _$VehiculeDeclare;
  }

  @override
  void update(void Function(VehiculeDeclareBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VehiculeDeclare build() => _build();

  _$VehiculeDeclare _build() {
    final _$result = _$v ??
        _$VehiculeDeclare._(
          actifZone: BuiltValueNullFieldError.checkNotNull(
              actifZone, r'VehiculeDeclare', 'actifZone'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'VehiculeDeclare', 'slug'),
          typeTransportId: BuiltValueNullFieldError.checkNotNull(
              typeTransportId, r'VehiculeDeclare', 'typeTransportId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
