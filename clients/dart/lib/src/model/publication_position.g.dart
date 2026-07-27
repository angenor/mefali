// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publication_position.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PublicationPosition extends PublicationPosition {
  @override
  final DateTime horodatageLocal;
  @override
  final double lat;
  @override
  final double lon;
  @override
  final int? precisionM;
  @override
  final String uuidClient;

  factory _$PublicationPosition(
          [void Function(PublicationPositionBuilder)? updates]) =>
      (PublicationPositionBuilder()..update(updates))._build();

  _$PublicationPosition._(
      {required this.horodatageLocal,
      required this.lat,
      required this.lon,
      this.precisionM,
      required this.uuidClient})
      : super._();
  @override
  PublicationPosition rebuild(
          void Function(PublicationPositionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PublicationPositionBuilder toBuilder() =>
      PublicationPositionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PublicationPosition &&
        horodatageLocal == other.horodatageLocal &&
        lat == other.lat &&
        lon == other.lon &&
        precisionM == other.precisionM &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, horodatageLocal.hashCode);
    _$hash = $jc(_$hash, lat.hashCode);
    _$hash = $jc(_$hash, lon.hashCode);
    _$hash = $jc(_$hash, precisionM.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PublicationPosition')
          ..add('horodatageLocal', horodatageLocal)
          ..add('lat', lat)
          ..add('lon', lon)
          ..add('precisionM', precisionM)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class PublicationPositionBuilder
    implements Builder<PublicationPosition, PublicationPositionBuilder> {
  _$PublicationPosition? _$v;

  DateTime? _horodatageLocal;
  DateTime? get horodatageLocal => _$this._horodatageLocal;
  set horodatageLocal(DateTime? horodatageLocal) =>
      _$this._horodatageLocal = horodatageLocal;

  double? _lat;
  double? get lat => _$this._lat;
  set lat(double? lat) => _$this._lat = lat;

  double? _lon;
  double? get lon => _$this._lon;
  set lon(double? lon) => _$this._lon = lon;

  int? _precisionM;
  int? get precisionM => _$this._precisionM;
  set precisionM(int? precisionM) => _$this._precisionM = precisionM;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  PublicationPositionBuilder() {
    PublicationPosition._defaults(this);
  }

  PublicationPositionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _horodatageLocal = $v.horodatageLocal;
      _lat = $v.lat;
      _lon = $v.lon;
      _precisionM = $v.precisionM;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PublicationPosition other) {
    _$v = other as _$PublicationPosition;
  }

  @override
  void update(void Function(PublicationPositionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PublicationPosition build() => _build();

  _$PublicationPosition _build() {
    final _$result = _$v ??
        _$PublicationPosition._(
          horodatageLocal: BuiltValueNullFieldError.checkNotNull(
              horodatageLocal, r'PublicationPosition', 'horodatageLocal'),
          lat: BuiltValueNullFieldError.checkNotNull(
              lat, r'PublicationPosition', 'lat'),
          lon: BuiltValueNullFieldError.checkNotNull(
              lon, r'PublicationPosition', 'lon'),
          precisionM: precisionM,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'PublicationPosition', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
