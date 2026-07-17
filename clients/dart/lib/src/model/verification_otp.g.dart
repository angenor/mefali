// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verification_otp.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VerificationOtp extends VerificationOtp {
  @override
  final AppareilDto appareil;
  @override
  final String code;
  @override
  final String telephone;
  @override
  final String zone;

  factory _$VerificationOtp([void Function(VerificationOtpBuilder)? updates]) =>
      (VerificationOtpBuilder()..update(updates))._build();

  _$VerificationOtp._(
      {required this.appareil,
      required this.code,
      required this.telephone,
      required this.zone})
      : super._();
  @override
  VerificationOtp rebuild(void Function(VerificationOtpBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VerificationOtpBuilder toBuilder() => VerificationOtpBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VerificationOtp &&
        appareil == other.appareil &&
        code == other.code &&
        telephone == other.telephone &&
        zone == other.zone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appareil.hashCode);
    _$hash = $jc(_$hash, code.hashCode);
    _$hash = $jc(_$hash, telephone.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VerificationOtp')
          ..add('appareil', appareil)
          ..add('code', code)
          ..add('telephone', telephone)
          ..add('zone', zone))
        .toString();
  }
}

class VerificationOtpBuilder
    implements Builder<VerificationOtp, VerificationOtpBuilder> {
  _$VerificationOtp? _$v;

  AppareilDtoBuilder? _appareil;
  AppareilDtoBuilder get appareil => _$this._appareil ??= AppareilDtoBuilder();
  set appareil(AppareilDtoBuilder? appareil) => _$this._appareil = appareil;

  String? _code;
  String? get code => _$this._code;
  set code(String? code) => _$this._code = code;

  String? _telephone;
  String? get telephone => _$this._telephone;
  set telephone(String? telephone) => _$this._telephone = telephone;

  String? _zone;
  String? get zone => _$this._zone;
  set zone(String? zone) => _$this._zone = zone;

  VerificationOtpBuilder() {
    VerificationOtp._defaults(this);
  }

  VerificationOtpBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appareil = $v.appareil.toBuilder();
      _code = $v.code;
      _telephone = $v.telephone;
      _zone = $v.zone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VerificationOtp other) {
    _$v = other as _$VerificationOtp;
  }

  @override
  void update(void Function(VerificationOtpBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VerificationOtp build() => _build();

  _$VerificationOtp _build() {
    _$VerificationOtp _$result;
    try {
      _$result = _$v ??
          _$VerificationOtp._(
            appareil: appareil.build(),
            code: BuiltValueNullFieldError.checkNotNull(
                code, r'VerificationOtp', 'code'),
            telephone: BuiltValueNullFieldError.checkNotNull(
                telephone, r'VerificationOtp', 'telephone'),
            zone: BuiltValueNullFieldError.checkNotNull(
                zone, r'VerificationOtp', 'zone'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'appareil';
        appareil.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'VerificationOtp', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
