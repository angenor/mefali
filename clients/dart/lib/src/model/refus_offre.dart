//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'refus_offre.g.dart';

/// Résultat d'un refus.
///
/// Properties:
/// * [issue] - Issue de l'offre après refus.
@BuiltValue()
abstract class RefusOffre implements Built<RefusOffre, RefusOffreBuilder> {
  /// Issue de l'offre après refus.
  @BuiltValueField(wireName: r'issue')
  String get issue;

  RefusOffre._();

  factory RefusOffre([void updates(RefusOffreBuilder b)]) = _$RefusOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RefusOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RefusOffre> get serializer => _$RefusOffreSerializer();
}

class _$RefusOffreSerializer implements PrimitiveSerializer<RefusOffre> {
  @override
  final Iterable<Type> types = const [RefusOffre, _$RefusOffre];

  @override
  final String wireName = r'RefusOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RefusOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'issue';
    yield serializers.serialize(
      object.issue,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RefusOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RefusOffreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.issue = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RefusOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RefusOffreBuilder();
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

