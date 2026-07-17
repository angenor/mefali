// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'erreur_api.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ErreurApi extends ErreurApi {
  @override
  final String code;
  @override
  final String messageCle;

  factory _$ErreurApi([void Function(ErreurApiBuilder)? updates]) =>
      (ErreurApiBuilder()..update(updates))._build();

  _$ErreurApi._({required this.code, required this.messageCle}) : super._();
  @override
  ErreurApi rebuild(void Function(ErreurApiBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ErreurApiBuilder toBuilder() => ErreurApiBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ErreurApi &&
        code == other.code &&
        messageCle == other.messageCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, messageCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ErreurApi')
          ..add('code', code)
          ..add('messageCle', messageCle))
        .toString();
  }
}

class ErreurApiBuilder implements Builder<ErreurApi, ErreurApiBuilder> {
  _$ErreurApi? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _messageCle;
  String? get messageCle => _$this._messageCle;
  set messageCle(String? messageCle) => _$this._messageCle = messageCle;

  ErreurApiBuilder() {
    ErreurApi._defaults(this);
  }

  ErreurApiBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _messageCle = $v.messageCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ErreurApi other) {
    _$v = other as _$ErreurApi;
  }

  @override
  void update(void Function(ErreurApiBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ErreurApi build() => _build();

  _$ErreurApi _build() {
    final _$result = _$v ??
        _$ErreurApi._(
          code:
              BuiltValueNullFieldError.checkNotNull(code, r'ErreurApi', 'code'),
          messageCle: BuiltValueNullFieldError.checkNotNull(
              messageCle, r'ErreurApi', 'messageCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
