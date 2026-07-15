// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_role.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecisionRole extends DecisionRole {
  @override
  final ActionRoleDto action;
  @override
  final String? motif;

  factory _$DecisionRole([void Function(DecisionRoleBuilder)? updates]) =>
      (DecisionRoleBuilder()..update(updates))._build();

  _$DecisionRole._({required this.action, this.motif}) : super._();
  @override
  DecisionRole rebuild(void Function(DecisionRoleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DecisionRoleBuilder toBuilder() => DecisionRoleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecisionRole &&
        action == other.action &&
        motif == other.motif;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecisionRole')
          ..add('action', action)
          ..add('motif', motif))
        .toString();
  }
}

class DecisionRoleBuilder
    implements Builder<DecisionRole, DecisionRoleBuilder> {
  _$DecisionRole? _$v;

  ActionRoleDto? _action;
  ActionRoleDto? get action => _$this._action;
  set action(ActionRoleDto? action) => _$this._action = action;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  DecisionRoleBuilder() {
    DecisionRole._defaults(this);
  }

  DecisionRoleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _action = $v.action;
      _motif = $v.motif;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecisionRole other) {
    _$v = other as _$DecisionRole;
  }

  @override
  void update(void Function(DecisionRoleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecisionRole build() => _build();

  _$DecisionRole _build() {
    final _$result = _$v ??
        _$DecisionRole._(
          action: BuiltValueNullFieldError.checkNotNull(
              action, r'DecisionRole', 'action'),
          motif: motif,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
