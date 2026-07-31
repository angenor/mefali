// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_de_presence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LotDePresence extends LotDePresence {
  @override
  final BuiltList<ReleveDePresence> releves;

  factory _$LotDePresence([void Function(LotDePresenceBuilder)? updates]) =>
      (LotDePresenceBuilder()..update(updates))._build();

  _$LotDePresence._({required this.releves}) : super._();
  @override
  LotDePresence rebuild(void Function(LotDePresenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LotDePresenceBuilder toBuilder() => LotDePresenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LotDePresence && releves == other.releves;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, releves.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LotDePresence')
          ..add('releves', releves))
        .toString();
  }
}

class LotDePresenceBuilder
    implements Builder<LotDePresence, LotDePresenceBuilder> {
  _$LotDePresence? _$v;

  ListBuilder<ReleveDePresence>? _releves;
  ListBuilder<ReleveDePresence> get releves =>
      _$this._releves ??= ListBuilder<ReleveDePresence>();
  set releves(ListBuilder<ReleveDePresence>? releves) =>
      _$this._releves = releves;

  LotDePresenceBuilder() {
    LotDePresence._defaults(this);
  }

  LotDePresenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _releves = $v.releves.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LotDePresence other) {
    _$v = other as _$LotDePresence;
  }

  @override
  void update(void Function(LotDePresenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LotDePresence build() => _build();

  _$LotDePresence _build() {
    _$LotDePresence _$result;
    try {
      _$result = _$v ??
          _$LotDePresence._(
            releves: releves.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'releves';
        releves.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'LotDePresence', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
