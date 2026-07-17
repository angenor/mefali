//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/discriminant_consentement.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'consentement_requis.g.dart';

/// Consentement ARTCI exigé avant création du compte (contrat `ConsentementRequis`, FR-006).
///
/// Properties:
/// * [jetonInscription] - Jeton d'inscription à usage unique.
/// * [resultat] - Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
@BuiltValue()
abstract class ConsentementRequis implements Built<ConsentementRequis, ConsentementRequisBuilder> {
  /// Jeton d'inscription à usage unique.
  @BuiltValueField(wireName: r'jeton_inscription')
  String get jetonInscription;

  /// Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
  @BuiltValueField(wireName: r'resultat')
  DiscriminantConsentement get resultat;
  // enum resultatEnum {  consentement_requis,  };

  ConsentementRequis._();

  factory ConsentementRequis([void updates(ConsentementRequisBuilder b)]) = _$ConsentementRequis;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ConsentementRequisBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ConsentementRequis> get serializer => _$ConsentementRequisSerializer();
}

class _$ConsentementRequisSerializer implements PrimitiveSerializer<ConsentementRequis> {
  @override
  final Iterable<Type> types = const [ConsentementRequis, _$ConsentementRequis];

  @override
  final String wireName = r'ConsentementRequis';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ConsentementRequis object, {
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
      specifiedType: const FullType(DiscriminantConsentement),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ConsentementRequis object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ConsentementRequisBuilder result,
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
            specifiedType: const FullType(DiscriminantConsentement),
          ) as DiscriminantConsentement;
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
  ConsentementRequis deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ConsentementRequisBuilder();
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

