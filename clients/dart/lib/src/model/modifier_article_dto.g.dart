// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier_article_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ModifierArticleDto extends ModifierArticleDto {
  @override
  final String? categorieInterne;
  @override
  final String? nom;
  @override
  final int? prixBarreUnites;
  @override
  final int? prixUnites;
  @override
  final bool? retirerPrixBarre;

  factory _$ModifierArticleDto(
          [void Function(ModifierArticleDtoBuilder)? updates]) =>
      (ModifierArticleDtoBuilder()..update(updates))._build();

  _$ModifierArticleDto._(
      {this.categorieInterne,
      this.nom,
      this.prixBarreUnites,
      this.prixUnites,
      this.retirerPrixBarre})
      : super._();
  @override
  ModifierArticleDto rebuild(
          void Function(ModifierArticleDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ModifierArticleDtoBuilder toBuilder() =>
      ModifierArticleDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ModifierArticleDto &&
        categorieInterne == other.categorieInterne &&
        nom == other.nom &&
        prixBarreUnites == other.prixBarreUnites &&
        prixUnites == other.prixUnites &&
        retirerPrixBarre == other.retirerPrixBarre;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieInterne.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, prixBarreUnites.hashCode);
    _$hash = $jc(_$hash, prixUnites.hashCode);
    _$hash = $jc(_$hash, retirerPrixBarre.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ModifierArticleDto')
          ..add('categorieInterne', categorieInterne)
          ..add('nom', nom)
          ..add('prixBarreUnites', prixBarreUnites)
          ..add('prixUnites', prixUnites)
          ..add('retirerPrixBarre', retirerPrixBarre))
        .toString();
  }
}

class ModifierArticleDtoBuilder
    implements Builder<ModifierArticleDto, ModifierArticleDtoBuilder> {
  _$ModifierArticleDto? _$v;

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

  bool? _retirerPrixBarre;
  bool? get retirerPrixBarre => _$this._retirerPrixBarre;
  set retirerPrixBarre(bool? retirerPrixBarre) =>
      _$this._retirerPrixBarre = retirerPrixBarre;

  ModifierArticleDtoBuilder() {
    ModifierArticleDto._defaults(this);
  }

  ModifierArticleDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieInterne = $v.categorieInterne;
      _nom = $v.nom;
      _prixBarreUnites = $v.prixBarreUnites;
      _prixUnites = $v.prixUnites;
      _retirerPrixBarre = $v.retirerPrixBarre;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ModifierArticleDto other) {
    _$v = other as _$ModifierArticleDto;
  }

  @override
  void update(void Function(ModifierArticleDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ModifierArticleDto build() => _build();

  _$ModifierArticleDto _build() {
    final _$result = _$v ??
        _$ModifierArticleDto._(
          categorieInterne: categorieInterne,
          nom: nom,
          prixBarreUnites: prixBarreUnites,
          prixUnites: prixUnites,
          retirerPrixBarre: retirerPrixBarre,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
