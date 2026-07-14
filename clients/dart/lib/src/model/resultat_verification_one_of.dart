//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_verification_one_of.g.dart';

/// Numéro connu — session ouverte.
///
/// Properties:
/// * [compte] - Compte connecté.
/// * [jetons] - Jetons de l'appareil.
/// * [resultat] 
@BuiltValue()
abstract class ResultatVerificationOneOf implements Built<ResultatVerificationOneOf, ResultatVerificationOneOfBuilder> {
  /// Compte connecté.
  @BuiltValueField(wireName: r'compte')
  CompteMoi get compte;

  /// Jetons de l'appareil.
  @BuiltValueField(wireName: r'jetons')
  JetonsDto get jetons;

  @BuiltValueField(wireName: r'resultat')
  ResultatVerificationOneOfResultatEnum get resultat;
  // enum resultatEnum {  session,  };

  ResultatVerificationOneOf._();

  factory ResultatVerificationOneOf([void updates(ResultatVerificationOneOfBuilder b)]) = _$ResultatVerificationOneOf;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatVerificationOneOfBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatVerificationOneOf> get serializer => _$ResultatVerificationOneOfSerializer();
}

class _$ResultatVerificationOneOfSerializer implements PrimitiveSerializer<ResultatVerificationOneOf> {
  @override
  final Iterable<Type> types = const [ResultatVerificationOneOf, _$ResultatVerificationOneOf];

  @override
  final String wireName = r'ResultatVerificationOneOf';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatVerificationOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'compte';
    yield serializers.serialize(
      object.compte,
      specifiedType: const FullType(CompteMoi),
    );
    yield r'jetons';
    yield serializers.serialize(
      object.jetons,
      specifiedType: const FullType(JetonsDto),
    );
    yield r'resultat';
    yield serializers.serialize(
      object.resultat,
      specifiedType: const FullType(ResultatVerificationOneOfResultatEnum),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatVerificationOneOf object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatVerificationOneOfBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'compte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(CompteMoi),
          ) as CompteMoi;
          result.compte.replace(valueDes);
          break;
        case r'jetons':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(JetonsDto),
          ) as JetonsDto;
          result.jetons.replace(valueDes);
          break;
        case r'resultat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ResultatVerificationOneOfResultatEnum),
          ) as ResultatVerificationOneOfResultatEnum;
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
  ResultatVerificationOneOf deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatVerificationOneOfBuilder();
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

class ResultatVerificationOneOfResultatEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'session')
  static const ResultatVerificationOneOfResultatEnum session = _$resultatVerificationOneOfResultatEnum_session;

  static Serializer<ResultatVerificationOneOfResultatEnum> get serializer => _$resultatVerificationOneOfResultatEnumSerializer;

  const ResultatVerificationOneOfResultatEnum._(String name): super(name);

  static BuiltSet<ResultatVerificationOneOfResultatEnum> get values => _$resultatVerificationOneOfResultatEnumValues;
  static ResultatVerificationOneOfResultatEnum valueOf(String name) => _$resultatVerificationOneOfResultatEnumValueOf(name);
}

