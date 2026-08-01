// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_remise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeRemise extends DemandeRemise {
  @override
  final String? code;
  @override
  final DateTime? confirmeLeLocal;
  @override
  final double? depotLat;
  @override
  final double? depotLon;
  @override
  final int? essaisHorsLigne;
  @override
  final bool? horsLigne;
  @override
  final String? jeton;
  @override
  final String mode;
  @override
  final String? photoCle;
  @override
  final String uuidClient;

  factory _$DemandeRemise([void Function(DemandeRemiseBuilder)? updates]) =>
      (DemandeRemiseBuilder()..update(updates))._build();

  _$DemandeRemise._(
      {this.code,
      this.confirmeLeLocal,
      this.depotLat,
      this.depotLon,
      this.essaisHorsLigne,
      this.horsLigne,
      this.jeton,
      required this.mode,
      this.photoCle,
      required this.uuidClient})
      : super._();
  @override
  DemandeRemise rebuild(void Function(DemandeRemiseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeRemiseBuilder toBuilder() => DemandeRemiseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeRemise &&
        code == other.code &&
        confirmeLeLocal == other.confirmeLeLocal &&
        depotLat == other.depotLat &&
        depotLon == other.depotLon &&
        essaisHorsLigne == other.essaisHorsLigne &&
        horsLigne == other.horsLigne &&
        jeton == other.jeton &&
        mode == other.mode &&
        photoCle == other.photoCle &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, confirmeLeLocal.hashCode);
    _$hash = $jc(_$hash, depotLat.hashCode);
    _$hash = $jc(_$hash, depotLon.hashCode);
    _$hash = $jc(_$hash, essaisHorsLigne.hashCode);
    _$hash = $jc(_$hash, horsLigne.hashCode);
    _$hash = $jc(_$hash, jeton.hashCode);
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, photoCle.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeRemise')
          ..add('code', code)
          ..add('confirmeLeLocal', confirmeLeLocal)
          ..add('depotLat', depotLat)
          ..add('depotLon', depotLon)
          ..add('essaisHorsLigne', essaisHorsLigne)
          ..add('horsLigne', horsLigne)
          ..add('jeton', jeton)
          ..add('mode', mode)
          ..add('photoCle', photoCle)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DemandeRemiseBuilder
    implements Builder<DemandeRemise, DemandeRemiseBuilder> {
  _$DemandeRemise? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  DateTime? _confirmeLeLocal;
  DateTime? get confirmeLeLocal => _$this._confirmeLeLocal;
  set confirmeLeLocal(DateTime? confirmeLeLocal) =>
      _$this._confirmeLeLocal = confirmeLeLocal;

  double? _depotLat;
  double? get depotLat => _$this._depotLat;
  set depotLat(double? depotLat) => _$this._depotLat = depotLat;

  double? _depotLon;
  double? get depotLon => _$this._depotLon;
  set depotLon(double? depotLon) => _$this._depotLon = depotLon;

  int? _essaisHorsLigne;
  int? get essaisHorsLigne => _$this._essaisHorsLigne;
  set essaisHorsLigne(int? essaisHorsLigne) =>
      _$this._essaisHorsLigne = essaisHorsLigne;

  bool? _horsLigne;
  bool? get horsLigne => _$this._horsLigne;
  set horsLigne(bool? horsLigne) => _$this._horsLigne = horsLigne;

  String? _jeton;
  String? get jeton => _$this._jeton;
  set jeton(String? jeton) => _$this._jeton = jeton;

  String? _mode;
  String? get mode => _$this._mode;
  set mode(String? mode) => _$this._mode = mode;

  String? _photoCle;
  String? get photoCle => _$this._photoCle;
  set photoCle(String? photoCle) => _$this._photoCle = photoCle;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DemandeRemiseBuilder() {
    DemandeRemise._defaults(this);
  }

  DemandeRemiseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _confirmeLeLocal = $v.confirmeLeLocal;
      _depotLat = $v.depotLat;
      _depotLon = $v.depotLon;
      _essaisHorsLigne = $v.essaisHorsLigne;
      _horsLigne = $v.horsLigne;
      _jeton = $v.jeton;
      _mode = $v.mode;
      _photoCle = $v.photoCle;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeRemise other) {
    _$v = other as _$DemandeRemise;
  }

  @override
  void update(void Function(DemandeRemiseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeRemise build() => _build();

  _$DemandeRemise _build() {
    final _$result = _$v ??
        _$DemandeRemise._(
          code: code,
          confirmeLeLocal: confirmeLeLocal,
          depotLat: depotLat,
          depotLon: depotLon,
          essaisHorsLigne: essaisHorsLigne,
          horsLigne: horsLigne,
          jeton: jeton,
          mode: BuiltValueNullFieldError.checkNotNull(
              mode, r'DemandeRemise', 'mode'),
          photoCle: photoCle,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandeRemise', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
