// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remises_bloquees.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RemisesBloquees extends RemisesBloquees {
  @override
  final BuiltList<RemiseBloquee> remises;

  factory _$RemisesBloquees([void Function(RemisesBloqueesBuilder)? updates]) =>
      (RemisesBloqueesBuilder()..update(updates))._build();

  _$RemisesBloquees._({required this.remises}) : super._();
  @override
  RemisesBloquees rebuild(void Function(RemisesBloqueesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RemisesBloqueesBuilder toBuilder() => RemisesBloqueesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RemisesBloquees && remises == other.remises;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, remises.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RemisesBloquees')
          ..add('remises', remises))
        .toString();
  }
}

class RemisesBloqueesBuilder
    implements Builder<RemisesBloquees, RemisesBloqueesBuilder> {
  _$RemisesBloquees? _$v;

  ListBuilder<RemiseBloquee>? _remises;
  ListBuilder<RemiseBloquee> get remises =>
      _$this._remises ??= ListBuilder<RemiseBloquee>();
  set remises(ListBuilder<RemiseBloquee>? remises) => _$this._remises = remises;

  RemisesBloqueesBuilder() {
    RemisesBloquees._defaults(this);
  }

  RemisesBloqueesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _remises = $v.remises.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RemisesBloquees other) {
    _$v = other as _$RemisesBloquees;
  }

  @override
  void update(void Function(RemisesBloqueesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RemisesBloquees build() => _build();

  _$RemisesBloquees _build() {
    _$RemisesBloquees _$result;
    try {
      _$result = _$v ??
          _$RemisesBloquees._(
            remises: remises.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'remises';
        remises.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RemisesBloquees', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
