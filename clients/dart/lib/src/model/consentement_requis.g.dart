// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'consentement_requis.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ConsentementRequis extends ConsentementRequis {
  @override
  final String jetonInscription;
  @override
  final DiscriminantConsentement resultat;

  factory _$ConsentementRequis(
          [void Function(ConsentementRequisBuilder)? updates]) =>
      (ConsentementRequisBuilder()..update(updates))._build();

  _$ConsentementRequis._(
      {required this.jetonInscription, required this.resultat})
      : super._();
  @override
  ConsentementRequis rebuild(
          void Function(ConsentementRequisBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ConsentementRequisBuilder toBuilder() =>
      ConsentementRequisBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ConsentementRequis &&
        jetonInscription == other.jetonInscription &&
        resultat == other.resultat;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, jetonInscription.hashCode);
    _$hash = $jc(_$hash, resultat.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ConsentementRequis')
          ..add('jetonInscription', jetonInscription)
          ..add('resultat', resultat))
        .toString();
  }
}

class ConsentementRequisBuilder
    implements Builder<ConsentementRequis, ConsentementRequisBuilder> {
  _$ConsentementRequis? _$v;

  String? _jetonInscription;
  String? get jetonInscription => _$this._jetonInscription;
  set jetonInscription(String? jetonInscription) =>
      _$this._jetonInscription = jetonInscription;

  DiscriminantConsentement? _resultat;
  DiscriminantConsentement? get resultat => _$this._resultat;
  set resultat(DiscriminantConsentement? resultat) =>
      _$this._resultat = resultat;

  ConsentementRequisBuilder() {
    ConsentementRequis._defaults(this);
  }

  ConsentementRequisBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jetonInscription = $v.jetonInscription;
      _resultat = $v.resultat;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ConsentementRequis other) {
    _$v = other as _$ConsentementRequis;
  }

  @override
  void update(void Function(ConsentementRequisBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ConsentementRequis build() => _build();

  _$ConsentementRequis _build() {
    final _$result = _$v ??
        _$ConsentementRequis._(
          jetonInscription: BuiltValueNullFieldError.checkNotNull(
              jetonInscription, r'ConsentementRequis', 'jetonInscription'),
          resultat: BuiltValueNullFieldError.checkNotNull(
              resultat, r'ConsentementRequis', 'resultat'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
