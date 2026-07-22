// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'article_vendeur.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArticleVendeur extends ArticleVendeur {
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
  @override
  final bool retire;
  @override
  final bool ruptureAdmin;
  @override
  final SourceBascule? sourceDerniereBascule;

  factory _$ArticleVendeur([void Function(ArticleVendeurBuilder)? updates]) =>
      (ArticleVendeurBuilder()..update(updates))._build();

  _$ArticleVendeur._(
      {this.categorieInterne,
      required this.devise,
      required this.disponible,
      required this.id,
      required this.nom,
      this.photoUrl,
      this.prixBarreUnites,
      required this.prixUnites,
      required this.retire,
      required this.ruptureAdmin,
      this.sourceDerniereBascule})
      : super._();
  @override
  ArticleVendeur rebuild(void Function(ArticleVendeurBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArticleVendeurBuilder toBuilder() => ArticleVendeurBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArticleVendeur &&
        categorieInterne == other.categorieInterne &&
        devise == other.devise &&
        disponible == other.disponible &&
        id == other.id &&
        nom == other.nom &&
        photoUrl == other.photoUrl &&
        prixBarreUnites == other.prixBarreUnites &&
        prixUnites == other.prixUnites &&
        retire == other.retire &&
        ruptureAdmin == other.ruptureAdmin &&
        sourceDerniereBascule == other.sourceDerniereBascule;
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
    _$hash = $jc(_$hash, retire.hashCode);
    _$hash = $jc(_$hash, ruptureAdmin.hashCode);
    _$hash = $jc(_$hash, sourceDerniereBascule.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArticleVendeur')
          ..add('categorieInterne', categorieInterne)
          ..add('devise', devise)
          ..add('disponible', disponible)
          ..add('id', id)
          ..add('nom', nom)
          ..add('photoUrl', photoUrl)
          ..add('prixBarreUnites', prixBarreUnites)
          ..add('prixUnites', prixUnites)
          ..add('retire', retire)
          ..add('ruptureAdmin', ruptureAdmin)
          ..add('sourceDerniereBascule', sourceDerniereBascule))
        .toString();
  }
}

class ArticleVendeurBuilder
    implements Builder<ArticleVendeur, ArticleVendeurBuilder> {
  _$ArticleVendeur? _$v;

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

  bool? _retire;
  bool? get retire => _$this._retire;
  set retire(bool? retire) => _$this._retire = retire;

  bool? _ruptureAdmin;
  bool? get ruptureAdmin => _$this._ruptureAdmin;
  set ruptureAdmin(bool? ruptureAdmin) => _$this._ruptureAdmin = ruptureAdmin;

  SourceBascule? _sourceDerniereBascule;
  SourceBascule? get sourceDerniereBascule => _$this._sourceDerniereBascule;
  set sourceDerniereBascule(SourceBascule? sourceDerniereBascule) =>
      _$this._sourceDerniereBascule = sourceDerniereBascule;

  ArticleVendeurBuilder() {
    ArticleVendeur._defaults(this);
  }

  ArticleVendeurBuilder get _$this {
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
      _retire = $v.retire;
      _ruptureAdmin = $v.ruptureAdmin;
      _sourceDerniereBascule = $v.sourceDerniereBascule;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArticleVendeur other) {
    _$v = other as _$ArticleVendeur;
  }

  @override
  void update(void Function(ArticleVendeurBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArticleVendeur build() => _build();

  _$ArticleVendeur _build() {
    final _$result = _$v ??
        _$ArticleVendeur._(
          categorieInterne: categorieInterne,
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'ArticleVendeur', 'devise'),
          disponible: BuiltValueNullFieldError.checkNotNull(
              disponible, r'ArticleVendeur', 'disponible'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'ArticleVendeur', 'id'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'ArticleVendeur', 'nom'),
          photoUrl: photoUrl,
          prixBarreUnites: prixBarreUnites,
          prixUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnites, r'ArticleVendeur', 'prixUnites'),
          retire: BuiltValueNullFieldError.checkNotNull(
              retire, r'ArticleVendeur', 'retire'),
          ruptureAdmin: BuiltValueNullFieldError.checkNotNull(
              ruptureAdmin, r'ArticleVendeur', 'ruptureAdmin'),
          sourceDerniereBascule: sourceDerniereBascule,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
