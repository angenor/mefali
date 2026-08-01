// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recu_arret.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecuArret extends RecuArret {
  @override
  final String arretId;
  @override
  final DateTime? collecteLe;
  @override
  final String devise;
  @override
  final BuiltList<LigneRecu> lignes;
  @override
  final int montantArticlesUnites;
  @override
  final String? motifRetenueCle;
  @override
  final int netVerseUnites;
  @override
  final String prestataireId;
  @override
  final int retenueLivraisonOfferteUnites;

  factory _$RecuArret([void Function(RecuArretBuilder)? updates]) =>
      (RecuArretBuilder()..update(updates))._build();

  _$RecuArret._(
      {required this.arretId,
      this.collecteLe,
      required this.devise,
      required this.lignes,
      required this.montantArticlesUnites,
      this.motifRetenueCle,
      required this.netVerseUnites,
      required this.prestataireId,
      required this.retenueLivraisonOfferteUnites})
      : super._();
  @override
  RecuArret rebuild(void Function(RecuArretBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecuArretBuilder toBuilder() => RecuArretBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecuArret &&
        arretId == other.arretId &&
        collecteLe == other.collecteLe &&
        devise == other.devise &&
        lignes == other.lignes &&
        montantArticlesUnites == other.montantArticlesUnites &&
        motifRetenueCle == other.motifRetenueCle &&
        netVerseUnites == other.netVerseUnites &&
        prestataireId == other.prestataireId &&
        retenueLivraisonOfferteUnites == other.retenueLivraisonOfferteUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, collecteLe.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, motifRetenueCle.hashCode);
    _$hash = $jc(_$hash, netVerseUnites.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, retenueLivraisonOfferteUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecuArret')
          ..add('arretId', arretId)
          ..add('collecteLe', collecteLe)
          ..add('devise', devise)
          ..add('lignes', lignes)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('motifRetenueCle', motifRetenueCle)
          ..add('netVerseUnites', netVerseUnites)
          ..add('prestataireId', prestataireId)
          ..add('retenueLivraisonOfferteUnites', retenueLivraisonOfferteUnites))
        .toString();
  }
}

class RecuArretBuilder implements Builder<RecuArret, RecuArretBuilder> {
  _$RecuArret? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  DateTime? _collecteLe;
  DateTime? get collecteLe => _$this._collecteLe;
  set collecteLe(DateTime? collecteLe) => _$this._collecteLe = collecteLe;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  ListBuilder<LigneRecu>? _lignes;
  ListBuilder<LigneRecu> get lignes =>
      _$this._lignes ??= ListBuilder<LigneRecu>();
  set lignes(ListBuilder<LigneRecu>? lignes) => _$this._lignes = lignes;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  String? _motifRetenueCle;
  String? get motifRetenueCle => _$this._motifRetenueCle;
  set motifRetenueCle(String? motifRetenueCle) =>
      _$this._motifRetenueCle = motifRetenueCle;

  int? _netVerseUnites;
  int? get netVerseUnites => _$this._netVerseUnites;
  set netVerseUnites(int? netVerseUnites) =>
      _$this._netVerseUnites = netVerseUnites;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  int? _retenueLivraisonOfferteUnites;
  int? get retenueLivraisonOfferteUnites =>
      _$this._retenueLivraisonOfferteUnites;
  set retenueLivraisonOfferteUnites(int? retenueLivraisonOfferteUnites) =>
      _$this._retenueLivraisonOfferteUnites = retenueLivraisonOfferteUnites;

  RecuArretBuilder() {
    RecuArret._defaults(this);
  }

  RecuArretBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _collecteLe = $v.collecteLe;
      _devise = $v.devise;
      _lignes = $v.lignes.toBuilder();
      _montantArticlesUnites = $v.montantArticlesUnites;
      _motifRetenueCle = $v.motifRetenueCle;
      _netVerseUnites = $v.netVerseUnites;
      _prestataireId = $v.prestataireId;
      _retenueLivraisonOfferteUnites = $v.retenueLivraisonOfferteUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecuArret other) {
    _$v = other as _$RecuArret;
  }

  @override
  void update(void Function(RecuArretBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecuArret build() => _build();

  _$RecuArret _build() {
    _$RecuArret _$result;
    try {
      _$result = _$v ??
          _$RecuArret._(
            arretId: BuiltValueNullFieldError.checkNotNull(
                arretId, r'RecuArret', 'arretId'),
            collecteLe: collecteLe,
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'RecuArret', 'devise'),
            lignes: lignes.build(),
            montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                montantArticlesUnites, r'RecuArret', 'montantArticlesUnites'),
            motifRetenueCle: motifRetenueCle,
            netVerseUnites: BuiltValueNullFieldError.checkNotNull(
                netVerseUnites, r'RecuArret', 'netVerseUnites'),
            prestataireId: BuiltValueNullFieldError.checkNotNull(
                prestataireId, r'RecuArret', 'prestataireId'),
            retenueLivraisonOfferteUnites:
                BuiltValueNullFieldError.checkNotNull(
                    retenueLivraisonOfferteUnites,
                    r'RecuArret',
                    'retenueLivraisonOfferteUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RecuArret', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
