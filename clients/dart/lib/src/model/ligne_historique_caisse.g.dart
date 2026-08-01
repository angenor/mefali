// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_historique_caisse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneHistoriqueCaisse extends LigneHistoriqueCaisse {
  @override
  final int avanceUnites;
  @override
  final String commandeId;
  @override
  final bool enAttenteReglement;
  @override
  final int gainUnites;
  @override
  final DateTime heure;
  @override
  final String? livraisonId;
  @override
  final String reference;
  @override
  final int rembourseUnites;
  @override
  final bool terminee;

  factory _$LigneHistoriqueCaisse(
          [void Function(LigneHistoriqueCaisseBuilder)? updates]) =>
      (LigneHistoriqueCaisseBuilder()..update(updates))._build();

  _$LigneHistoriqueCaisse._(
      {required this.avanceUnites,
      required this.commandeId,
      required this.enAttenteReglement,
      required this.gainUnites,
      required this.heure,
      this.livraisonId,
      required this.reference,
      required this.rembourseUnites,
      required this.terminee})
      : super._();
  @override
  LigneHistoriqueCaisse rebuild(
          void Function(LigneHistoriqueCaisseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneHistoriqueCaisseBuilder toBuilder() =>
      LigneHistoriqueCaisseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneHistoriqueCaisse &&
        avanceUnites == other.avanceUnites &&
        commandeId == other.commandeId &&
        enAttenteReglement == other.enAttenteReglement &&
        gainUnites == other.gainUnites &&
        heure == other.heure &&
        livraisonId == other.livraisonId &&
        reference == other.reference &&
        rembourseUnites == other.rembourseUnites &&
        terminee == other.terminee;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, avanceUnites.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, enAttenteReglement.hashCode);
    _$hash = $jc(_$hash, gainUnites.hashCode);
    _$hash = $jc(_$hash, heure.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, reference.hashCode);
    _$hash = $jc(_$hash, rembourseUnites.hashCode);
    _$hash = $jc(_$hash, terminee.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneHistoriqueCaisse')
          ..add('avanceUnites', avanceUnites)
          ..add('commandeId', commandeId)
          ..add('enAttenteReglement', enAttenteReglement)
          ..add('gainUnites', gainUnites)
          ..add('heure', heure)
          ..add('livraisonId', livraisonId)
          ..add('reference', reference)
          ..add('rembourseUnites', rembourseUnites)
          ..add('terminee', terminee))
        .toString();
  }
}

class LigneHistoriqueCaisseBuilder
    implements Builder<LigneHistoriqueCaisse, LigneHistoriqueCaisseBuilder> {
  _$LigneHistoriqueCaisse? _$v;

  int? _avanceUnites;
  int? get avanceUnites => _$this._avanceUnites;
  set avanceUnites(int? avanceUnites) => _$this._avanceUnites = avanceUnites;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _enAttenteReglement;
  bool? get enAttenteReglement => _$this._enAttenteReglement;
  set enAttenteReglement(bool? enAttenteReglement) =>
      _$this._enAttenteReglement = enAttenteReglement;

  int? _gainUnites;
  int? get gainUnites => _$this._gainUnites;
  set gainUnites(int? gainUnites) => _$this._gainUnites = gainUnites;

  DateTime? _heure;
  DateTime? get heure => _$this._heure;
  set heure(DateTime? heure) => _$this._heure = heure;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  String? _reference;
  String? get reference => _$this._reference;
  set reference(String? reference) => _$this._reference = reference;

  int? _rembourseUnites;
  int? get rembourseUnites => _$this._rembourseUnites;
  set rembourseUnites(int? rembourseUnites) =>
      _$this._rembourseUnites = rembourseUnites;

  bool? _terminee;
  bool? get terminee => _$this._terminee;
  set terminee(bool? terminee) => _$this._terminee = terminee;

  LigneHistoriqueCaisseBuilder() {
    LigneHistoriqueCaisse._defaults(this);
  }

  LigneHistoriqueCaisseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _avanceUnites = $v.avanceUnites;
      _commandeId = $v.commandeId;
      _enAttenteReglement = $v.enAttenteReglement;
      _gainUnites = $v.gainUnites;
      _heure = $v.heure;
      _livraisonId = $v.livraisonId;
      _reference = $v.reference;
      _rembourseUnites = $v.rembourseUnites;
      _terminee = $v.terminee;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneHistoriqueCaisse other) {
    _$v = other as _$LigneHistoriqueCaisse;
  }

  @override
  void update(void Function(LigneHistoriqueCaisseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneHistoriqueCaisse build() => _build();

  _$LigneHistoriqueCaisse _build() {
    final _$result = _$v ??
        _$LigneHistoriqueCaisse._(
          avanceUnites: BuiltValueNullFieldError.checkNotNull(
              avanceUnites, r'LigneHistoriqueCaisse', 'avanceUnites'),
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'LigneHistoriqueCaisse', 'commandeId'),
          enAttenteReglement: BuiltValueNullFieldError.checkNotNull(
              enAttenteReglement,
              r'LigneHistoriqueCaisse',
              'enAttenteReglement'),
          gainUnites: BuiltValueNullFieldError.checkNotNull(
              gainUnites, r'LigneHistoriqueCaisse', 'gainUnites'),
          heure: BuiltValueNullFieldError.checkNotNull(
              heure, r'LigneHistoriqueCaisse', 'heure'),
          livraisonId: livraisonId,
          reference: BuiltValueNullFieldError.checkNotNull(
              reference, r'LigneHistoriqueCaisse', 'reference'),
          rembourseUnites: BuiltValueNullFieldError.checkNotNull(
              rembourseUnites, r'LigneHistoriqueCaisse', 'rembourseUnites'),
          terminee: BuiltValueNullFieldError.checkNotNull(
              terminee, r'LigneHistoriqueCaisse', 'terminee'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
