// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_otp.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeOtp extends DemandeOtp {
  @override
  final String telephone;
  @override
  final String zone;

  factory _$DemandeOtp([void Function(DemandeOtpBuilder)? updates]) =>
      (DemandeOtpBuilder()..update(updates))._build();

  _$DemandeOtp._({required this.telephone, required this.zone}) : super._();
  @override
  DemandeOtp rebuild(void Function(DemandeOtpBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeOtpBuilder toBuilder() => DemandeOtpBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeOtp &&
        telephone == other.telephone &&
        zone == other.zone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, telephone.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeOtp')
          ..add('telephone', telephone)
          ..add('zone', zone))
        .toString();
  }
}

class DemandeOtpBuilder implements Builder<DemandeOtp, DemandeOtpBuilder> {
  _$DemandeOtp? _$v;

  String? _telephone;
  String? get telephone => _$this._telephone;
  set telephone(String? telephone) => _$this._telephone = telephone;

  String? _zone;
  String? get zone => _$this._zone;
  set zone(String? zone) => _$this._zone = zone;

  DemandeOtpBuilder() {
    DemandeOtp._defaults(this);
  }

  DemandeOtpBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _telephone = $v.telephone;
      _zone = $v.zone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeOtp other) {
    _$v = other as _$DemandeOtp;
  }

  @override
  void update(void Function(DemandeOtpBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeOtp build() => _build();

  _$DemandeOtp _build() {
    final _$result = _$v ??
        _$DemandeOtp._(
          telephone: BuiltValueNullFieldError.checkNotNull(
              telephone, r'DemandeOtp', 'telephone'),
          zone: BuiltValueNullFieldError.checkNotNull(
              zone, r'DemandeOtp', 'zone'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
