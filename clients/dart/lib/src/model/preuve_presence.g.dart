// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preuve_presence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PreuvePresence extends PreuvePresence {
  @override
  final String? motifCle;
  @override
  final bool ok;
  @override
  final int requis;
  @override
  final int secondes;

  factory _$PreuvePresence([void Function(PreuvePresenceBuilder)? updates]) =>
      (PreuvePresenceBuilder()..update(updates))._build();

  _$PreuvePresence._(
      {this.motifCle,
      required this.ok,
      required this.requis,
      required this.secondes})
      : super._();
  @override
  PreuvePresence rebuild(void Function(PreuvePresenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreuvePresenceBuilder toBuilder() => PreuvePresenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PreuvePresence &&
        motifCle == other.motifCle &&
        ok == other.ok &&
        requis == other.requis &&
        secondes == other.secondes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, requis.hashCode);
    _$hash = $jc(_$hash, secondes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PreuvePresence')
          ..add('motifCle', motifCle)
          ..add('ok', ok)
          ..add('requis', requis)
          ..add('secondes', secondes))
        .toString();
  }
}

class PreuvePresenceBuilder
    implements Builder<PreuvePresence, PreuvePresenceBuilder> {
  _$PreuvePresence? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  int? _requis;
  int? get requis => _$this._requis;
  set requis(int? requis) => _$this._requis = requis;

  int? _secondes;
  int? get secondes => _$this._secondes;
  set secondes(int? secondes) => _$this._secondes = secondes;

  PreuvePresenceBuilder() {
    PreuvePresence._defaults(this);
  }

  PreuvePresenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _ok = $v.ok;
      _requis = $v.requis;
      _secondes = $v.secondes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PreuvePresence other) {
    _$v = other as _$PreuvePresence;
  }

  @override
  void update(void Function(PreuvePresenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PreuvePresence build() => _build();

  _$PreuvePresence _build() {
    final _$result = _$v ??
        _$PreuvePresence._(
          motifCle: motifCle,
          ok: BuiltValueNullFieldError.checkNotNull(
              ok, r'PreuvePresence', 'ok'),
          requis: BuiltValueNullFieldError.checkNotNull(
              requis, r'PreuvePresence', 'requis'),
          secondes: BuiltValueNullFieldError.checkNotNull(
              secondes, r'PreuvePresence', 'secondes'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
