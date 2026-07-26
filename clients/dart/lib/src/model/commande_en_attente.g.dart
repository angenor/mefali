// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande_en_attente.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CommandeEnAttente extends CommandeEnAttente {
  @override
  final int ageS;
  @override
  final String commandeId;
  @override
  final String devise;
  @override
  final int montantAAvancer;
  @override
  final int nbCollectes;
  @override
  final double? premiereCollecteLat;
  @override
  final double? premiereCollecteLon;
  @override
  final String zoneId;

  factory _$CommandeEnAttente(
          [void Function(CommandeEnAttenteBuilder)? updates]) =>
      (CommandeEnAttenteBuilder()..update(updates))._build();

  _$CommandeEnAttente._(
      {required this.ageS,
      required this.commandeId,
      required this.devise,
      required this.montantAAvancer,
      required this.nbCollectes,
      this.premiereCollecteLat,
      this.premiereCollecteLon,
      required this.zoneId})
      : super._();
  @override
  CommandeEnAttente rebuild(void Function(CommandeEnAttenteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandeEnAttenteBuilder toBuilder() =>
      CommandeEnAttenteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandeEnAttente &&
        ageS == other.ageS &&
        commandeId == other.commandeId &&
        devise == other.devise &&
        montantAAvancer == other.montantAAvancer &&
        nbCollectes == other.nbCollectes &&
        premiereCollecteLat == other.premiereCollecteLat &&
        premiereCollecteLon == other.premiereCollecteLon &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ageS.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, montantAAvancer.hashCode);
    _$hash = $jc(_$hash, nbCollectes.hashCode);
    _$hash = $jc(_$hash, premiereCollecteLat.hashCode);
    _$hash = $jc(_$hash, premiereCollecteLon.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CommandeEnAttente')
          ..add('ageS', ageS)
          ..add('commandeId', commandeId)
          ..add('devise', devise)
          ..add('montantAAvancer', montantAAvancer)
          ..add('nbCollectes', nbCollectes)
          ..add('premiereCollecteLat', premiereCollecteLat)
          ..add('premiereCollecteLon', premiereCollecteLon)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class CommandeEnAttenteBuilder
    implements Builder<CommandeEnAttente, CommandeEnAttenteBuilder> {
  _$CommandeEnAttente? _$v;

  int? _ageS;
  int? get ageS => _$this._ageS;
  set ageS(int? ageS) => _$this._ageS = ageS;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _montantAAvancer;
  int? get montantAAvancer => _$this._montantAAvancer;
  set montantAAvancer(int? montantAAvancer) =>
      _$this._montantAAvancer = montantAAvancer;

  int? _nbCollectes;
  int? get nbCollectes => _$this._nbCollectes;
  set nbCollectes(int? nbCollectes) => _$this._nbCollectes = nbCollectes;

  double? _premiereCollecteLat;
  double? get premiereCollecteLat => _$this._premiereCollecteLat;
  set premiereCollecteLat(double? premiereCollecteLat) =>
      _$this._premiereCollecteLat = premiereCollecteLat;

  double? _premiereCollecteLon;
  double? get premiereCollecteLon => _$this._premiereCollecteLon;
  set premiereCollecteLon(double? premiereCollecteLon) =>
      _$this._premiereCollecteLon = premiereCollecteLon;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  CommandeEnAttenteBuilder() {
    CommandeEnAttente._defaults(this);
  }

  CommandeEnAttenteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ageS = $v.ageS;
      _commandeId = $v.commandeId;
      _devise = $v.devise;
      _montantAAvancer = $v.montantAAvancer;
      _nbCollectes = $v.nbCollectes;
      _premiereCollecteLat = $v.premiereCollecteLat;
      _premiereCollecteLon = $v.premiereCollecteLon;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandeEnAttente other) {
    _$v = other as _$CommandeEnAttente;
  }

  @override
  void update(void Function(CommandeEnAttenteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CommandeEnAttente build() => _build();

  _$CommandeEnAttente _build() {
    final _$result = _$v ??
        _$CommandeEnAttente._(
          ageS: BuiltValueNullFieldError.checkNotNull(
              ageS, r'CommandeEnAttente', 'ageS'),
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'CommandeEnAttente', 'commandeId'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'CommandeEnAttente', 'devise'),
          montantAAvancer: BuiltValueNullFieldError.checkNotNull(
              montantAAvancer, r'CommandeEnAttente', 'montantAAvancer'),
          nbCollectes: BuiltValueNullFieldError.checkNotNull(
              nbCollectes, r'CommandeEnAttente', 'nbCollectes'),
          premiereCollecteLat: premiereCollecteLat,
          premiereCollecteLon: premiereCollecteLon,
          zoneId: BuiltValueNullFieldError.checkNotNull(
              zoneId, r'CommandeEnAttente', 'zoneId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
