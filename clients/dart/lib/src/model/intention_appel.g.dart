// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'intention_appel.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IntentionAppel extends IntentionAppel {
  @override
  final String? motif;

  factory _$IntentionAppel([void Function(IntentionAppelBuilder)? updates]) =>
      (IntentionAppelBuilder()..update(updates))._build();

  _$IntentionAppel._({this.motif}) : super._();
  @override
  IntentionAppel rebuild(void Function(IntentionAppelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IntentionAppelBuilder toBuilder() => IntentionAppelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IntentionAppel && motif == other.motif;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IntentionAppel')..add('motif', motif))
        .toString();
  }
}

class IntentionAppelBuilder
    implements Builder<IntentionAppel, IntentionAppelBuilder> {
  _$IntentionAppel? _$v;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  IntentionAppelBuilder() {
    IntentionAppel._defaults(this);
  }

  IntentionAppelBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motif = $v.motif;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IntentionAppel other) {
    _$v = other as _$IntentionAppel;
  }

  @override
  void update(void Function(IntentionAppelBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IntentionAppel build() => _build();

  _$IntentionAppel _build() {
    final _$result = _$v ??
        _$IntentionAppel._(
          motif: motif,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
