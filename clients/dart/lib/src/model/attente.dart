//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'attente.g.dart';

/// Attente constatée à un arrêt — les DEUX horodatages sont requis, sinon la prime vaut 0 (FR-029 : jamais inventée).
///
/// Properties:
/// * [arrivee] - Arrivée géolocalisée du coursier.
/// * [scan] - Scan QR de la plaque (fin d'attente).
@BuiltValue()
abstract class Attente implements Built<Attente, AttenteBuilder> {
  /// Arrivée géolocalisée du coursier.
  @BuiltValueField(wireName: r'arrivee')
  DateTime get arrivee;

  /// Scan QR de la plaque (fin d'attente).
  @BuiltValueField(wireName: r'scan')
  DateTime get scan;

  Attente._();

  factory Attente([void updates(AttenteBuilder b)]) = _$Attente;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AttenteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Attente> get serializer => _$AttenteSerializer();
}

class _$AttenteSerializer implements PrimitiveSerializer<Attente> {
  @override
  final Iterable<Type> types = const [Attente, _$Attente];

  @override
  final String wireName = r'Attente';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Attente object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrivee';
    yield serializers.serialize(
      object.arrivee,
      specifiedType: const FullType(DateTime),
    );
    yield r'scan';
    yield serializers.serialize(
      object.scan,
      specifiedType: const FullType(DateTime),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Attente object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AttenteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrivee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.arrivee = valueDes;
          break;
        case r'scan':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.scan = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Attente deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AttenteBuilder();
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

