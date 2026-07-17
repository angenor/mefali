//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'inscription.g.dart';

/// Corps de `POST /auth/inscription`.
///
/// Properties:
/// * [consentementVersion] - Version du texte ARTCI accepté — servie par la config de zone.
/// * [jetonInscription] - Émis par `/auth/otp/verifier`, usage unique, TTL 10 min.
@BuiltValue()
abstract class Inscription implements Built<Inscription, InscriptionBuilder> {
  /// Version du texte ARTCI accepté — servie par la config de zone.
  @BuiltValueField(wireName: r'consentement_version')
  String get consentementVersion;

  /// Émis par `/auth/otp/verifier`, usage unique, TTL 10 min.
  @BuiltValueField(wireName: r'jeton_inscription')
  String get jetonInscription;

  Inscription._();

  factory Inscription([void updates(InscriptionBuilder b)]) = _$Inscription;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(InscriptionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Inscription> get serializer => _$InscriptionSerializer();
}

class _$InscriptionSerializer implements PrimitiveSerializer<Inscription> {
  @override
  final Iterable<Type> types = const [Inscription, _$Inscription];

  @override
  final String wireName = r'Inscription';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Inscription object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'consentement_version';
    yield serializers.serialize(
      object.consentementVersion,
      specifiedType: const FullType(String),
    );
    yield r'jeton_inscription';
    yield serializers.serialize(
      object.jetonInscription,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Inscription object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required InscriptionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'consentement_version':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.consentementVersion = valueDes;
          break;
        case r'jeton_inscription':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jetonInscription = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Inscription deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = InscriptionBuilder();
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

