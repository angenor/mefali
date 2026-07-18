// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plage_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlageDto extends PlageDto {
  @override
  final String debut;
  @override
  final String fin;

  factory _$PlageDto([void Function(PlageDtoBuilder)? updates]) =>
      (PlageDtoBuilder()..update(updates))._build();

  _$PlageDto._({required this.debut, required this.fin}) : super._();
  @override
  PlageDto rebuild(void Function(PlageDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlageDtoBuilder toBuilder() => PlageDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlageDto && debut == other.debut && fin == other.fin;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, debut.hashCode);
    _$hash = $jc(_$hash, fin.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlageDto')
          ..add('debut', debut)
          ..add('fin', fin))
        .toString();
  }
}

class PlageDtoBuilder implements Builder<PlageDto, PlageDtoBuilder> {
  _$PlageDto? _$v;

  String? _debut;
  String? get debut => _$this._debut;
  set debut(String? debut) => _$this._debut = debut;

  String? _fin;
  String? get fin => _$this._fin;
  set fin(String? fin) => _$this._fin = fin;

  PlageDtoBuilder() {
    PlageDto._defaults(this);
  }

  PlageDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _debut = $v.debut;
      _fin = $v.fin;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlageDto other) {
    _$v = other as _$PlageDto;
  }

  @override
  void update(void Function(PlageDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlageDto build() => _build();

  _$PlageDto _build() {
    final _$result = _$v ??
        _$PlageDto._(
          debut: BuiltValueNullFieldError.checkNotNull(
              debut, r'PlageDto', 'debut'),
          fin: BuiltValueNullFieldError.checkNotNull(fin, r'PlageDto', 'fin'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
