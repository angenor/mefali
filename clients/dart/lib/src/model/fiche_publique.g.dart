// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fiche_publique.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$FichePublique extends FichePublique {
  @override
  final AffichageRupture affichageRupture;
  @override
  final BuiltList<ArticlePublic> articles;
  @override
  final EtatEffectifBoutique boutique;
  @override
  final String categorie;
  @override
  final bool commandable;
  @override
  final int delaiPreparationMin;
  @override
  final HorairesSemaineDto horaires;
  @override
  final String id;
  @override
  final String nom;
  @override
  final BuiltList<String> photos;

  factory _$FichePublique([void Function(FichePubliqueBuilder)? updates]) =>
      (FichePubliqueBuilder()..update(updates))._build();

  _$FichePublique._(
      {required this.affichageRupture,
      required this.articles,
      required this.boutique,
      required this.categorie,
      required this.commandable,
      required this.delaiPreparationMin,
      required this.horaires,
      required this.id,
      required this.nom,
      required this.photos})
      : super._();
  @override
  FichePublique rebuild(void Function(FichePubliqueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  FichePubliqueBuilder toBuilder() => FichePubliqueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is FichePublique &&
        affichageRupture == other.affichageRupture &&
        articles == other.articles &&
        boutique == other.boutique &&
        categorie == other.categorie &&
        commandable == other.commandable &&
        delaiPreparationMin == other.delaiPreparationMin &&
        horaires == other.horaires &&
        id == other.id &&
        nom == other.nom &&
        photos == other.photos;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, affichageRupture.hashCode);
    _$hash = $jc(_$hash, articles.hashCode);
    _$hash = $jc(_$hash, boutique.hashCode);
    _$hash = $jc(_$hash, categorie.hashCode);
    _$hash = $jc(_$hash, commandable.hashCode);
    _$hash = $jc(_$hash, delaiPreparationMin.hashCode);
    _$hash = $jc(_$hash, horaires.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, photos.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'FichePublique')
          ..add('affichageRupture', affichageRupture)
          ..add('articles', articles)
          ..add('boutique', boutique)
          ..add('categorie', categorie)
          ..add('commandable', commandable)
          ..add('delaiPreparationMin', delaiPreparationMin)
          ..add('horaires', horaires)
          ..add('id', id)
          ..add('nom', nom)
          ..add('photos', photos))
        .toString();
  }
}

class FichePubliqueBuilder
    implements Builder<FichePublique, FichePubliqueBuilder> {
  _$FichePublique? _$v;

  AffichageRupture? _affichageRupture;
  AffichageRupture? get affichageRupture => _$this._affichageRupture;
  set affichageRupture(AffichageRupture? affichageRupture) =>
      _$this._affichageRupture = affichageRupture;

  ListBuilder<ArticlePublic>? _articles;
  ListBuilder<ArticlePublic> get articles =>
      _$this._articles ??= ListBuilder<ArticlePublic>();
  set articles(ListBuilder<ArticlePublic>? articles) =>
      _$this._articles = articles;

  EtatEffectifBoutiqueBuilder? _boutique;
  EtatEffectifBoutiqueBuilder get boutique =>
      _$this._boutique ??= EtatEffectifBoutiqueBuilder();
  set boutique(EtatEffectifBoutiqueBuilder? boutique) =>
      _$this._boutique = boutique;

  String? _categorie;
  String? get categorie => _$this._categorie;
  set categorie(String? categorie) => _$this._categorie = categorie;

  bool? _commandable;
  bool? get commandable => _$this._commandable;
  set commandable(bool? commandable) => _$this._commandable = commandable;

  int? _delaiPreparationMin;
  int? get delaiPreparationMin => _$this._delaiPreparationMin;
  set delaiPreparationMin(int? delaiPreparationMin) =>
      _$this._delaiPreparationMin = delaiPreparationMin;

  HorairesSemaineDtoBuilder? _horaires;
  HorairesSemaineDtoBuilder get horaires =>
      _$this._horaires ??= HorairesSemaineDtoBuilder();
  set horaires(HorairesSemaineDtoBuilder? horaires) =>
      _$this._horaires = horaires;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  ListBuilder<String>? _photos;
  ListBuilder<String> get photos => _$this._photos ??= ListBuilder<String>();
  set photos(ListBuilder<String>? photos) => _$this._photos = photos;

  FichePubliqueBuilder() {
    FichePublique._defaults(this);
  }

  FichePubliqueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _affichageRupture = $v.affichageRupture;
      _articles = $v.articles.toBuilder();
      _boutique = $v.boutique.toBuilder();
      _categorie = $v.categorie;
      _commandable = $v.commandable;
      _delaiPreparationMin = $v.delaiPreparationMin;
      _horaires = $v.horaires.toBuilder();
      _id = $v.id;
      _nom = $v.nom;
      _photos = $v.photos.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(FichePublique other) {
    _$v = other as _$FichePublique;
  }

  @override
  void update(void Function(FichePubliqueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  FichePublique build() => _build();

  _$FichePublique _build() {
    _$FichePublique _$result;
    try {
      _$result = _$v ??
          _$FichePublique._(
            affichageRupture: BuiltValueNullFieldError.checkNotNull(
                affichageRupture, r'FichePublique', 'affichageRupture'),
            articles: articles.build(),
            boutique: boutique.build(),
            categorie: BuiltValueNullFieldError.checkNotNull(
                categorie, r'FichePublique', 'categorie'),
            commandable: BuiltValueNullFieldError.checkNotNull(
                commandable, r'FichePublique', 'commandable'),
            delaiPreparationMin: BuiltValueNullFieldError.checkNotNull(
                delaiPreparationMin, r'FichePublique', 'delaiPreparationMin'),
            horaires: horaires.build(),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'FichePublique', 'id'),
            nom: BuiltValueNullFieldError.checkNotNull(
                nom, r'FichePublique', 'nom'),
            photos: photos.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'articles';
        articles.build();
        _$failedField = 'boutique';
        boutique.build();

        _$failedField = 'horaires';
        horaires.build();

        _$failedField = 'photos';
        photos.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'FichePublique', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
