// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devis_panier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DevisPanier extends DevisPanier {
  @override
  final DevisLivraison devis;
  @override
  final String devise;
  @override
  final BuiltList<GroupeVendeur> groupes;
  @override
  final int montantArticlesUnites;
  @override
  final PaiementPanier paiement;
  @override
  final ScissionProposee? scission;
  @override
  final int totalUnites;

  factory _$DevisPanier([void Function(DevisPanierBuilder)? updates]) =>
      (DevisPanierBuilder()..update(updates))._build();

  _$DevisPanier._(
      {required this.devis,
      required this.devise,
      required this.groupes,
      required this.montantArticlesUnites,
      required this.paiement,
      this.scission,
      required this.totalUnites})
      : super._();
  @override
  DevisPanier rebuild(void Function(DevisPanierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DevisPanierBuilder toBuilder() => DevisPanierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DevisPanier &&
        devis == other.devis &&
        devise == other.devise &&
        groupes == other.groupes &&
        montantArticlesUnites == other.montantArticlesUnites &&
        paiement == other.paiement &&
        scission == other.scission &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, devis.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, groupes.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, paiement.hashCode);
    _$hash = $jc(_$hash, scission.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DevisPanier')
          ..add('devis', devis)
          ..add('devise', devise)
          ..add('groupes', groupes)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('paiement', paiement)
          ..add('scission', scission)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class DevisPanierBuilder implements Builder<DevisPanier, DevisPanierBuilder> {
  _$DevisPanier? _$v;

  DevisLivraisonBuilder? _devis;
  DevisLivraisonBuilder get devis => _$this._devis ??= DevisLivraisonBuilder();
  set devis(DevisLivraisonBuilder? devis) => _$this._devis = devis;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  ListBuilder<GroupeVendeur>? _groupes;
  ListBuilder<GroupeVendeur> get groupes =>
      _$this._groupes ??= ListBuilder<GroupeVendeur>();
  set groupes(ListBuilder<GroupeVendeur>? groupes) => _$this._groupes = groupes;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  PaiementPanierBuilder? _paiement;
  PaiementPanierBuilder get paiement =>
      _$this._paiement ??= PaiementPanierBuilder();
  set paiement(PaiementPanierBuilder? paiement) => _$this._paiement = paiement;

  ScissionProposeeBuilder? _scission;
  ScissionProposeeBuilder get scission =>
      _$this._scission ??= ScissionProposeeBuilder();
  set scission(ScissionProposeeBuilder? scission) =>
      _$this._scission = scission;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  DevisPanierBuilder() {
    DevisPanier._defaults(this);
  }

  DevisPanierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _devis = $v.devis.toBuilder();
      _devise = $v.devise;
      _groupes = $v.groupes.toBuilder();
      _montantArticlesUnites = $v.montantArticlesUnites;
      _paiement = $v.paiement.toBuilder();
      _scission = $v.scission?.toBuilder();
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DevisPanier other) {
    _$v = other as _$DevisPanier;
  }

  @override
  void update(void Function(DevisPanierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DevisPanier build() => _build();

  _$DevisPanier _build() {
    _$DevisPanier _$result;
    try {
      _$result = _$v ??
          _$DevisPanier._(
            devis: devis.build(),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'DevisPanier', 'devise'),
            groupes: groupes.build(),
            montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                montantArticlesUnites, r'DevisPanier', 'montantArticlesUnites'),
            paiement: paiement.build(),
            scission: _scission?.build(),
            totalUnites: BuiltValueNullFieldError.checkNotNull(
                totalUnites, r'DevisPanier', 'totalUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'devis';
        devis.build();

        _$failedField = 'groupes';
        groupes.build();

        _$failedField = 'paiement';
        paiement.build();
        _$failedField = 'scission';
        _scission?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DevisPanier', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
