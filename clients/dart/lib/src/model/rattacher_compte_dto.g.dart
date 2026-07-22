// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rattacher_compte_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RattacherCompteDto extends RattacherCompteDto {
  @override
  final String compteId;

  factory _$RattacherCompteDto(
          [void Function(RattacherCompteDtoBuilder)? updates]) =>
      (RattacherCompteDtoBuilder()..update(updates))._build();

  _$RattacherCompteDto._({required this.compteId}) : super._();
  @override
  RattacherCompteDto rebuild(
          void Function(RattacherCompteDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RattacherCompteDtoBuilder toBuilder() =>
      RattacherCompteDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RattacherCompteDto && compteId == other.compteId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compteId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RattacherCompteDto')
          ..add('compteId', compteId))
        .toString();
  }
}

class RattacherCompteDtoBuilder
    implements Builder<RattacherCompteDto, RattacherCompteDtoBuilder> {
  _$RattacherCompteDto? _$v;

  String? _compteId;
  String? get compteId => _$this._compteId;
  set compteId(String? compteId) => _$this._compteId = compteId;

  RattacherCompteDtoBuilder() {
    RattacherCompteDto._defaults(this);
  }

  RattacherCompteDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compteId = $v.compteId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RattacherCompteDto other) {
    _$v = other as _$RattacherCompteDto;
  }

  @override
  void update(void Function(RattacherCompteDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RattacherCompteDto build() => _build();

  _$RattacherCompteDto _build() {
    final _$result = _$v ??
        _$RattacherCompteDto._(
          compteId: BuiltValueNullFieldError.checkNotNull(
              compteId, r'RattacherCompteDto', 'compteId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
