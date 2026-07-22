// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'horaires_semaine_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$HorairesSemaineDto extends HorairesSemaineDto {
  @override
  final BuiltList<BuiltList<PlageDto>> jours;

  factory _$HorairesSemaineDto(
          [void Function(HorairesSemaineDtoBuilder)? updates]) =>
      (HorairesSemaineDtoBuilder()..update(updates))._build();

  _$HorairesSemaineDto._({required this.jours}) : super._();
  @override
  HorairesSemaineDto rebuild(
          void Function(HorairesSemaineDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  HorairesSemaineDtoBuilder toBuilder() =>
      HorairesSemaineDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is HorairesSemaineDto && jours == other.jours;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jours.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'HorairesSemaineDto')
          ..add('jours', jours))
        .toString();
  }
}

class HorairesSemaineDtoBuilder
    implements Builder<HorairesSemaineDto, HorairesSemaineDtoBuilder> {
  _$HorairesSemaineDto? _$v;

  ListBuilder<BuiltList<PlageDto>>? _jours;
  ListBuilder<BuiltList<PlageDto>> get jours =>
      _$this._jours ??= ListBuilder<BuiltList<PlageDto>>();
  set jours(ListBuilder<BuiltList<PlageDto>>? jours) => _$this._jours = jours;

  HorairesSemaineDtoBuilder() {
    HorairesSemaineDto._defaults(this);
  }

  HorairesSemaineDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jours = $v.jours.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(HorairesSemaineDto other) {
    _$v = other as _$HorairesSemaineDto;
  }

  @override
  void update(void Function(HorairesSemaineDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  HorairesSemaineDto build() => _build();

  _$HorairesSemaineDto _build() {
    _$HorairesSemaineDto _$result;
    try {
      _$result = _$v ??
          _$HorairesSemaineDto._(
            jours: jours.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'jours';
        jours.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'HorairesSemaineDto', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
