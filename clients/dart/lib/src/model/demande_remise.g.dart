// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_remise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeRemise extends DemandeRemise {
  @override
  final String? code;
  @override
  final String? jeton;
  @override
  final String mode;
  @override
  final String? photoCle;

  factory _$DemandeRemise([void Function(DemandeRemiseBuilder)? updates]) =>
      (DemandeRemiseBuilder()..update(updates))._build();

  _$DemandeRemise._({this.code, this.jeton, required this.mode, this.photoCle})
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
        jeton == other.jeton &&
        mode == other.mode &&
        photoCle == other.photoCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, jeton.hashCode);
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, photoCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeRemise')
          ..add('code', code)
          ..add('jeton', jeton)
          ..add('mode', mode)
          ..add('photoCle', photoCle))
        .toString();
  }
}

class DemandeRemiseBuilder
    implements Builder<DemandeRemise, DemandeRemiseBuilder> {
  _$DemandeRemise? _$v;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _jeton;
  String? get jeton => _$this._jeton;
  set jeton(String? jeton) => _$this._jeton = jeton;

  String? _mode;
  String? get mode => _$this._mode;
  set mode(String? mode) => _$this._mode = mode;

  String? _photoCle;
  String? get photoCle => _$this._photoCle;
  set photoCle(String? photoCle) => _$this._photoCle = photoCle;

  DemandeRemiseBuilder() {
    DemandeRemise._defaults(this);
  }

  DemandeRemiseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _code = $v.code;
      _jeton = $v.jeton;
      _mode = $v.mode;
      _photoCle = $v.photoCle;
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
          jeton: jeton,
          mode: BuiltValueNullFieldError.checkNotNull(
              mode, r'DemandeRemise', 'mode'),
          photoCle: photoCle,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
