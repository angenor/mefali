// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_registre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneRegistre extends LigneRegistre {
  @override
  final String commandeId;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String fournisseur;
  @override
  final String id;
  @override
  final DateTime? issueLe;
  @override
  final int montantUnites;
  @override
  final String moyen;
  @override
  final bool orpheline;
  @override
  final DateTime ouverteLe;
  @override
  final String? referenceFournisseur;

  factory _$LigneRegistre([void Function(LigneRegistreBuilder)? updates]) =>
      (LigneRegistreBuilder()..update(updates))._build();

  _$LigneRegistre._(
      {required this.commandeId,
      required this.devise,
      required this.etat,
      required this.fournisseur,
      required this.id,
      this.issueLe,
      required this.montantUnites,
      required this.moyen,
      required this.orpheline,
      required this.ouverteLe,
      this.referenceFournisseur})
      : super._();
  @override
  LigneRegistre rebuild(void Function(LigneRegistreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneRegistreBuilder toBuilder() => LigneRegistreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneRegistre &&
        commandeId == other.commandeId &&
        devise == other.devise &&
        etat == other.etat &&
        fournisseur == other.fournisseur &&
        id == other.id &&
        issueLe == other.issueLe &&
        montantUnites == other.montantUnites &&
        moyen == other.moyen &&
        orpheline == other.orpheline &&
        ouverteLe == other.ouverteLe &&
        referenceFournisseur == other.referenceFournisseur;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, fournisseur.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, issueLe.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, moyen.hashCode);
    _$hash = $jc(_$hash, orpheline.hashCode);
    _$hash = $jc(_$hash, ouverteLe.hashCode);
    _$hash = $jc(_$hash, referenceFournisseur.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneRegistre')
          ..add('commandeId', commandeId)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('fournisseur', fournisseur)
          ..add('id', id)
          ..add('issueLe', issueLe)
          ..add('montantUnites', montantUnites)
          ..add('moyen', moyen)
          ..add('orpheline', orpheline)
          ..add('ouverteLe', ouverteLe)
          ..add('referenceFournisseur', referenceFournisseur))
        .toString();
  }
}

class LigneRegistreBuilder
    implements Builder<LigneRegistre, LigneRegistreBuilder> {
  _$LigneRegistre? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _fournisseur;
  String? get fournisseur => _$this._fournisseur;
  set fournisseur(String? fournisseur) => _$this._fournisseur = fournisseur;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _issueLe;
  DateTime? get issueLe => _$this._issueLe;
  set issueLe(DateTime? issueLe) => _$this._issueLe = issueLe;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  String? _moyen;
  String? get moyen => _$this._moyen;
  set moyen(String? moyen) => _$this._moyen = moyen;

  bool? _orpheline;
  bool? get orpheline => _$this._orpheline;
  set orpheline(bool? orpheline) => _$this._orpheline = orpheline;

  DateTime? _ouverteLe;
  DateTime? get ouverteLe => _$this._ouverteLe;
  set ouverteLe(DateTime? ouverteLe) => _$this._ouverteLe = ouverteLe;

  String? _referenceFournisseur;
  String? get referenceFournisseur => _$this._referenceFournisseur;
  set referenceFournisseur(String? referenceFournisseur) =>
      _$this._referenceFournisseur = referenceFournisseur;

  LigneRegistreBuilder() {
    LigneRegistre._defaults(this);
  }

  LigneRegistreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _devise = $v.devise;
      _etat = $v.etat;
      _fournisseur = $v.fournisseur;
      _id = $v.id;
      _issueLe = $v.issueLe;
      _montantUnites = $v.montantUnites;
      _moyen = $v.moyen;
      _orpheline = $v.orpheline;
      _ouverteLe = $v.ouverteLe;
      _referenceFournisseur = $v.referenceFournisseur;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneRegistre other) {
    _$v = other as _$LigneRegistre;
  }

  @override
  void update(void Function(LigneRegistreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneRegistre build() => _build();

  _$LigneRegistre _build() {
    final _$result = _$v ??
        _$LigneRegistre._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'LigneRegistre', 'commandeId'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'LigneRegistre', 'devise'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'LigneRegistre', 'etat'),
          fournisseur: BuiltValueNullFieldError.checkNotNull(
              fournisseur, r'LigneRegistre', 'fournisseur'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'LigneRegistre', 'id'),
          issueLe: issueLe,
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'LigneRegistre', 'montantUnites'),
          moyen: BuiltValueNullFieldError.checkNotNull(
              moyen, r'LigneRegistre', 'moyen'),
          orpheline: BuiltValueNullFieldError.checkNotNull(
              orpheline, r'LigneRegistre', 'orpheline'),
          ouverteLe: BuiltValueNullFieldError.checkNotNull(
              ouverteLe, r'LigneRegistre', 'ouverteLe'),
          referenceFournisseur: referenceFournisseur,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
