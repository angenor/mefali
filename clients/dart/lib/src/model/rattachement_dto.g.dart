// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rattachement_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RattachementDto extends RattachementDto {
  @override
  final String compteId;
  @override
  final DateTime rattacheLe;

  factory _$RattachementDto([void Function(RattachementDtoBuilder)? updates]) =>
      (RattachementDtoBuilder()..update(updates))._build();

  _$RattachementDto._({required this.compteId, required this.rattacheLe})
      : super._();
  @override
  RattachementDto rebuild(void Function(RattachementDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RattachementDtoBuilder toBuilder() => RattachementDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RattachementDto &&
        compteId == other.compteId &&
        rattacheLe == other.rattacheLe;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compteId.hashCode);
    _$hash = $jc(_$hash, rattacheLe.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RattachementDto')
          ..add('compteId', compteId)
          ..add('rattacheLe', rattacheLe))
        .toString();
  }
}

class RattachementDtoBuilder
    implements Builder<RattachementDto, RattachementDtoBuilder> {
  _$RattachementDto? _$v;

  String? _compteId;
  String? get compteId => _$this._compteId;
  set compteId(String? compteId) => _$this._compteId = compteId;

  DateTime? _rattacheLe;
  DateTime? get rattacheLe => _$this._rattacheLe;
  set rattacheLe(DateTime? rattacheLe) => _$this._rattacheLe = rattacheLe;

  RattachementDtoBuilder() {
    RattachementDto._defaults(this);
  }

  RattachementDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compteId = $v.compteId;
      _rattacheLe = $v.rattacheLe;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RattachementDto other) {
    _$v = other as _$RattachementDto;
  }

  @override
  void update(void Function(RattachementDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RattachementDto build() => _build();

  _$RattachementDto _build() {
    final _$result = _$v ??
        _$RattachementDto._(
          compteId: BuiltValueNullFieldError.checkNotNull(
              compteId, r'RattachementDto', 'compteId'),
          rattacheLe: BuiltValueNullFieldError.checkNotNull(
              rattacheLe, r'RattachementDto', 'rattacheLe'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
