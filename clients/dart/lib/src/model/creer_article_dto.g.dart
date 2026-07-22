// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creer_article_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreerArticleDto extends CreerArticleDto {
  @override
  final String? categorieInterne;
  @override
  final String nom;
  @override
  final int? prixBarreUnites;
  @override
  final int prixUnites;

  factory _$CreerArticleDto([void Function(CreerArticleDtoBuilder)? updates]) =>
      (CreerArticleDtoBuilder()..update(updates))._build();

  _$CreerArticleDto._(
      {this.categorieInterne,
      required this.nom,
      this.prixBarreUnites,
      required this.prixUnites})
      : super._();
  @override
  CreerArticleDto rebuild(void Function(CreerArticleDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreerArticleDtoBuilder toBuilder() => CreerArticleDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreerArticleDto &&
        categorieInterne == other.categorieInterne &&
        nom == other.nom &&
        prixBarreUnites == other.prixBarreUnites &&
        prixUnites == other.prixUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieInterne.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, prixBarreUnites.hashCode);
    _$hash = $jc(_$hash, prixUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreerArticleDto')
          ..add('categorieInterne', categorieInterne)
          ..add('nom', nom)
          ..add('prixBarreUnites', prixBarreUnites)
          ..add('prixUnites', prixUnites))
        .toString();
  }
}

class CreerArticleDtoBuilder
    implements Builder<CreerArticleDto, CreerArticleDtoBuilder> {
  _$CreerArticleDto? _$v;

  String? _categorieInterne;
  String? get categorieInterne => _$this._categorieInterne;
  set categorieInterne(String? categorieInterne) =>
      _$this._categorieInterne = categorieInterne;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  int? _prixBarreUnites;
  int? get prixBarreUnites => _$this._prixBarreUnites;
  set prixBarreUnites(int? prixBarreUnites) =>
      _$this._prixBarreUnites = prixBarreUnites;

  int? _prixUnites;
  int? get prixUnites => _$this._prixUnites;
  set prixUnites(int? prixUnites) => _$this._prixUnites = prixUnites;

  CreerArticleDtoBuilder() {
    CreerArticleDto._defaults(this);
  }

  CreerArticleDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieInterne = $v.categorieInterne;
      _nom = $v.nom;
      _prixBarreUnites = $v.prixBarreUnites;
      _prixUnites = $v.prixUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreerArticleDto other) {
    _$v = other as _$CreerArticleDto;
  }

  @override
  void update(void Function(CreerArticleDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreerArticleDto build() => _build();

  _$CreerArticleDto _build() {
    final _$result = _$v ??
        _$CreerArticleDto._(
          categorieInterne: categorieInterne,
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'CreerArticleDto', 'nom'),
          prixBarreUnites: prixBarreUnites,
          prixUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnites, r'CreerArticleDto', 'prixUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
