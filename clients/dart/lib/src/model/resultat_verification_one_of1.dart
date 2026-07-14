//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_verification_one_of1.g.dart';

/// Numéro inconnu — consentement ARTCI exigé avant création (FR-006).
///
/// Properties:
/// * [jetonInscription] - Jeton d'inscription à usage unique.
/// * [resultat] 
@BuiltValue()
abstract class ResultatVerificationOneOf1 implements Built<ResultatVerificationOneOf1, ResultatVerificationOneOf1Builder> {
  /// Jeton d'inscription à usage unique.
  @BuiltValueField(wireName: r'jeton_inscription')
  String get jetonInscription;

  @BuiltValueField(wireName: r'resultat')
  ResultatVerificationOneOf1ResultatEnum get resultat;
  // enum resultatEnum {  consentement_requis,  };

  ResultatVerificationOneOf1._();

  factory ResultatVerificationOneOf1([void updates(ResultatVerificationOneOf1Builder b)]) = _$ResultatVerificationOneOf1;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatVerificationOneOf1Builder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatVerificationOneOf1> get serializer => _$ResultatVerificationOneOf1Serializer();
}

class _$ResultatVerificationOneOf1Serializer implements PrimitiveSerializer<ResultatVerificationOneOf1> {
  @override
  final Iterable<Type> types = const [ResultatVerificationOneOf1, _$ResultatVerificationOneOf1];

  @override
  final String wireName = r'ResultatVerificationOneOf1';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatVerificationOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'jeton_inscription';
    yield serializers.serialize(
      object.jetonInscription,
      specifiedType: const FullType(String),
    );
    yield r'resultat';
    yield serializers.serialize(
      object.resultat,
      specifiedType: const FullType(ResultatVerificationOneOf1ResultatEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatVerificationOneOf1 object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatVerificationOneOf1Builder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'jeton_inscription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jetonInscription = valueDes;
          break;
        case r'resultat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ResultatVerificationOneOf1ResultatEnum),
          ) as ResultatVerificationOneOf1ResultatEnum;
          result.resultat = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResultatVerificationOneOf1 deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatVerificationOneOf1Builder();
    final serializedList = (serialized as Iterable<Object?>).toList();
    final unhandled = <Object?>[];
    _deserializeProperties(
      serializers,
      serialized,
      specifiedType: specifiedType,
      serializedList: serializedList,
      unhandled: unhandled,
      result: result,
    );
    return result.build();
  }
}

class ResultatVerificationOneOf1ResultatEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'consentement_requis')
  static const ResultatVerificationOneOf1ResultatEnum consentementRequis = _$resultatVerificationOneOf1ResultatEnum_consentementRequis;

  static Serializer<ResultatVerificationOneOf1ResultatEnum> get serializer => _$resultatVerificationOneOf1ResultatEnumSerializer;

  const ResultatVerificationOneOf1ResultatEnum._(String name): super(name);

  static BuiltSet<ResultatVerificationOneOf1ResultatEnum> get values => _$resultatVerificationOneOf1ResultatEnumValues;
  static ResultatVerificationOneOf1ResultatEnum valueOf(String name) => _$resultatVerificationOneOf1ResultatEnumValueOf(name);
}

