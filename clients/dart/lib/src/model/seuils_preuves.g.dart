// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'seuils_preuves.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SeuilsPreuves extends SeuilsPreuves {
  @override
  final int appelsMin;
  @override
  final int espacementS;
  @override
  final int photosMin;
  @override
  final int presenceS;
  @override
  final int rayonM;

  factory _$SeuilsPreuves([void Function(SeuilsPreuvesBuilder)? updates]) =>
      (SeuilsPreuvesBuilder()..update(updates))._build();

  _$SeuilsPreuves._(
      {required this.appelsMin,
      required this.espacementS,
      required this.photosMin,
      required this.presenceS,
      required this.rayonM})
      : super._();
  @override
  SeuilsPreuves rebuild(void Function(SeuilsPreuvesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SeuilsPreuvesBuilder toBuilder() => SeuilsPreuvesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SeuilsPreuves &&
        appelsMin == other.appelsMin &&
        espacementS == other.espacementS &&
        photosMin == other.photosMin &&
        presenceS == other.presenceS &&
        rayonM == other.rayonM;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appelsMin.hashCode);
    _$hash = $jc(_$hash, espacementS.hashCode);
    _$hash = $jc(_$hash, photosMin.hashCode);
    _$hash = $jc(_$hash, presenceS.hashCode);
    _$hash = $jc(_$hash, rayonM.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SeuilsPreuves')
          ..add('appelsMin', appelsMin)
          ..add('espacementS', espacementS)
          ..add('photosMin', photosMin)
          ..add('presenceS', presenceS)
          ..add('rayonM', rayonM))
        .toString();
  }
}

class SeuilsPreuvesBuilder
    implements Builder<SeuilsPreuves, SeuilsPreuvesBuilder> {
  _$SeuilsPreuves? _$v;

  int? _appelsMin;
  int? get appelsMin => _$this._appelsMin;
  set appelsMin(int? appelsMin) => _$this._appelsMin = appelsMin;

  int? _espacementS;
  int? get espacementS => _$this._espacementS;
  set espacementS(int? espacementS) => _$this._espacementS = espacementS;

  int? _photosMin;
  int? get photosMin => _$this._photosMin;
  set photosMin(int? photosMin) => _$this._photosMin = photosMin;

  int? _presenceS;
  int? get presenceS => _$this._presenceS;
  set presenceS(int? presenceS) => _$this._presenceS = presenceS;

  int? _rayonM;
  int? get rayonM => _$this._rayonM;
  set rayonM(int? rayonM) => _$this._rayonM = rayonM;

  SeuilsPreuvesBuilder() {
    SeuilsPreuves._defaults(this);
  }

  SeuilsPreuvesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appelsMin = $v.appelsMin;
      _espacementS = $v.espacementS;
      _photosMin = $v.photosMin;
      _presenceS = $v.presenceS;
      _rayonM = $v.rayonM;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SeuilsPreuves other) {
    _$v = other as _$SeuilsPreuves;
  }

  @override
  void update(void Function(SeuilsPreuvesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SeuilsPreuves build() => _build();

  _$SeuilsPreuves _build() {
    final _$result = _$v ??
        _$SeuilsPreuves._(
          appelsMin: BuiltValueNullFieldError.checkNotNull(
              appelsMin, r'SeuilsPreuves', 'appelsMin'),
          espacementS: BuiltValueNullFieldError.checkNotNull(
              espacementS, r'SeuilsPreuves', 'espacementS'),
          photosMin: BuiltValueNullFieldError.checkNotNull(
              photosMin, r'SeuilsPreuves', 'photosMin'),
          presenceS: BuiltValueNullFieldError.checkNotNull(
              presenceS, r'SeuilsPreuves', 'presenceS'),
          rayonM: BuiltValueNullFieldError.checkNotNull(
              rayonM, r'SeuilsPreuves', 'rayonM'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
