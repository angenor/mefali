// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_verification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatVerification extends ResultatVerification {
  @override
  final OneOf oneOf;

  factory _$ResultatVerification(
          [void Function(ResultatVerificationBuilder)? updates]) =>
      (ResultatVerificationBuilder()..update(updates))._build();

  _$ResultatVerification._({required this.oneOf}) : super._();
  @override
  ResultatVerification rebuild(
          void Function(ResultatVerificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatVerificationBuilder toBuilder() =>
      ResultatVerificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatVerification && oneOf == other.oneOf;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, oneOf.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatVerification')
          ..add('oneOf', oneOf))
        .toString();
  }
}

class ResultatVerificationBuilder
    implements Builder<ResultatVerification, ResultatVerificationBuilder> {
  _$ResultatVerification? _$v;

  OneOf? _oneOf;
  OneOf? get oneOf => _$this._oneOf;
  set oneOf(OneOf? oneOf) => _$this._oneOf = oneOf;

  ResultatVerificationBuilder() {
    ResultatVerification._defaults(this);
  }

  ResultatVerificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _oneOf = $v.oneOf;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatVerification other) {
    _$v = other as _$ResultatVerification;
  }

  @override
  void update(void Function(ResultatVerificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatVerification build() => _build();

  _$ResultatVerification _build() {
    final _$result = _$v ??
        _$ResultatVerification._(
          oneOf: BuiltValueNullFieldError.checkNotNull(
              oneOf, r'ResultatVerification', 'oneOf'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
