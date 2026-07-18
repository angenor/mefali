// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier_prestataire_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ModifierPrestataireDto extends ModifierPrestataireDto {
  @override
  final String? contactTelephone;
  @override
  final int? delaiPreparationMin;
  @override
  final String? nom;

  factory _$ModifierPrestataireDto(
          [void Function(ModifierPrestataireDtoBuilder)? updates]) =>
      (ModifierPrestataireDtoBuilder()..update(updates))._build();

  _$ModifierPrestataireDto._(
      {this.contactTelephone, this.delaiPreparationMin, this.nom})
      : super._();
  @override
  ModifierPrestataireDto rebuild(
          void Function(ModifierPrestataireDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ModifierPrestataireDtoBuilder toBuilder() =>
      ModifierPrestataireDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ModifierPrestataireDto &&
        contactTelephone == other.contactTelephone &&
        delaiPreparationMin == other.delaiPreparationMin &&
        nom == other.nom;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, contactTelephone.hashCode);
    _$hash = $jc(_$hash, delaiPreparationMin.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ModifierPrestataireDto')
          ..add('contactTelephone', contactTelephone)
          ..add('delaiPreparationMin', delaiPreparationMin)
          ..add('nom', nom))
        .toString();
  }
}

class ModifierPrestataireDtoBuilder
    implements Builder<ModifierPrestataireDto, ModifierPrestataireDtoBuilder> {
  _$ModifierPrestataireDto? _$v;

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

  ModifierPrestataireDtoBuilder() {
    ModifierPrestataireDto._defaults(this);
  }

  ModifierPrestataireDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _contactTelephone = $v.contactTelephone;
      _delaiPreparationMin = $v.delaiPreparationMin;
      _nom = $v.nom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ModifierPrestataireDto other) {
    _$v = other as _$ModifierPrestataireDto;
  }

  @override
  void update(void Function(ModifierPrestataireDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ModifierPrestataireDto build() => _build();

  _$ModifierPrestataireDto _build() {
    final _$result = _$v ??
        _$ModifierPrestataireDto._(
          contactTelephone: contactTelephone,
          delaiPreparationMin: delaiPreparationMin,
          nom: nom,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
