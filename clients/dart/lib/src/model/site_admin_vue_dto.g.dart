// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site_admin_vue_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SiteAdminVueDto extends SiteAdminVueDto {
  @override
  final HorairesSemaineDto horaires;
  @override
  final DateTime? pauseFin;
  @override
  final double positionLat;
  @override
  final double positionLng;
  @override
  final StatutBoutique statutBoutique;

  factory _$SiteAdminVueDto([void Function(SiteAdminVueDtoBuilder)? updates]) =>
      (SiteAdminVueDtoBuilder()..update(updates))._build();

  _$SiteAdminVueDto._(
      {required this.horaires,
      this.pauseFin,
      required this.positionLat,
      required this.positionLng,
      required this.statutBoutique})
      : super._();
  @override
  SiteAdminVueDto rebuild(void Function(SiteAdminVueDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SiteAdminVueDtoBuilder toBuilder() => SiteAdminVueDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SiteAdminVueDto &&
        horaires == other.horaires &&
        pauseFin == other.pauseFin &&
        positionLat == other.positionLat &&
        positionLng == other.positionLng &&
        statutBoutique == other.statutBoutique;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, horaires.hashCode);
    _$hash = $jc(_$hash, pauseFin.hashCode);
    _$hash = $jc(_$hash, positionLat.hashCode);
    _$hash = $jc(_$hash, positionLng.hashCode);
    _$hash = $jc(_$hash, statutBoutique.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SiteAdminVueDto')
          ..add('horaires', horaires)
          ..add('pauseFin', pauseFin)
          ..add('positionLat', positionLat)
          ..add('positionLng', positionLng)
          ..add('statutBoutique', statutBoutique))
        .toString();
  }
}

class SiteAdminVueDtoBuilder
    implements Builder<SiteAdminVueDto, SiteAdminVueDtoBuilder> {
  _$SiteAdminVueDto? _$v;

  HorairesSemaineDtoBuilder? _horaires;
  HorairesSemaineDtoBuilder get horaires =>
      _$this._horaires ??= HorairesSemaineDtoBuilder();
  set horaires(HorairesSemaineDtoBuilder? horaires) =>
      _$this._horaires = horaires;

  DateTime? _pauseFin;
  DateTime? get pauseFin => _$this._pauseFin;
  set pauseFin(DateTime? pauseFin) => _$this._pauseFin = pauseFin;

  double? _positionLat;
  double? get positionLat => _$this._positionLat;
  set positionLat(double? positionLat) => _$this._positionLat = positionLat;

  double? _positionLng;
  double? get positionLng => _$this._positionLng;
  set positionLng(double? positionLng) => _$this._positionLng = positionLng;

  StatutBoutique? _statutBoutique;
  StatutBoutique? get statutBoutique => _$this._statutBoutique;
  set statutBoutique(StatutBoutique? statutBoutique) =>
      _$this._statutBoutique = statutBoutique;

  SiteAdminVueDtoBuilder() {
    SiteAdminVueDto._defaults(this);
  }

  SiteAdminVueDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _horaires = $v.horaires.toBuilder();
      _pauseFin = $v.pauseFin;
      _positionLat = $v.positionLat;
      _positionLng = $v.positionLng;
      _statutBoutique = $v.statutBoutique;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SiteAdminVueDto other) {
    _$v = other as _$SiteAdminVueDto;
  }

  @override
  void update(void Function(SiteAdminVueDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SiteAdminVueDto build() => _build();

  _$SiteAdminVueDto _build() {
    _$SiteAdminVueDto _$result;
    try {
      _$result = _$v ??
          _$SiteAdminVueDto._(
            horaires: horaires.build(),
            pauseFin: pauseFin,
            positionLat: BuiltValueNullFieldError.checkNotNull(
                positionLat, r'SiteAdminVueDto', 'positionLat'),
            positionLng: BuiltValueNullFieldError.checkNotNull(
                positionLng, r'SiteAdminVueDto', 'positionLng'),
            statutBoutique: BuiltValueNullFieldError.checkNotNull(
                statutBoutique, r'SiteAdminVueDto', 'statutBoutique'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'horaires';
        horaires.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SiteAdminVueDto', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
