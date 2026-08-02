// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regler_creance_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReglerCreanceDto extends ReglerCreanceDto {
  @override
  final String motifCle;

  factory _$ReglerCreanceDto(
          [void Function(ReglerCreanceDtoBuilder)? updates]) =>
      (ReglerCreanceDtoBuilder()..update(updates))._build();

  _$ReglerCreanceDto._({required this.motifCle}) : super._();
  @override
  ReglerCreanceDto rebuild(void Function(ReglerCreanceDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReglerCreanceDtoBuilder toBuilder() =>
      ReglerCreanceDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReglerCreanceDto && motifCle == other.motifCle;
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
    return (newBuiltValueToStringHelper(r'ReglerCreanceDto')
          ..add('motifCle', motifCle))
        .toString();
  }
}

class ReglerCreanceDtoBuilder
    implements Builder<ReglerCreanceDto, ReglerCreanceDtoBuilder> {
  _$ReglerCreanceDto? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  ReglerCreanceDtoBuilder() {
    ReglerCreanceDto._defaults(this);
  }

  ReglerCreanceDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReglerCreanceDto other) {
    _$v = other as _$ReglerCreanceDto;
  }

  @override
  void update(void Function(ReglerCreanceDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReglerCreanceDto build() => _build();

  _$ReglerCreanceDto _build() {
    final _$result = _$v ??
        _$ReglerCreanceDto._(
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'ReglerCreanceDto', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
