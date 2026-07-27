// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_publication_position.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatPublicationPosition extends EtatPublicationPosition {
  @override
  final bool dansLePool;
  @override
  final int prochainePublicationS;
  @override
  final int ttlS;

  factory _$EtatPublicationPosition(
          [void Function(EtatPublicationPositionBuilder)? updates]) =>
      (EtatPublicationPositionBuilder()..update(updates))._build();

  _$EtatPublicationPosition._(
      {required this.dansLePool,
      required this.prochainePublicationS,
      required this.ttlS})
      : super._();
  @override
  EtatPublicationPosition rebuild(
          void Function(EtatPublicationPositionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatPublicationPositionBuilder toBuilder() =>
      EtatPublicationPositionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatPublicationPosition &&
        dansLePool == other.dansLePool &&
        prochainePublicationS == other.prochainePublicationS &&
        ttlS == other.ttlS;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, dansLePool.hashCode);
    _$hash = $jc(_$hash, prochainePublicationS.hashCode);
    _$hash = $jc(_$hash, ttlS.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatPublicationPosition')
          ..add('dansLePool', dansLePool)
          ..add('prochainePublicationS', prochainePublicationS)
          ..add('ttlS', ttlS))
        .toString();
  }
}

class EtatPublicationPositionBuilder
    implements
        Builder<EtatPublicationPosition, EtatPublicationPositionBuilder> {
  _$EtatPublicationPosition? _$v;

  bool? _dansLePool;
  bool? get dansLePool => _$this._dansLePool;
  set dansLePool(bool? dansLePool) => _$this._dansLePool = dansLePool;

  int? _prochainePublicationS;
  int? get prochainePublicationS => _$this._prochainePublicationS;
  set prochainePublicationS(int? prochainePublicationS) =>
      _$this._prochainePublicationS = prochainePublicationS;

  int? _ttlS;
  int? get ttlS => _$this._ttlS;
  set ttlS(int? ttlS) => _$this._ttlS = ttlS;

  EtatPublicationPositionBuilder() {
    EtatPublicationPosition._defaults(this);
  }

  EtatPublicationPositionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _dansLePool = $v.dansLePool;
      _prochainePublicationS = $v.prochainePublicationS;
      _ttlS = $v.ttlS;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatPublicationPosition other) {
    _$v = other as _$EtatPublicationPosition;
  }

  @override
  void update(void Function(EtatPublicationPositionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatPublicationPosition build() => _build();

  _$EtatPublicationPosition _build() {
    final _$result = _$v ??
        _$EtatPublicationPosition._(
          dansLePool: BuiltValueNullFieldError.checkNotNull(
              dansLePool, r'EtatPublicationPosition', 'dansLePool'),
          prochainePublicationS: BuiltValueNullFieldError.checkNotNull(
              prochainePublicationS,
              r'EtatPublicationPosition',
              'prochainePublicationS'),
          ttlS: BuiltValueNullFieldError.checkNotNull(
              ttlS, r'EtatPublicationPosition', 'ttlS'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
