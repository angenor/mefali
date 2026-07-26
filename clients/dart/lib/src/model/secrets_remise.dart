//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'secrets_remise.g.dart';

/// Secrets de remise — servis au CLIENT PROPRIÉTAIRE seul (research R6).
///
/// Properties:
/// * [codeLivraison] - Code à 4 chiffres.
/// * [jetonReception] - Jeton encodé dans le QR de réception.
@BuiltValue()
abstract class SecretsRemise implements Built<SecretsRemise, SecretsRemiseBuilder> {
  /// Code à 4 chiffres.
  @BuiltValueField(wireName: r'code_livraison')
  String get codeLivraison;

  /// Jeton encodé dans le QR de réception.
  @BuiltValueField(wireName: r'jeton_reception')
  String get jetonReception;

  SecretsRemise._();

  factory SecretsRemise([void updates(SecretsRemiseBuilder b)]) = _$SecretsRemise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SecretsRemiseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SecretsRemise> get serializer => _$SecretsRemiseSerializer();
}

class _$SecretsRemiseSerializer implements PrimitiveSerializer<SecretsRemise> {
  @override
  final Iterable<Type> types = const [SecretsRemise, _$SecretsRemise];

  @override
  final String wireName = r'SecretsRemise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SecretsRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code_livraison';
    yield serializers.serialize(
      object.codeLivraison,
      specifiedType: const FullType(String),
    );
    yield r'jeton_reception';
    yield serializers.serialize(
      object.jetonReception,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SecretsRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SecretsRemiseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code_livraison':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.codeLivraison = valueDes;
          break;
        case r'jeton_reception':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.jetonReception = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SecretsRemise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SecretsRemiseBuilder();
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

