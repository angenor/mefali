// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_public.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArticlePublic extends ArticlePublic {
  @override
  final String? categorieInterne;
  @override
  final String devise;
  @override
  final bool disponible;
  @override
  final String id;
  @override
  final String nom;
  @override
  final String? photoUrl;
  @override
  final int? prixBarreUnites;
  @override
  final int prixUnites;

  factory _$ArticlePublic([void Function(ArticlePublicBuilder)? updates]) =>
      (ArticlePublicBuilder()..update(updates))._build();

  _$ArticlePublic._(
      {this.categorieInterne,
      required this.devise,
      required this.disponible,
      required this.id,
      required this.nom,
      this.photoUrl,
      this.prixBarreUnites,
      required this.prixUnites})
      : super._();
  @override
  ArticlePublic rebuild(void Function(ArticlePublicBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArticlePublicBuilder toBuilder() => ArticlePublicBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArticlePublic &&
        categorieInterne == other.categorieInterne &&
        devise == other.devise &&
        disponible == other.disponible &&
        id == other.id &&
        nom == other.nom &&
        photoUrl == other.photoUrl &&
        prixBarreUnites == other.prixBarreUnites &&
        prixUnites == other.prixUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieInterne.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, disponible.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, photoUrl.hashCode);
    _$hash = $jc(_$hash, prixBarreUnites.hashCode);
    _$hash = $jc(_$hash, prixUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArticlePublic')
          ..add('categorieInterne', categorieInterne)
          ..add('devise', devise)
          ..add('disponible', disponible)
          ..add('id', id)
          ..add('nom', nom)
          ..add('photoUrl', photoUrl)
          ..add('prixBarreUnites', prixBarreUnites)
          ..add('prixUnites', prixUnites))
        .toString();
  }
}

class ArticlePublicBuilder
    implements Builder<ArticlePublic, ArticlePublicBuilder> {
  _$ArticlePublic? _$v;

  String? _categorieInterne;
  String? get categorieInterne => _$this._categorieInterne;
  set categorieInterne(String? categorieInterne) =>
      _$this._categorieInterne = categorieInterne;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  bool? _disponible;
  bool? get disponible => _$this._disponible;
  set disponible(bool? disponible) => _$this._disponible = disponible;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  String? _photoUrl;
  String? get photoUrl => _$this._photoUrl;
  set photoUrl(String? photoUrl) => _$this._photoUrl = photoUrl;

  int? _prixBarreUnites;
  int? get prixBarreUnites => _$this._prixBarreUnites;
  set prixBarreUnites(int? prixBarreUnites) =>
      _$this._prixBarreUnites = prixBarreUnites;

  int? _prixUnites;
  int? get prixUnites => _$this._prixUnites;
  set prixUnites(int? prixUnites) => _$this._prixUnites = prixUnites;

  ArticlePublicBuilder() {
    ArticlePublic._defaults(this);
  }

  ArticlePublicBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieInterne = $v.categorieInterne;
      _devise = $v.devise;
      _disponible = $v.disponible;
      _id = $v.id;
      _nom = $v.nom;
      _photoUrl = $v.photoUrl;
      _prixBarreUnites = $v.prixBarreUnites;
      _prixUnites = $v.prixUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArticlePublic other) {
    _$v = other as _$ArticlePublic;
  }

  @override
  void update(void Function(ArticlePublicBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArticlePublic build() => _build();

  _$ArticlePublic _build() {
    final _$result = _$v ??
        _$ArticlePublic._(
          categorieInterne: categorieInterne,
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'ArticlePublic', 'devise'),
          disponible: BuiltValueNullFieldError.checkNotNull(
              disponible, r'ArticlePublic', 'disponible'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'ArticlePublic', 'id'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'ArticlePublic', 'nom'),
          photoUrl: photoUrl,
          prixBarreUnites: prixBarreUnites,
          prixUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnites, r'ArticlePublic', 'prixUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
