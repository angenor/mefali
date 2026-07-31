// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_indemnisation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecisionIndemnisation extends DecisionIndemnisation {
  @override
  final String? motifCle;

  factory _$DecisionIndemnisation(
          [void Function(DecisionIndemnisationBuilder)? updates]) =>
      (DecisionIndemnisationBuilder()..update(updates))._build();

  _$DecisionIndemnisation._({this.motifCle}) : super._();
  @override
  DecisionIndemnisation rebuild(
          void Function(DecisionIndemnisationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DecisionIndemnisationBuilder toBuilder() =>
      DecisionIndemnisationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecisionIndemnisation && motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecisionIndemnisation')
          ..add('motifCle', motifCle))
        .toString();
  }
}

class DecisionIndemnisationBuilder
    implements Builder<DecisionIndemnisation, DecisionIndemnisationBuilder> {
  _$DecisionIndemnisation? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DecisionIndemnisationBuilder() {
    DecisionIndemnisation._defaults(this);
  }

  DecisionIndemnisationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecisionIndemnisation other) {
    _$v = other as _$DecisionIndemnisation;
  }

  @override
  void update(void Function(DecisionIndemnisationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecisionIndemnisation build() => _build();

  _$DecisionIndemnisation _build() {
    final _$result = _$v ??
        _$DecisionIndemnisation._(
          motifCle: motifCle,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
