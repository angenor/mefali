// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clore_dossier_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CloreDossierDto extends CloreDossierDto {
  @override
  final String motifCle;

  factory _$CloreDossierDto([void Function(CloreDossierDtoBuilder)? updates]) =>
      (CloreDossierDtoBuilder()..update(updates))._build();

  _$CloreDossierDto._({required this.motifCle}) : super._();
  @override
  CloreDossierDto rebuild(void Function(CloreDossierDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CloreDossierDtoBuilder toBuilder() => CloreDossierDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CloreDossierDto && motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CloreDossierDto')
          ..add('motifCle', motifCle))
        .toString();
  }
}

class CloreDossierDtoBuilder
    implements Builder<CloreDossierDto, CloreDossierDtoBuilder> {
  _$CloreDossierDto? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  CloreDossierDtoBuilder() {
    CloreDossierDto._defaults(this);
  }

  CloreDossierDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CloreDossierDto other) {
    _$v = other as _$CloreDossierDto;
  }

  @override
  void update(void Function(CloreDossierDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CloreDossierDto build() => _build();

  _$CloreDossierDto _build() {
    final _$result = _$v ??
        _$CloreDossierDto._(
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'CloreDossierDto', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
