// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appareil_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppareilDto extends AppareilDto {
  @override
  final String nom;
  @override
  final PlateformeDto plateforme;

  factory _$AppareilDto([void Function(AppareilDtoBuilder)? updates]) =>
      (AppareilDtoBuilder()..update(updates))._build();

  _$AppareilDto._({required this.nom, required this.plateforme}) : super._();
  @override
  AppareilDto rebuild(void Function(AppareilDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppareilDtoBuilder toBuilder() => AppareilDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppareilDto &&
        nom == other.nom &&
        plateforme == other.plateforme;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, plateforme.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppareilDto')
          ..add('nom', nom)
          ..add('plateforme', plateforme))
        .toString();
  }
}

class AppareilDtoBuilder implements Builder<AppareilDto, AppareilDtoBuilder> {
  _$AppareilDto? _$v;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  PlateformeDto? _plateforme;
  PlateformeDto? get plateforme => _$this._plateforme;
  set plateforme(PlateformeDto? plateforme) => _$this._plateforme = plateforme;

  AppareilDtoBuilder() {
    AppareilDto._defaults(this);
  }

  AppareilDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _nom = $v.nom;
      _plateforme = $v.plateforme;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppareilDto other) {
    _$v = other as _$AppareilDto;
  }

  @override
  void update(void Function(AppareilDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppareilDto build() => _build();

  _$AppareilDto _build() {
    final _$result = _$v ??
        _$AppareilDto._(
          nom:
              BuiltValueNullFieldError.checkNotNull(nom, r'AppareilDto', 'nom'),
          plateforme: BuiltValueNullFieldError.checkNotNull(
              plateforme, r'AppareilDto', 'plateforme'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
