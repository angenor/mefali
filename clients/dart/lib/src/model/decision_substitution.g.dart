// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_substitution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecisionSubstitution extends DecisionSubstitution {
  @override
  final bool accepte;

  factory _$DecisionSubstitution(
          [void Function(DecisionSubstitutionBuilder)? updates]) =>
      (DecisionSubstitutionBuilder()..update(updates))._build();

  _$DecisionSubstitution._({required this.accepte}) : super._();
  @override
  DecisionSubstitution rebuild(
          void Function(DecisionSubstitutionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DecisionSubstitutionBuilder toBuilder() =>
      DecisionSubstitutionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecisionSubstitution && accepte == other.accepte;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accepte.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecisionSubstitution')
          ..add('accepte', accepte))
        .toString();
  }
}

class DecisionSubstitutionBuilder
    implements Builder<DecisionSubstitution, DecisionSubstitutionBuilder> {
  _$DecisionSubstitution? _$v;

  bool? _accepte;
  bool? get accepte => _$this._accepte;
  set accepte(bool? accepte) => _$this._accepte = accepte;

  DecisionSubstitutionBuilder() {
    DecisionSubstitution._defaults(this);
  }

  DecisionSubstitutionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accepte = $v.accepte;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecisionSubstitution other) {
    _$v = other as _$DecisionSubstitution;
  }

  @override
  void update(void Function(DecisionSubstitutionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecisionSubstitution build() => _build();

  _$DecisionSubstitution _build() {
    final _$result = _$v ??
        _$DecisionSubstitution._(
          accepte: BuiltValueNullFieldError.checkNotNull(
              accepte, r'DecisionSubstitution', 'accepte'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
