// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'presence_enregistree.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PresenceEnregistree extends PresenceEnregistree {
  @override
  final int presenceS;
  @override
  final int requisS;
  @override
  final int retenus;

  factory _$PresenceEnregistree(
          [void Function(PresenceEnregistreeBuilder)? updates]) =>
      (PresenceEnregistreeBuilder()..update(updates))._build();

  _$PresenceEnregistree._(
      {required this.presenceS, required this.requisS, required this.retenus})
      : super._();
  @override
  PresenceEnregistree rebuild(
          void Function(PresenceEnregistreeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PresenceEnregistreeBuilder toBuilder() =>
      PresenceEnregistreeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PresenceEnregistree &&
        presenceS == other.presenceS &&
        requisS == other.requisS &&
        retenus == other.retenus;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, presenceS.hashCode);
    _$hash = $jc(_$hash, requisS.hashCode);
    _$hash = $jc(_$hash, retenus.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PresenceEnregistree')
          ..add('presenceS', presenceS)
          ..add('requisS', requisS)
          ..add('retenus', retenus))
        .toString();
  }
}

class PresenceEnregistreeBuilder
    implements Builder<PresenceEnregistree, PresenceEnregistreeBuilder> {
  _$PresenceEnregistree? _$v;

  int? _presenceS;
  int? get presenceS => _$this._presenceS;
  set presenceS(int? presenceS) => _$this._presenceS = presenceS;

  int? _requisS;
  int? get requisS => _$this._requisS;
  set requisS(int? requisS) => _$this._requisS = requisS;

  int? _retenus;
  int? get retenus => _$this._retenus;
  set retenus(int? retenus) => _$this._retenus = retenus;

  PresenceEnregistreeBuilder() {
    PresenceEnregistree._defaults(this);
  }

  PresenceEnregistreeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _presenceS = $v.presenceS;
      _requisS = $v.requisS;
      _retenus = $v.retenus;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PresenceEnregistree other) {
    _$v = other as _$PresenceEnregistree;
  }

  @override
  void update(void Function(PresenceEnregistreeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PresenceEnregistree build() => _build();

  _$PresenceEnregistree _build() {
    final _$result = _$v ??
        _$PresenceEnregistree._(
          presenceS: BuiltValueNullFieldError.checkNotNull(
              presenceS, r'PresenceEnregistree', 'presenceS'),
          requisS: BuiltValueNullFieldError.checkNotNull(
              requisS, r'PresenceEnregistree', 'requisS'),
          retenus: BuiltValueNullFieldError.checkNotNull(
              retenus, r'PresenceEnregistree', 'retenus'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
