// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_depot.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecisionDepot extends DecisionDepot {
  @override
  final String commandeId;
  @override
  final bool depotAutorise;
  @override
  final String motifCle;

  factory _$DecisionDepot([void Function(DecisionDepotBuilder)? updates]) =>
      (DecisionDepotBuilder()..update(updates))._build();

  _$DecisionDepot._(
      {required this.commandeId,
      required this.depotAutorise,
      required this.motifCle})
      : super._();
  @override
  DecisionDepot rebuild(void Function(DecisionDepotBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DecisionDepotBuilder toBuilder() => DecisionDepotBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecisionDepot &&
        commandeId == other.commandeId &&
        depotAutorise == other.depotAutorise &&
        motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, depotAutorise.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecisionDepot')
          ..add('commandeId', commandeId)
          ..add('depotAutorise', depotAutorise)
          ..add('motifCle', motifCle))
        .toString();
  }
}

class DecisionDepotBuilder
    implements Builder<DecisionDepot, DecisionDepotBuilder> {
  _$DecisionDepot? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _depotAutorise;
  bool? get depotAutorise => _$this._depotAutorise;
  set depotAutorise(bool? depotAutorise) =>
      _$this._depotAutorise = depotAutorise;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DecisionDepotBuilder() {
    DecisionDepot._defaults(this);
  }

  DecisionDepotBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _depotAutorise = $v.depotAutorise;
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecisionDepot other) {
    _$v = other as _$DecisionDepot;
  }

  @override
  void update(void Function(DecisionDepotBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecisionDepot build() => _build();

  _$DecisionDepot _build() {
    final _$result = _$v ??
        _$DecisionDepot._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'DecisionDepot', 'commandeId'),
          depotAutorise: BuiltValueNullFieldError.checkNotNull(
              depotAutorise, r'DecisionDepot', 'depotAutorise'),
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DecisionDepot', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
