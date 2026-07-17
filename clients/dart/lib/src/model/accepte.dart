//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'accepte.g.dart';

/// Réponse UNIQUE de `/auth/otp/demander`.
///
/// Properties:
/// * [messageCle] - Toujours `comptes.otp.envoye_si_valide`.
@BuiltValue()
abstract class Accepte implements Built<Accepte, AccepteBuilder> {
  /// Toujours `comptes.otp.envoye_si_valide`.
  @BuiltValueField(wireName: r'message_cle')
  String get messageCle;

  Accepte._();

  factory Accepte([void updates(AccepteBuilder b)]) = _$Accepte;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AccepteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Accepte> get serializer => _$AccepteSerializer();
}

class _$AccepteSerializer implements PrimitiveSerializer<Accepte> {
  @override
  final Iterable<Type> types = const [Accepte, _$Accepte];

  @override
  final String wireName = r'Accepte';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Accepte object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message_cle';
    yield serializers.serialize(
      object.messageCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Accepte object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AccepteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.messageCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Accepte deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AccepteBuilder();
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

