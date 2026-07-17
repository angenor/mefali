// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepte.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Accepte extends Accepte {
  @override
  final String messageCle;

  factory _$Accepte([void Function(AccepteBuilder)? updates]) =>
      (AccepteBuilder()..update(updates))._build();

  _$Accepte._({required this.messageCle}) : super._();
  @override
  Accepte rebuild(void Function(AccepteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AccepteBuilder toBuilder() => AccepteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Accepte && messageCle == other.messageCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, messageCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Accepte')
          ..add('messageCle', messageCle))
        .toString();
  }
}

class AccepteBuilder implements Builder<Accepte, AccepteBuilder> {
  _$Accepte? _$v;

  String? _messageCle;
  String? get messageCle => _$this._messageCle;
  set messageCle(String? messageCle) => _$this._messageCle = messageCle;

  AccepteBuilder() {
    Accepte._defaults(this);
  }

  AccepteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _messageCle = $v.messageCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Accepte other) {
    _$v = other as _$Accepte;
  }

  @override
  void update(void Function(AccepteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Accepte build() => _build();

  _$Accepte _build() {
    final _$result = _$v ??
        _$Accepte._(
          messageCle: BuiltValueNullFieldError.checkNotNull(
              messageCle, r'Accepte', 'messageCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
