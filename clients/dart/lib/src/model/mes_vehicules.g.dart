// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mes_vehicules.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MesVehicules extends MesVehicules {
  @override
  final BuiltList<String> vehicules;

  factory _$MesVehicules([void Function(MesVehiculesBuilder)? updates]) =>
      (MesVehiculesBuilder()..update(updates))._build();

  _$MesVehicules._({required this.vehicules}) : super._();
  @override
  MesVehicules rebuild(void Function(MesVehiculesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MesVehiculesBuilder toBuilder() => MesVehiculesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MesVehicules && vehicules == other.vehicules;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, vehicules.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MesVehicules')
          ..add('vehicules', vehicules))
        .toString();
  }
}

class MesVehiculesBuilder
    implements Builder<MesVehicules, MesVehiculesBuilder> {
  _$MesVehicules? _$v;

  ListBuilder<String>? _vehicules;
  ListBuilder<String> get vehicules =>
      _$this._vehicules ??= ListBuilder<String>();
  set vehicules(ListBuilder<String>? vehicules) =>
      _$this._vehicules = vehicules;

  MesVehiculesBuilder() {
    MesVehicules._defaults(this);
  }

  MesVehiculesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _vehicules = $v.vehicules.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MesVehicules other) {
    _$v = other as _$MesVehicules;
  }

  @override
  void update(void Function(MesVehiculesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MesVehicules build() => _build();

  _$MesVehicules _build() {
    _$MesVehicules _$result;
    try {
      _$result = _$v ??
          _$MesVehicules._(
            vehicules: vehicules.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'vehicules';
        vehicules.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'MesVehicules', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
