//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:mefali_api_client/src/model/discriminant_session.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'session_ouverte.g.dart';

/// Session ouverte sur un compte (contrat `SessionOuverte`).  Schéma NOMMÉ et non une variante anonyme du `oneOf` : c'est aussi le corps entier du 201 de `/auth/inscription`, qui n'a qu'une issue possible.
///
/// Properties:
/// * [compte] - Compte connecté.
/// * [jetons] - Jetons de l'appareil.
/// * [resultat] - Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
@BuiltValue()
abstract class SessionOuverte implements Built<SessionOuverte, SessionOuverteBuilder> {
  /// Compte connecté.
  @BuiltValueField(wireName: r'compte')
  CompteMoi get compte;

  /// Jetons de l'appareil.
  @BuiltValueField(wireName: r'jetons')
  JetonsDto get jetons;

  /// Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
  @BuiltValueField(wireName: r'resultat')
  DiscriminantSession get resultat;
  // enum resultatEnum {  session,  };

  SessionOuverte._();

  factory SessionOuverte([void updates(SessionOuverteBuilder b)]) = _$SessionOuverte;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SessionOuverteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SessionOuverte> get serializer => _$SessionOuverteSerializer();
}

class _$SessionOuverteSerializer implements PrimitiveSerializer<SessionOuverte> {
  @override
  final Iterable<Type> types = const [SessionOuverte, _$SessionOuverte];

  @override
  final String wireName = r'SessionOuverte';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SessionOuverte object, {
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
      specifiedType: const FullType(DiscriminantSession),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SessionOuverte object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SessionOuverteBuilder result,
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
            specifiedType: const FullType(DiscriminantSession),
          ) as DiscriminantSession;
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
  SessionOuverte deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SessionOuverteBuilder();
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

