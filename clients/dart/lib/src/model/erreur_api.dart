//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'erreur_api.g.dart';

/// Corps d'erreur du contrat — `{ code, message_cle }`.
///
/// Properties:
/// * [code] - Code stable, exploitable par le client.
/// * [messageCle] - Clé i18n fr — aucune chaîne UI en dur (constitution VII).
@BuiltValue()
abstract class ErreurApi implements Built<ErreurApi, ErreurApiBuilder> {
  /// Code stable, exploitable par le client.
  @BuiltValueField(wireName: r'code')
  String get code;

  /// Clé i18n fr — aucune chaîne UI en dur (constitution VII).
  @BuiltValueField(wireName: r'message_cle')
  String get messageCle;

  ErreurApi._();

  factory ErreurApi([void updates(ErreurApiBuilder b)]) = _$ErreurApi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ErreurApiBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ErreurApi> get serializer => _$ErreurApiSerializer();
}

class _$ErreurApiSerializer implements PrimitiveSerializer<ErreurApi> {
  @override
  final Iterable<Type> types = const [ErreurApi, _$ErreurApi];

  @override
  final String wireName = r'ErreurApi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ErreurApi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
    yield r'message_cle';
    yield serializers.serialize(
      object.messageCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ErreurApi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ErreurApiBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
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
  ErreurApi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ErreurApiBuilder();
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

