//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/escalade_dispatch.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/course_bloquee.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'alertes_dispatch.g.dart';

/// Le tableau d'alertes de l'exploitation.
///
/// Properties:
/// * [coursesBloquees] - Courses assignées sans progression.
/// * [escalades] - Commandes escaladées, **les plus anciennes d'abord**.
@BuiltValue()
abstract class AlertesDispatch implements Built<AlertesDispatch, AlertesDispatchBuilder> {
  /// Courses assignées sans progression.
  @BuiltValueField(wireName: r'courses_bloquees')
  BuiltList<CourseBloquee> get coursesBloquees;

  /// Commandes escaladées, **les plus anciennes d'abord**.
  @BuiltValueField(wireName: r'escalades')
  BuiltList<EscaladeDispatch> get escalades;

  AlertesDispatch._();

  factory AlertesDispatch([void updates(AlertesDispatchBuilder b)]) = _$AlertesDispatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AlertesDispatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AlertesDispatch> get serializer => _$AlertesDispatchSerializer();
}

class _$AlertesDispatchSerializer implements PrimitiveSerializer<AlertesDispatch> {
  @override
  final Iterable<Type> types = const [AlertesDispatch, _$AlertesDispatch];

  @override
  final String wireName = r'AlertesDispatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AlertesDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'courses_bloquees';
    yield serializers.serialize(
      object.coursesBloquees,
      specifiedType: const FullType(BuiltList, [FullType(CourseBloquee)]),
    );
    yield r'escalades';
    yield serializers.serialize(
      object.escalades,
      specifiedType: const FullType(BuiltList, [FullType(EscaladeDispatch)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AlertesDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AlertesDispatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'courses_bloquees':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CourseBloquee)]),
          ) as BuiltList<CourseBloquee>;
          result.coursesBloquees.replace(valueDes);
          break;
        case r'escalades':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(EscaladeDispatch)]),
          ) as BuiltList<EscaladeDispatch>;
          result.escalades.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AlertesDispatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AlertesDispatchBuilder();
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

