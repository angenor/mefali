// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'destination_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DestinationOffre extends DestinationOffre {
  @override
  final int distanceM;
  @override
  final String mentionCle;
  @override
  final String zoneNom;

  factory _$DestinationOffre(
          [void Function(DestinationOffreBuilder)? updates]) =>
      (DestinationOffreBuilder()..update(updates))._build();

  _$DestinationOffre._(
      {required this.distanceM,
      required this.mentionCle,
      required this.zoneNom})
      : super._();
  @override
  DestinationOffre rebuild(void Function(DestinationOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DestinationOffreBuilder toBuilder() =>
      DestinationOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DestinationOffre &&
        distanceM == other.distanceM &&
        mentionCle == other.mentionCle &&
        zoneNom == other.zoneNom;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, mentionCle.hashCode);
    _$hash = $jc(_$hash, zoneNom.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DestinationOffre')
          ..add('distanceM', distanceM)
          ..add('mentionCle', mentionCle)
          ..add('zoneNom', zoneNom))
        .toString();
  }
}

class DestinationOffreBuilder
    implements Builder<DestinationOffre, DestinationOffreBuilder> {
  _$DestinationOffre? _$v;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  String? _mentionCle;
  String? get mentionCle => _$this._mentionCle;
  set mentionCle(String? mentionCle) => _$this._mentionCle = mentionCle;

  String? _zoneNom;
  String? get zoneNom => _$this._zoneNom;
  set zoneNom(String? zoneNom) => _$this._zoneNom = zoneNom;

  DestinationOffreBuilder() {
    DestinationOffre._defaults(this);
  }

  DestinationOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _distanceM = $v.distanceM;
      _mentionCle = $v.mentionCle;
      _zoneNom = $v.zoneNom;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DestinationOffre other) {
    _$v = other as _$DestinationOffre;
  }

  @override
  void update(void Function(DestinationOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DestinationOffre build() => _build();

  _$DestinationOffre _build() {
    final _$result = _$v ??
        _$DestinationOffre._(
          distanceM: BuiltValueNullFieldError.checkNotNull(
              distanceM, r'DestinationOffre', 'distanceM'),
          mentionCle: BuiltValueNullFieldError.checkNotNull(
              mentionCle, r'DestinationOffre', 'mentionCle'),
          zoneNom: BuiltValueNullFieldError.checkNotNull(
              zoneNom, r'DestinationOffre', 'zoneNom'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
