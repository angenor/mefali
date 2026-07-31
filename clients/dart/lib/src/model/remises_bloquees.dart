//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/remise_bloquee.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'remises_bloquees.g.dart';

/// La file des blocages d'une zone.
///
/// Properties:
/// * [remises] - Commandes bloquées, **la plus ancienne d'abord**.
@BuiltValue()
abstract class RemisesBloquees implements Built<RemisesBloquees, RemisesBloqueesBuilder> {
  /// Commandes bloquées, **la plus ancienne d'abord**.
  @BuiltValueField(wireName: r'remises')
  BuiltList<RemiseBloquee> get remises;

  RemisesBloquees._();

  factory RemisesBloquees([void updates(RemisesBloqueesBuilder b)]) = _$RemisesBloquees;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RemisesBloqueesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RemisesBloquees> get serializer => _$RemisesBloqueesSerializer();
}

class _$RemisesBloqueesSerializer implements PrimitiveSerializer<RemisesBloquees> {
  @override
  final Iterable<Type> types = const [RemisesBloquees, _$RemisesBloquees];

  @override
  final String wireName = r'RemisesBloquees';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RemisesBloquees object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'remises';
    yield serializers.serialize(
      object.remises,
      specifiedType: const FullType(BuiltList, [FullType(RemiseBloquee)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RemisesBloquees object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RemisesBloqueesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'remises':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(RemiseBloquee)]),
          ) as BuiltList<RemiseBloquee>;
          result.remises.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RemisesBloquees deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RemisesBloqueesBuilder();
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

