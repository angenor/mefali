// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creer_prestataire_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CreerPrestataireDto extends CreerPrestataireDto {
  @override
  final String categorieSlug;
  @override
  final String contactTelephone;
  @override
  final int delaiPreparationMin;
  @override
  final String nom;
  @override
  final String villeId;

  factory _$CreerPrestataireDto(
          [void Function(CreerPrestataireDtoBuilder)? updates]) =>
      (CreerPrestataireDtoBuilder()..update(updates))._build();

  _$CreerPrestataireDto._(
      {required this.categorieSlug,
      required this.contactTelephone,
      required this.delaiPreparationMin,
      required this.nom,
      required this.villeId})
      : super._();
  @override
  CreerPrestataireDto rebuild(
          void Function(CreerPrestataireDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreerPrestataireDtoBuilder toBuilder() =>
      CreerPrestataireDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CreerPrestataireDto &&
        categorieSlug == other.categorieSlug &&
        contactTelephone == other.contactTelephone &&
        delaiPreparationMin == other.delaiPreparationMin &&
        nom == other.nom &&
        villeId == other.villeId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, contactTelephone.hashCode);
    _$hash = $jc(_$hash, delaiPreparationMin.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, villeId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CreerPrestataireDto')
          ..add('categorieSlug', categorieSlug)
          ..add('contactTelephone', contactTelephone)
          ..add('delaiPreparationMin', delaiPreparationMin)
          ..add('nom', nom)
          ..add('villeId', villeId))
        .toString();
  }
}

class CreerPrestataireDtoBuilder
    implements Builder<CreerPrestataireDto, CreerPrestataireDtoBuilder> {
  _$CreerPrestataireDto? _$v;

  String? _categorieSlug;
  String? get categorieSlug => _$this._categorieSlug;
  set categorieSlug(String? categorieSlug) =>
      _$this._categorieSlug = categorieSlug;

  String? _contactTelephone;
  String? get contactTelephone => _$this._contactTelephone;
  set contactTelephone(String? contactTelephone) =>
      _$this._contactTelephone = contactTelephone;

  int? _delaiPreparationMin;
  int? get delaiPreparationMin => _$this._delaiPreparationMin;
  set delaiPreparationMin(int? delaiPreparationMin) =>
      _$this._delaiPreparationMin = delaiPreparationMin;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  String? _villeId;
  String? get villeId => _$this._villeId;
  set villeId(String? villeId) => _$this._villeId = villeId;

  CreerPrestataireDtoBuilder() {
    CreerPrestataireDto._defaults(this);
  }

  CreerPrestataireDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieSlug = $v.categorieSlug;
      _contactTelephone = $v.contactTelephone;
      _delaiPreparationMin = $v.delaiPreparationMin;
      _nom = $v.nom;
      _villeId = $v.villeId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CreerPrestataireDto other) {
    _$v = other as _$CreerPrestataireDto;
  }

  @override
  void update(void Function(CreerPrestataireDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CreerPrestataireDto build() => _build();

  _$CreerPrestataireDto _build() {
    final _$result = _$v ??
        _$CreerPrestataireDto._(
          categorieSlug: BuiltValueNullFieldError.checkNotNull(
              categorieSlug, r'CreerPrestataireDto', 'categorieSlug'),
          contactTelephone: BuiltValueNullFieldError.checkNotNull(
              contactTelephone, r'CreerPrestataireDto', 'contactTelephone'),
          delaiPreparationMin: BuiltValueNullFieldError.checkNotNull(
              delaiPreparationMin,
              r'CreerPrestataireDto',
              'delaiPreparationMin'),
          nom: BuiltValueNullFieldError.checkNotNull(
              nom, r'CreerPrestataireDto', 'nom'),
          villeId: BuiltValueNullFieldError.checkNotNull(
              villeId, r'CreerPrestataireDto', 'villeId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
