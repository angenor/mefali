//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_reprise.g.dart';

/// Demande de reprise manuelle — **motif obligatoire**.
///
/// Properties:
/// * [motif] - Pourquoi l'exploitation reprend cette course. Journalisé avec son auteur.
@BuiltValue()
abstract class DemandeReprise implements Built<DemandeReprise, DemandeRepriseBuilder> {
  /// Pourquoi l'exploitation reprend cette course. Journalisé avec son auteur.
  @BuiltValueField(wireName: r'motif')
  String get motif;

  DemandeReprise._();

  factory DemandeReprise([void updates(DemandeRepriseBuilder b)]) = _$DemandeReprise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeRepriseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeReprise> get serializer => _$DemandeRepriseSerializer();
}

class _$DemandeRepriseSerializer implements PrimitiveSerializer<DemandeReprise> {
  @override
  final Iterable<Type> types = const [DemandeReprise, _$DemandeReprise];

  @override
  final String wireName = r'DemandeReprise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeReprise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'motif';
    yield serializers.serialize(
      object.motif,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeReprise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeRepriseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motif = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeReprise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeRepriseBuilder();
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

