// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_verification_one_of.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

const ResultatVerificationOneOfResultatEnum
    _$resultatVerificationOneOfResultatEnum_session =
    const ResultatVerificationOneOfResultatEnum._('session');

ResultatVerificationOneOfResultatEnum
    _$resultatVerificationOneOfResultatEnumValueOf(String name) {
  switch (name) {
    case 'session':
      return _$resultatVerificationOneOfResultatEnum_session;
    default:
      throw ArgumentError(name);
  }
}

final BuiltSet<ResultatVerificationOneOfResultatEnum>
    _$resultatVerificationOneOfResultatEnumValues = BuiltSet<
        ResultatVerificationOneOfResultatEnum>(const <ResultatVerificationOneOfResultatEnum>[
  _$resultatVerificationOneOfResultatEnum_session,
]);

Serializer<ResultatVerificationOneOfResultatEnum>
    _$resultatVerificationOneOfResultatEnumSerializer =
    _$ResultatVerificationOneOfResultatEnumSerializer();

class _$ResultatVerificationOneOfResultatEnumSerializer
    implements PrimitiveSerializer<ResultatVerificationOneOfResultatEnum> {
  static const Map<String, Object> _toWire = const <String, Object>{
    'session': 'session',
  };
  static const Map<Object, String> _fromWire = const <Object, String>{
    'session': 'session',
  };

  @override
  final Iterable<Type> types = const <Type>[
    ResultatVerificationOneOfResultatEnum
  ];
  @override
  final String wireName = 'ResultatVerificationOneOfResultatEnum';

  @override
  Object serialize(
          Serializers serializers, ResultatVerificationOneOfResultatEnum object,
          {FullType specifiedType = FullType.unspecified}) =>
      _toWire[object.name] ?? object.name;

  @override
  ResultatVerificationOneOfResultatEnum deserialize(
          Serializers serializers, Object serialized,
          {FullType specifiedType = FullType.unspecified}) =>
      ResultatVerificationOneOfResultatEnum.valueOf(
          _fromWire[serialized] ?? (serialized is String ? serialized : ''));
}

class _$ResultatVerificationOneOf extends ResultatVerificationOneOf {
  @override
  final CompteMoi compte;
  @override
  final JetonsDto jetons;
  @override
  final ResultatVerificationOneOfResultatEnum resultat;

  factory _$ResultatVerificationOneOf(
          [void Function(ResultatVerificationOneOfBuilder)? updates]) =>
      (ResultatVerificationOneOfBuilder()..update(updates))._build();

  _$ResultatVerificationOneOf._(
      {required this.compte, required this.jetons, required this.resultat})
      : super._();
  @override
  ResultatVerificationOneOf rebuild(
          void Function(ResultatVerificationOneOfBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatVerificationOneOfBuilder toBuilder() =>
      ResultatVerificationOneOfBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatVerificationOneOf &&
        compte == other.compte &&
        jetons == other.jetons &&
        resultat == other.resultat;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, compte.hashCode);
    _$hash = $jc(_$hash, jetons.hashCode);
    _$hash = $jc(_$hash, resultat.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatVerificationOneOf')
          ..add('compte', compte)
          ..add('jetons', jetons)
          ..add('resultat', resultat))
        .toString();
  }
}

class ResultatVerificationOneOfBuilder
    implements
        Builder<ResultatVerificationOneOf, ResultatVerificationOneOfBuilder> {
  _$ResultatVerificationOneOf? _$v;

  CompteMoiBuilder? _compte;
  CompteMoiBuilder get compte => _$this._compte ??= CompteMoiBuilder();
  set compte(CompteMoiBuilder? compte) => _$this._compte = compte;

  JetonsDtoBuilder? _jetons;
  JetonsDtoBuilder get jetons => _$this._jetons ??= JetonsDtoBuilder();
  set jetons(JetonsDtoBuilder? jetons) => _$this._jetons = jetons;

  ResultatVerificationOneOfResultatEnum? _resultat;
  ResultatVerificationOneOfResultatEnum? get resultat => _$this._resultat;
  set resultat(ResultatVerificationOneOfResultatEnum? resultat) =>
      _$this._resultat = resultat;

  ResultatVerificationOneOfBuilder() {
    ResultatVerificationOneOf._defaults(this);
  }

  ResultatVerificationOneOfBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _compte = $v.compte.toBuilder();
      _jetons = $v.jetons.toBuilder();
      _resultat = $v.resultat;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatVerificationOneOf other) {
    _$v = other as _$ResultatVerificationOneOf;
  }

  @override
  void update(void Function(ResultatVerificationOneOfBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatVerificationOneOf build() => _build();

  _$ResultatVerificationOneOf _build() {
    _$ResultatVerificationOneOf _$result;
    try {
      _$result = _$v ??
          _$ResultatVerificationOneOf._(
            compte: compte.build(),
            jetons: jetons.build(),
            resultat: BuiltValueNullFieldError.checkNotNull(
                resultat, r'ResultatVerificationOneOf', 'resultat'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'compte';
        compte.build();
        _$failedField = 'jetons';
        jetons.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ResultatVerificationOneOf', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
