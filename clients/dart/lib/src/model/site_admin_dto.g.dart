// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_admin_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SiteAdminDto extends SiteAdminDto {
  @override
  final HorairesSemaineDto horaires;
  @override
  final double positionLat;
  @override
  final double positionLng;
  @override
  final StatutBoutique? statutInitial;

  factory _$SiteAdminDto([void Function(SiteAdminDtoBuilder)? updates]) =>
      (SiteAdminDtoBuilder()..update(updates))._build();

  _$SiteAdminDto._(
      {required this.horaires,
      required this.positionLat,
      required this.positionLng,
      this.statutInitial})
      : super._();
  @override
  SiteAdminDto rebuild(void Function(SiteAdminDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SiteAdminDtoBuilder toBuilder() => SiteAdminDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SiteAdminDto &&
        horaires == other.horaires &&
        positionLat == other.positionLat &&
        positionLng == other.positionLng &&
        statutInitial == other.statutInitial;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, horaires.hashCode);
    _$hash = $jc(_$hash, positionLat.hashCode);
    _$hash = $jc(_$hash, positionLng.hashCode);
    _$hash = $jc(_$hash, statutInitial.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SiteAdminDto')
          ..add('horaires', horaires)
          ..add('positionLat', positionLat)
          ..add('positionLng', positionLng)
          ..add('statutInitial', statutInitial))
        .toString();
  }
}

class SiteAdminDtoBuilder
    implements Builder<SiteAdminDto, SiteAdminDtoBuilder> {
  _$SiteAdminDto? _$v;

  HorairesSemaineDtoBuilder? _horaires;
  HorairesSemaineDtoBuilder get horaires =>
      _$this._horaires ??= HorairesSemaineDtoBuilder();
  set horaires(HorairesSemaineDtoBuilder? horaires) =>
      _$this._horaires = horaires;

  double? _positionLat;
  double? get positionLat => _$this._positionLat;
  set positionLat(double? positionLat) => _$this._positionLat = positionLat;

  double? _positionLng;
  double? get positionLng => _$this._positionLng;
  set positionLng(double? positionLng) => _$this._positionLng = positionLng;

  StatutBoutique? _statutInitial;
  StatutBoutique? get statutInitial => _$this._statutInitial;
  set statutInitial(StatutBoutique? statutInitial) =>
      _$this._statutInitial = statutInitial;

  SiteAdminDtoBuilder() {
    SiteAdminDto._defaults(this);
  }

  SiteAdminDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _horaires = $v.horaires.toBuilder();
      _positionLat = $v.positionLat;
      _positionLng = $v.positionLng;
      _statutInitial = $v.statutInitial;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SiteAdminDto other) {
    _$v = other as _$SiteAdminDto;
  }

  @override
  void update(void Function(SiteAdminDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SiteAdminDto build() => _build();

  _$SiteAdminDto _build() {
    _$SiteAdminDto _$result;
    try {
      _$result = _$v ??
          _$SiteAdminDto._(
            horaires: horaires.build(),
            positionLat: BuiltValueNullFieldError.checkNotNull(
                positionLat, r'SiteAdminDto', 'positionLat'),
            positionLng: BuiltValueNullFieldError.checkNotNull(
                positionLng, r'SiteAdminDto', 'positionLng'),
            statutInitial: statutInitial,
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'horaires';
        horaires.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SiteAdminDto', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
