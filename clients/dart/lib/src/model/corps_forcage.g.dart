// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corps_forcage.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CorpsForcage extends CorpsForcage {
  @override
  final ForcageDto forcage;

  factory _$CorpsForcage([void Function(CorpsForcageBuilder)? updates]) =>
      (CorpsForcageBuilder()..update(updates))._build();

  _$CorpsForcage._({required this.forcage}) : super._();
  @override
  CorpsForcage rebuild(void Function(CorpsForcageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CorpsForcageBuilder toBuilder() => CorpsForcageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CorpsForcage && forcage == other.forcage;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, forcage.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CorpsForcage')
          ..add('forcage', forcage))
        .toString();
  }
}

class CorpsForcageBuilder
    implements Builder<CorpsForcage, CorpsForcageBuilder> {
  _$CorpsForcage? _$v;

  ForcageDto? _forcage;
  ForcageDto? get forcage => _$this._forcage;
  set forcage(ForcageDto? forcage) => _$this._forcage = forcage;

  CorpsForcageBuilder() {
    CorpsForcage._defaults(this);
  }

  CorpsForcageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _forcage = $v.forcage;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CorpsForcage other) {
    _$v = other as _$CorpsForcage;
  }

  @override
  void update(void Function(CorpsForcageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CorpsForcage build() => _build();

  _$CorpsForcage _build() {
    final _$result = _$v ??
        _$CorpsForcage._(
          forcage: BuiltValueNullFieldError.checkNotNull(
              forcage, r'CorpsForcage', 'forcage'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
