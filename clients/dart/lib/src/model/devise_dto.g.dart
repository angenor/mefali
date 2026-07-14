// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devise_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DeviseDto extends DeviseDto {
  @override
  final String code;
  @override
  final int decimales;

  factory _$DeviseDto([void Function(DeviseDtoBuilder)? updates]) =>
      (DeviseDtoBuilder()..update(updates))._build();

  _$DeviseDto._({required this.code, required this.decimales}) : super._();
  @override
  DeviseDto rebuild(void Function(DeviseDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DeviseDtoBuilder toBuilder() => DeviseDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DeviseDto &&
        code == other.code &&
        decimales == other.decimales;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, decimales.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DeviseDto')
          ..add('code', code)
          ..add('decimales', decimales))
        .toString();
  }
}

class DeviseDtoBuilder implements Builder<DeviseDto, DeviseDtoBuilder> {
  _$DeviseDto? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  int? _decimales;
  int? get decimales => _$this._decimales;
  set decimales(int? decimales) => _$this._decimales = decimales;

  DeviseDtoBuilder() {
    DeviseDto._defaults(this);
  }

  DeviseDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _decimales = $v.decimales;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DeviseDto other) {
    _$v = other as _$DeviseDto;
  }

  @override
  void update(void Function(DeviseDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DeviseDto build() => _build();

  _$DeviseDto _build() {
    final _$result = _$v ??
        _$DeviseDto._(
          code:
              BuiltValueNullFieldError.checkNotNull(code, r'DeviseDto', 'code'),
          decimales: BuiltValueNullFieldError.checkNotNull(
              decimales, r'DeviseDto', 'decimales'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
