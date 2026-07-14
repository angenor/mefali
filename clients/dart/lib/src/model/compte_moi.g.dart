// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'compte_moi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CompteMoi extends CompteMoi {
  @override
  final DateTime creeLe;
  @override
  final String id;
  @override
  final BuiltList<EtatRoleDto> roles;
  @override
  final String telephoneE164;
  @override
  final String zoneId;

  factory _$CompteMoi([void Function(CompteMoiBuilder)? updates]) =>
      (CompteMoiBuilder()..update(updates))._build();

  _$CompteMoi._(
      {required this.creeLe,
      required this.id,
      required this.roles,
      required this.telephoneE164,
      required this.zoneId})
      : super._();
  @override
  CompteMoi rebuild(void Function(CompteMoiBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CompteMoiBuilder toBuilder() => CompteMoiBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CompteMoi &&
        creeLe == other.creeLe &&
        id == other.id &&
        roles == other.roles &&
        telephoneE164 == other.telephoneE164 &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, roles.hashCode);
    _$hash = $jc(_$hash, telephoneE164.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CompteMoi')
          ..add('creeLe', creeLe)
          ..add('id', id)
          ..add('roles', roles)
          ..add('telephoneE164', telephoneE164)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class CompteMoiBuilder implements Builder<CompteMoi, CompteMoiBuilder> {
  _$CompteMoi? _$v;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<EtatRoleDto>? _roles;
  ListBuilder<EtatRoleDto> get roles =>
      _$this._roles ??= ListBuilder<EtatRoleDto>();
  set roles(ListBuilder<EtatRoleDto>? roles) => _$this._roles = roles;

  String? _telephoneE164;
  String? get telephoneE164 => _$this._telephoneE164;
  set telephoneE164(String? telephoneE164) =>
      _$this._telephoneE164 = telephoneE164;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  CompteMoiBuilder() {
    CompteMoi._defaults(this);
  }

  CompteMoiBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _creeLe = $v.creeLe;
      _id = $v.id;
      _roles = $v.roles.toBuilder();
      _telephoneE164 = $v.telephoneE164;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CompteMoi other) {
    _$v = other as _$CompteMoi;
  }

  @override
  void update(void Function(CompteMoiBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CompteMoi build() => _build();

  _$CompteMoi _build() {
    _$CompteMoi _$result;
    try {
      _$result = _$v ??
          _$CompteMoi._(
            creeLe: BuiltValueNullFieldError.checkNotNull(
                creeLe, r'CompteMoi', 'creeLe'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'CompteMoi', 'id'),
            roles: roles.build(),
            telephoneE164: BuiltValueNullFieldError.checkNotNull(
                telephoneE164, r'CompteMoi', 'telephoneE164'),
            zoneId: BuiltValueNullFieldError.checkNotNull(
                zoneId, r'CompteMoi', 'zoneId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'roles';
        roles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'CompteMoi', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
