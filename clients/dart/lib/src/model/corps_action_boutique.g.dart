// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corps_action_boutique.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CorpsActionBoutique extends CorpsActionBoutique {
  @override
  final ActionBoutiqueDto action;
  @override
  final int? dureeMinutes;

  factory _$CorpsActionBoutique(
          [void Function(CorpsActionBoutiqueBuilder)? updates]) =>
      (CorpsActionBoutiqueBuilder()..update(updates))._build();

  _$CorpsActionBoutique._({required this.action, this.dureeMinutes})
      : super._();
  @override
  CorpsActionBoutique rebuild(
          void Function(CorpsActionBoutiqueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CorpsActionBoutiqueBuilder toBuilder() =>
      CorpsActionBoutiqueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CorpsActionBoutique &&
        action == other.action &&
        dureeMinutes == other.dureeMinutes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, action.hashCode);
    _$hash = $jc(_$hash, dureeMinutes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CorpsActionBoutique')
          ..add('action', action)
          ..add('dureeMinutes', dureeMinutes))
        .toString();
  }
}

class CorpsActionBoutiqueBuilder
    implements Builder<CorpsActionBoutique, CorpsActionBoutiqueBuilder> {
  _$CorpsActionBoutique? _$v;

  ActionBoutiqueDto? _action;
  ActionBoutiqueDto? get action => _$this._action;
  set action(ActionBoutiqueDto? action) => _$this._action = action;

  int? _dureeMinutes;
  int? get dureeMinutes => _$this._dureeMinutes;
  set dureeMinutes(int? dureeMinutes) => _$this._dureeMinutes = dureeMinutes;

  CorpsActionBoutiqueBuilder() {
    CorpsActionBoutique._defaults(this);
  }

  CorpsActionBoutiqueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _action = $v.action;
      _dureeMinutes = $v.dureeMinutes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CorpsActionBoutique other) {
    _$v = other as _$CorpsActionBoutique;
  }

  @override
  void update(void Function(CorpsActionBoutiqueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CorpsActionBoutique build() => _build();

  _$CorpsActionBoutique _build() {
    final _$result = _$v ??
        _$CorpsActionBoutique._(
          action: BuiltValueNullFieldError.checkNotNull(
              action, r'CorpsActionBoutique', 'action'),
          dureeMinutes: dureeMinutes,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
