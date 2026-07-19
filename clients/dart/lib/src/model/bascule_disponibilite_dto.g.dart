// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bascule_disponibilite_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BasculeDisponibiliteDto extends BasculeDisponibiliteDto {
  @override
  final bool disponible;

  factory _$BasculeDisponibiliteDto(
          [void Function(BasculeDisponibiliteDtoBuilder)? updates]) =>
      (BasculeDisponibiliteDtoBuilder()..update(updates))._build();

  _$BasculeDisponibiliteDto._({required this.disponible}) : super._();
  @override
  BasculeDisponibiliteDto rebuild(
          void Function(BasculeDisponibiliteDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BasculeDisponibiliteDtoBuilder toBuilder() =>
      BasculeDisponibiliteDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BasculeDisponibiliteDto && disponible == other.disponible;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, disponible.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BasculeDisponibiliteDto')
          ..add('disponible', disponible))
        .toString();
  }
}

class BasculeDisponibiliteDtoBuilder
    implements
        Builder<BasculeDisponibiliteDto, BasculeDisponibiliteDtoBuilder> {
  _$BasculeDisponibiliteDto? _$v;

  bool? _disponible;
  bool? get disponible => _$this._disponible;
  set disponible(bool? disponible) => _$this._disponible = disponible;

  BasculeDisponibiliteDtoBuilder() {
    BasculeDisponibiliteDto._defaults(this);
  }

  BasculeDisponibiliteDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _disponible = $v.disponible;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BasculeDisponibiliteDto other) {
    _$v = other as _$BasculeDisponibiliteDto;
  }

  @override
  void update(void Function(BasculeDisponibiliteDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BasculeDisponibiliteDto build() => _build();

  _$BasculeDisponibiliteDto _build() {
    final _$result = _$v ??
        _$BasculeDisponibiliteDto._(
          disponible: BuiltValueNullFieldError.checkNotNull(
              disponible, r'BasculeDisponibiliteDto', 'disponible'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
