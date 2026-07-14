// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'categorie_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CategorieDto extends CategorieDto {
  @override
  final bool mixable;
  @override
  final String nomCle;
  @override
  final String slug;

  factory _$CategorieDto([void Function(CategorieDtoBuilder)? updates]) =>
      (CategorieDtoBuilder()..update(updates))._build();

  _$CategorieDto._(
      {required this.mixable, required this.nomCle, required this.slug})
      : super._();
  @override
  CategorieDto rebuild(void Function(CategorieDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CategorieDtoBuilder toBuilder() => CategorieDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CategorieDto &&
        mixable == other.mixable &&
        nomCle == other.nomCle &&
        slug == other.slug;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, mixable.hashCode);
    _$hash = $jc(_$hash, nomCle.hashCode);
    _$hash = $jc(_$hash, slug.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CategorieDto')
          ..add('mixable', mixable)
          ..add('nomCle', nomCle)
          ..add('slug', slug))
        .toString();
  }
}

class CategorieDtoBuilder
    implements Builder<CategorieDto, CategorieDtoBuilder> {
  _$CategorieDto? _$v;

  bool? _mixable;
  bool? get mixable => _$this._mixable;
  set mixable(bool? mixable) => _$this._mixable = mixable;

  String? _nomCle;
  String? get nomCle => _$this._nomCle;
  set nomCle(String? nomCle) => _$this._nomCle = nomCle;

  String? _slug;
  String? get slug => _$this._slug;
  set slug(String? slug) => _$this._slug = slug;

  CategorieDtoBuilder() {
    CategorieDto._defaults(this);
  }

  CategorieDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _mixable = $v.mixable;
      _nomCle = $v.nomCle;
      _slug = $v.slug;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CategorieDto other) {
    _$v = other as _$CategorieDto;
  }

  @override
  void update(void Function(CategorieDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CategorieDto build() => _build();

  _$CategorieDto _build() {
    final _$result = _$v ??
        _$CategorieDto._(
          mixable: BuiltValueNullFieldError.checkNotNull(
              mixable, r'CategorieDto', 'mixable'),
          nomCle: BuiltValueNullFieldError.checkNotNull(
              nomCle, r'CategorieDto', 'nomCle'),
          slug: BuiltValueNullFieldError.checkNotNull(
              slug, r'CategorieDto', 'slug'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
