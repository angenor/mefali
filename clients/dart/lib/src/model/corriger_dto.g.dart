// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'corriger_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CorrigerDto extends CorrigerDto {
  @override
  final String? categorieSlug;
  @override
  final String? villeId;

  factory _$CorrigerDto([void Function(CorrigerDtoBuilder)? updates]) =>
      (CorrigerDtoBuilder()..update(updates))._build();

  _$CorrigerDto._({this.categorieSlug, this.villeId}) : super._();
  @override
  CorrigerDto rebuild(void Function(CorrigerDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CorrigerDtoBuilder toBuilder() => CorrigerDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CorrigerDto &&
        categorieSlug == other.categorieSlug &&
        villeId == other.villeId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, villeId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CorrigerDto')
          ..add('categorieSlug', categorieSlug)
          ..add('villeId', villeId))
        .toString();
  }
}

class CorrigerDtoBuilder implements Builder<CorrigerDto, CorrigerDtoBuilder> {
  _$CorrigerDto? _$v;

  String? _categorieSlug;
  String? get categorieSlug => _$this._categorieSlug;
  set categorieSlug(String? categorieSlug) =>
      _$this._categorieSlug = categorieSlug;

  String? _villeId;
  String? get villeId => _$this._villeId;
  set villeId(String? villeId) => _$this._villeId = villeId;

  CorrigerDtoBuilder() {
    CorrigerDto._defaults(this);
  }

  CorrigerDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieSlug = $v.categorieSlug;
      _villeId = $v.villeId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CorrigerDto other) {
    _$v = other as _$CorrigerDto;
  }

  @override
  void update(void Function(CorrigerDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CorrigerDto build() => _build();

  _$CorrigerDto _build() {
    final _$result = _$v ??
        _$CorrigerDto._(
          categorieSlug: categorieSlug,
          villeId: villeId,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
