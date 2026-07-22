// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suspendre_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SuspendreDto extends SuspendreDto {
  @override
  final String motif;

  factory _$SuspendreDto([void Function(SuspendreDtoBuilder)? updates]) =>
      (SuspendreDtoBuilder()..update(updates))._build();

  _$SuspendreDto._({required this.motif}) : super._();
  @override
  SuspendreDto rebuild(void Function(SuspendreDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SuspendreDtoBuilder toBuilder() => SuspendreDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SuspendreDto && motif == other.motif;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SuspendreDto')..add('motif', motif))
        .toString();
  }
}

class SuspendreDtoBuilder
    implements Builder<SuspendreDto, SuspendreDtoBuilder> {
  _$SuspendreDto? _$v;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  SuspendreDtoBuilder() {
    SuspendreDto._defaults(this);
  }

  SuspendreDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motif = $v.motif;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SuspendreDto other) {
    _$v = other as _$SuspendreDto;
  }

  @override
  void update(void Function(SuspendreDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SuspendreDto build() => _build();

  _$SuspendreDto _build() {
    final _$result = _$v ??
        _$SuspendreDto._(
          motif: BuiltValueNullFieldError.checkNotNull(
              motif, r'SuspendreDto', 'motif'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
