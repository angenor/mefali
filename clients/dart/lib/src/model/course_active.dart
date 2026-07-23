//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/arret_pre_provisionne.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'course_active.g.dart';

/// Course active du coursier + arrêts pré-provisionnés.
///
/// Properties:
/// * [arrets] - Arrêts à collecter, avec empreintes.
/// * [livraisonId] - Livraison active (première des arrêts), `None` si aucune.
@BuiltValue()
abstract class CourseActive implements Built<CourseActive, CourseActiveBuilder> {
  /// Arrêts à collecter, avec empreintes.
  @BuiltValueField(wireName: r'arrets')
  BuiltList<ArretPreProvisionne> get arrets;

  /// Livraison active (première des arrêts), `None` si aucune.
  @BuiltValueField(wireName: r'livraison_id')
  String? get livraisonId;

  CourseActive._();

  factory CourseActive([void updates(CourseActiveBuilder b)]) = _$CourseActive;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CourseActiveBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CourseActive> get serializer => _$CourseActiveSerializer();
}

class _$CourseActiveSerializer implements PrimitiveSerializer<CourseActive> {
  @override
  final Iterable<Type> types = const [CourseActive, _$CourseActive];

  @override
  final String wireName = r'CourseActive';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CourseActive object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrets';
    yield serializers.serialize(
      object.arrets,
      specifiedType: const FullType(BuiltList, [FullType(ArretPreProvisionne)]),
    );
    if (object.livraisonId != null) {
      yield r'livraison_id';
      yield serializers.serialize(
        object.livraisonId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CourseActive object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CourseActiveBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ArretPreProvisionne)]),
          ) as BuiltList<ArretPreProvisionne>;
          result.arrets.replace(valueDes);
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.livraisonId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CourseActive deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CourseActiveBuilder();
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

