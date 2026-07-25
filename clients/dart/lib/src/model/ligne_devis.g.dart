// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_devis.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneDevis extends LigneDevis {
  @override
  final String articleId;
  @override
  final String nom;
  @override
  final String preference;
  @override
  final int prixUnites;
  @override
  final int quantite;
  @override
  final int sousTotalUnites;

  factory _$LigneDevis([void Function(LigneDevisBuilder)? updates]) =>
      (LigneDevisBuilder()..update(updates))._build();

  _$LigneDevis._(
      {required this.articleId,
      required this.nom,
      required this.preference,
      required this.prixUnites,
      required this.quantite,
      required this.sousTotalUnites})
      : super._();
  @override
  LigneDevis rebuild(void Function(LigneDevisBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneDevisBuilder toBuilder() => LigneDevisBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneDevis &&
        articleId == other.articleId &&
        nom == other.nom &&
        preference == other.preference &&
        prixUnites == other.prixUnites &&
        quantite == other.quantite &&
        sousTotalUnites == other.sousTotalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, articleId.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, preference.hashCode);
    _$hash = $jc(_$hash, prixUnites.hashCode);
    _$hash = $jc(_$hash, quantite.hashCode);
    _$hash = $jc(_$hash, sousTotalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneDevis')
          ..add('articleId', articleId)
          ..add('nom', nom)
          ..add('preference', preference)
          ..add('prixUnites', prixUnites)
          ..add('quantite', quantite)
          ..add('sousTotalUnites', sousTotalUnites))
        .toString();
  }
}

class LigneDevisBuilder implements Builder<LigneDevis, LigneDevisBuilder> {
  _$LigneDevis? _$v;

  String? _articleId;
  String? get articleId => _$this._articleId;
  set articleId(String? articleId) => _$this._articleId = articleId;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  String? _preference;
  String? get preference => _$this._preference;
  set preference(String? preference) => _$this._preference = preference;

  int? _prixUnites;
  int? get prixUnites => _$this._prixUnites;
  set prixUnites(int? prixUnites) => _$this._prixUnites = prixUnites;

  int? _quantite;
  int? get quantite => _$this._quantite;
  set quantite(int? quantite) => _$this._quantite = quantite;

  int? _sousTotalUnites;
  int? get sousTotalUnites => _$this._sousTotalUnites;
  set sousTotalUnites(int? sousTotalUnites) =>
      _$this._sousTotalUnites = sousTotalUnites;

  LigneDevisBuilder() {
    LigneDevis._defaults(this);
  }

  LigneDevisBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _articleId = $v.articleId;
      _nom = $v.nom;
      _preference = $v.preference;
      _prixUnites = $v.prixUnites;
      _quantite = $v.quantite;
      _sousTotalUnites = $v.sousTotalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneDevis other) {
    _$v = other as _$LigneDevis;
  }

  @override
  void update(void Function(LigneDevisBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneDevis build() => _build();

  _$LigneDevis _build() {
    final _$result = _$v ??
        _$LigneDevis._(
          articleId: BuiltValueNullFieldError.checkNotNull(
              articleId, r'LigneDevis', 'articleId'),
          nom: BuiltValueNullFieldError.checkNotNull(nom, r'LigneDevis', 'nom'),
          preference: BuiltValueNullFieldError.checkNotNull(
              preference, r'LigneDevis', 'preference'),
          prixUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnites, r'LigneDevis', 'prixUnites'),
          quantite: BuiltValueNullFieldError.checkNotNull(
              quantite, r'LigneDevis', 'quantite'),
          sousTotalUnites: BuiltValueNullFieldError.checkNotNull(
              sousTotalUnites, r'LigneDevis', 'sousTotalUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
