// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'inscription.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Inscription extends Inscription {
  @override
  final String consentementVersion;
  @override
  final String jetonInscription;

  factory _$Inscription([void Function(InscriptionBuilder)? updates]) =>
      (InscriptionBuilder()..update(updates))._build();

  _$Inscription._(
      {required this.consentementVersion, required this.jetonInscription})
      : super._();
  @override
  Inscription rebuild(void Function(InscriptionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  InscriptionBuilder toBuilder() => InscriptionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Inscription &&
        consentementVersion == other.consentementVersion &&
        jetonInscription == other.jetonInscription;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, consentementVersion.hashCode);
    _$hash = $jc(_$hash, jetonInscription.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Inscription')
          ..add('consentementVersion', consentementVersion)
          ..add('jetonInscription', jetonInscription))
        .toString();
  }
}

class InscriptionBuilder implements Builder<Inscription, InscriptionBuilder> {
  _$Inscription? _$v;

  String? _consentementVersion;
  String? get consentementVersion => _$this._consentementVersion;
  set consentementVersion(String? consentementVersion) =>
      _$this._consentementVersion = consentementVersion;

  String? _jetonInscription;
  String? get jetonInscription => _$this._jetonInscription;
  set jetonInscription(String? jetonInscription) =>
      _$this._jetonInscription = jetonInscription;

  InscriptionBuilder() {
    Inscription._defaults(this);
  }

  InscriptionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _consentementVersion = $v.consentementVersion;
      _jetonInscription = $v.jetonInscription;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Inscription other) {
    _$v = other as _$Inscription;
  }

  @override
  void update(void Function(InscriptionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Inscription build() => _build();

  _$Inscription _build() {
    final _$result = _$v ??
        _$Inscription._(
          consentementVersion: BuiltValueNullFieldError.checkNotNull(
              consentementVersion, r'Inscription', 'consentementVersion'),
          jetonInscription: BuiltValueNullFieldError.checkNotNull(
              jetonInscription, r'Inscription', 'jetonInscription'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
