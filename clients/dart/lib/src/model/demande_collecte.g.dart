// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_collecte.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeCollecte extends DemandeCollecte {
  @override
  final String? code;
  @override
  final DateTime horodatageLocal;
  @override
  final String? jeton;
  @override
  final ModeCollecte mode;
  @override
  final double positionLat;
  @override
  final double positionLon;
  @override
  final String uuidClient;

  factory _$DemandeCollecte([void Function(DemandeCollecteBuilder)? updates]) =>
      (DemandeCollecteBuilder()..update(updates))._build();

  _$DemandeCollecte._(
      {this.code,
      required this.horodatageLocal,
      this.jeton,
      required this.mode,
      required this.positionLat,
      required this.positionLon,
      required this.uuidClient})
      : super._();
  @override
  DemandeCollecte rebuild(void Function(DemandeCollecteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeCollecteBuilder toBuilder() => DemandeCollecteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeCollecte &&
        code == other.code &&
        horodatageLocal == other.horodatageLocal &&
        jeton == other.jeton &&
        mode == other.mode &&
        positionLat == other.positionLat &&
        positionLon == other.positionLon &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, horodatageLocal.hashCode);
    _$hash = $jc(_$hash, jeton.hashCode);
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, positionLat.hashCode);
    _$hash = $jc(_$hash, positionLon.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeCollecte')
          ..add('code', code)
          ..add('horodatageLocal', horodatageLocal)
          ..add('jeton', jeton)
          ..add('mode', mode)
          ..add('positionLat', positionLat)
          ..add('positionLon', positionLon)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DemandeCollecteBuilder
    implements Builder<DemandeCollecte, DemandeCollecteBuilder> {
  _$DemandeCollecte? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  DateTime? _horodatageLocal;
  DateTime? get horodatageLocal => _$this._horodatageLocal;
  set horodatageLocal(DateTime? horodatageLocal) =>
      _$this._horodatageLocal = horodatageLocal;

  String? _jeton;
  String? get jeton => _$this._jeton;
  set jeton(String? jeton) => _$this._jeton = jeton;

  ModeCollecte? _mode;
  ModeCollecte? get mode => _$this._mode;
  set mode(ModeCollecte? mode) => _$this._mode = mode;

  double? _positionLat;
  double? get positionLat => _$this._positionLat;
  set positionLat(double? positionLat) => _$this._positionLat = positionLat;

  double? _positionLon;
  double? get positionLon => _$this._positionLon;
  set positionLon(double? positionLon) => _$this._positionLon = positionLon;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DemandeCollecteBuilder() {
    DemandeCollecte._defaults(this);
  }

  DemandeCollecteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _horodatageLocal = $v.horodatageLocal;
      _jeton = $v.jeton;
      _mode = $v.mode;
      _positionLat = $v.positionLat;
      _positionLon = $v.positionLon;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeCollecte other) {
    _$v = other as _$DemandeCollecte;
  }

  @override
  void update(void Function(DemandeCollecteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeCollecte build() => _build();

  _$DemandeCollecte _build() {
    final _$result = _$v ??
        _$DemandeCollecte._(
          code: code,
          horodatageLocal: BuiltValueNullFieldError.checkNotNull(
              horodatageLocal, r'DemandeCollecte', 'horodatageLocal'),
          jeton: jeton,
          mode: BuiltValueNullFieldError.checkNotNull(
              mode, r'DemandeCollecte', 'mode'),
          positionLat: BuiltValueNullFieldError.checkNotNull(
              positionLat, r'DemandeCollecte', 'positionLat'),
          positionLon: BuiltValueNullFieldError.checkNotNull(
              positionLon, r'DemandeCollecte', 'positionLon'),
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandeCollecte', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
