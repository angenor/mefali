// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'action_arret.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ActionArret extends ActionArret {
  @override
  final DateTime horodatageLocal;
  @override
  final String? motif;
  @override
  final String uuidClient;

  factory _$ActionArret([void Function(ActionArretBuilder)? updates]) =>
      (ActionArretBuilder()..update(updates))._build();

  _$ActionArret._(
      {required this.horodatageLocal, this.motif, required this.uuidClient})
      : super._();
  @override
  ActionArret rebuild(void Function(ActionArretBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ActionArretBuilder toBuilder() => ActionArretBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ActionArret &&
        horodatageLocal == other.horodatageLocal &&
        motif == other.motif &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, horodatageLocal.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ActionArret')
          ..add('horodatageLocal', horodatageLocal)
          ..add('motif', motif)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class ActionArretBuilder implements Builder<ActionArret, ActionArretBuilder> {
  _$ActionArret? _$v;

  DateTime? _horodatageLocal;
  DateTime? get horodatageLocal => _$this._horodatageLocal;
  set horodatageLocal(DateTime? horodatageLocal) =>
      _$this._horodatageLocal = horodatageLocal;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  ActionArretBuilder() {
    ActionArret._defaults(this);
  }

  ActionArretBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _horodatageLocal = $v.horodatageLocal;
      _motif = $v.motif;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ActionArret other) {
    _$v = other as _$ActionArret;
  }

  @override
  void update(void Function(ActionArretBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ActionArret build() => _build();

  _$ActionArret _build() {
    final _$result = _$v ??
        _$ActionArret._(
          horodatageLocal: BuiltValueNullFieldError.checkNotNull(
              horodatageLocal, r'ActionArret', 'horodatageLocal'),
          motif: motif,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'ActionArret', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
