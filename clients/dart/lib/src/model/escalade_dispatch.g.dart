// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'escalade_dispatch.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EscaladeDispatch extends EscaladeDispatch {
  @override
  final int ageS;
  @override
  final String chemin;
  @override
  final String commandeId;
  @override
  final String etat;
  @override
  final int nbOffresEmises;
  @override
  final int seuilS;
  @override
  final String zoneId;

  factory _$EscaladeDispatch(
          [void Function(EscaladeDispatchBuilder)? updates]) =>
      (EscaladeDispatchBuilder()..update(updates))._build();

  _$EscaladeDispatch._(
      {required this.ageS,
      required this.chemin,
      required this.commandeId,
      required this.etat,
      required this.nbOffresEmises,
      required this.seuilS,
      required this.zoneId})
      : super._();
  @override
  EscaladeDispatch rebuild(void Function(EscaladeDispatchBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EscaladeDispatchBuilder toBuilder() =>
      EscaladeDispatchBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EscaladeDispatch &&
        ageS == other.ageS &&
        chemin == other.chemin &&
        commandeId == other.commandeId &&
        etat == other.etat &&
        nbOffresEmises == other.nbOffresEmises &&
        seuilS == other.seuilS &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ageS.hashCode);
    _$hash = $jc(_$hash, chemin.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, nbOffresEmises.hashCode);
    _$hash = $jc(_$hash, seuilS.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EscaladeDispatch')
          ..add('ageS', ageS)
          ..add('chemin', chemin)
          ..add('commandeId', commandeId)
          ..add('etat', etat)
          ..add('nbOffresEmises', nbOffresEmises)
          ..add('seuilS', seuilS)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class EscaladeDispatchBuilder
    implements Builder<EscaladeDispatch, EscaladeDispatchBuilder> {
  _$EscaladeDispatch? _$v;

  int? _ageS;
  int? get ageS => _$this._ageS;
  set ageS(int? ageS) => _$this._ageS = ageS;

  String? _chemin;
  String? get chemin => _$this._chemin;
  set chemin(String? chemin) => _$this._chemin = chemin;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  int? _nbOffresEmises;
  int? get nbOffresEmises => _$this._nbOffresEmises;
  set nbOffresEmises(int? nbOffresEmises) =>
      _$this._nbOffresEmises = nbOffresEmises;

  int? _seuilS;
  int? get seuilS => _$this._seuilS;
  set seuilS(int? seuilS) => _$this._seuilS = seuilS;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  EscaladeDispatchBuilder() {
    EscaladeDispatch._defaults(this);
  }

  EscaladeDispatchBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ageS = $v.ageS;
      _chemin = $v.chemin;
      _commandeId = $v.commandeId;
      _etat = $v.etat;
      _nbOffresEmises = $v.nbOffresEmises;
      _seuilS = $v.seuilS;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EscaladeDispatch other) {
    _$v = other as _$EscaladeDispatch;
  }

  @override
  void update(void Function(EscaladeDispatchBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EscaladeDispatch build() => _build();

  _$EscaladeDispatch _build() {
    final _$result = _$v ??
        _$EscaladeDispatch._(
          ageS: BuiltValueNullFieldError.checkNotNull(
              ageS, r'EscaladeDispatch', 'ageS'),
          chemin: BuiltValueNullFieldError.checkNotNull(
              chemin, r'EscaladeDispatch', 'chemin'),
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'EscaladeDispatch', 'commandeId'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'EscaladeDispatch', 'etat'),
          nbOffresEmises: BuiltValueNullFieldError.checkNotNull(
              nbOffresEmises, r'EscaladeDispatch', 'nbOffresEmises'),
          seuilS: BuiltValueNullFieldError.checkNotNull(
              seuilS, r'EscaladeDispatch', 'seuilS'),
          zoneId: BuiltValueNullFieldError.checkNotNull(
              zoneId, r'EscaladeDispatch', 'zoneId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
