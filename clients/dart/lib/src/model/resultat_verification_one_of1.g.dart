// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_verification_one_of1.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ResultatVerificationOneOf1ResultatEnum
    _$resultatVerificationOneOf1ResultatEnum_consentementRequis =
    const ResultatVerificationOneOf1ResultatEnum._('consentementRequis');

ResultatVerificationOneOf1ResultatEnum
    _$resultatVerificationOneOf1ResultatEnumValueOf(String name) {
  switch (name) {
    case 'consentementRequis':
      return _$resultatVerificationOneOf1ResultatEnum_consentementRequis;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ResultatVerificationOneOf1ResultatEnum>
    _$resultatVerificationOneOf1ResultatEnumValues = BuiltSet<
        ResultatVerificationOneOf1ResultatEnum>(const <ResultatVerificationOneOf1ResultatEnum>[
  _$resultatVerificationOneOf1ResultatEnum_consentementRequis,
]);

Serializer<ResultatVerificationOneOf1ResultatEnum>
    _$resultatVerificationOneOf1ResultatEnumSerializer =
    _$ResultatVerificationOneOf1ResultatEnumSerializer();

class _$ResultatVerificationOneOf1ResultatEnumSerializer
    implements PrimitiveSerializer<ResultatVerificationOneOf1ResultatEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'consentementRequis': 'consentement_requis',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'consentement_requis': 'consentementRequis',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ResultatVerificationOneOf1ResultatEnum
  ];
  @override
  final String wireName = 'ResultatVerificationOneOf1ResultatEnum';

  @override
  Object serialize(Serializers serializers,
          ResultatVerificationOneOf1ResultatEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ResultatVerificationOneOf1ResultatEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ResultatVerificationOneOf1ResultatEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ResultatVerificationOneOf1 extends ResultatVerificationOneOf1 {
  @override
  final String jetonInscription;
  @override
  final ResultatVerificationOneOf1ResultatEnum resultat;

  factory _$ResultatVerificationOneOf1(
          [void Function(ResultatVerificationOneOf1Builder)? updates]) =>
      (ResultatVerificationOneOf1Builder()..update(updates))._build();

  _$ResultatVerificationOneOf1._(
      {required this.jetonInscription, required this.resultat})
      : super._();
  @override
  ResultatVerificationOneOf1 rebuild(
          void Function(ResultatVerificationOneOf1Builder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatVerificationOneOf1Builder toBuilder() =>
      ResultatVerificationOneOf1Builder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatVerificationOneOf1 &&
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
    return (newBuiltValueToStringHelper(r'ResultatVerificationOneOf1')
          ..add('jetonInscription', jetonInscription)
          ..add('resultat', resultat))
        .toString();
  }
}

class ResultatVerificationOneOf1Builder
    implements
        Builder<ResultatVerificationOneOf1, ResultatVerificationOneOf1Builder> {
  _$ResultatVerificationOneOf1? _$v;

  String? _jetonInscription;
  String? get jetonInscription => _$this._jetonInscription;
  set jetonInscription(String? jetonInscription) =>
      _$this._jetonInscription = jetonInscription;

  ResultatVerificationOneOf1ResultatEnum? _resultat;
  ResultatVerificationOneOf1ResultatEnum? get resultat => _$this._resultat;
  set resultat(ResultatVerificationOneOf1ResultatEnum? resultat) =>
      _$this._resultat = resultat;

  ResultatVerificationOneOf1Builder() {
    ResultatVerificationOneOf1._defaults(this);
  }

  ResultatVerificationOneOf1Builder get _$this {
    final $v = _$v;
    if ($v != null) {
      _jetonInscription = $v.jetonInscription;
      _resultat = $v.resultat;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatVerificationOneOf1 other) {
    _$v = other as _$ResultatVerificationOneOf1;
  }

  @override
  void update(void Function(ResultatVerificationOneOf1Builder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatVerificationOneOf1 build() => _build();

  _$ResultatVerificationOneOf1 _build() {
    final _$result = _$v ??
        _$ResultatVerificationOneOf1._(
          jetonInscription: BuiltValueNullFieldError.checkNotNull(
              jetonInscription,
              r'ResultatVerificationOneOf1',
              'jetonInscription'),
          resultat: BuiltValueNullFieldError.checkNotNull(
              resultat, r'ResultatVerificationOneOf1', 'resultat'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
