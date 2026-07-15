//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/action_role_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decision_role.g.dart';

/// Corps de la décision.
///
/// Properties:
/// * [action] - Action à appliquer.
/// * [motif] - Motif — REQUIS pour `refuser` et `suspendre` (FR-017).
@BuiltValue()
abstract class DecisionRole implements Built<DecisionRole, DecisionRoleBuilder> {
  /// Action à appliquer.
  @BuiltValueField(wireName: r'action')
  ActionRoleDto get action;
  // enum actionEnum {  attribuer,  valider,  refuser,  suspendre,  retablir,  };

  /// Motif — REQUIS pour `refuser` et `suspendre` (FR-017).
  @BuiltValueField(wireName: r'motif')
  String? get motif;

  DecisionRole._();

  factory DecisionRole([void updates(DecisionRoleBuilder b)]) = _$DecisionRole;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecisionRoleBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecisionRole> get serializer => _$DecisionRoleSerializer();
}

class _$DecisionRoleSerializer implements PrimitiveSerializer<DecisionRole> {
  @override
  final Iterable<Type> types = const [DecisionRole, _$DecisionRole];

  @override
  final String wireName = r'DecisionRole';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecisionRole object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(ActionRoleDto),
    );
    if (object.motif != null) {
      yield r'motif';
      yield serializers.serialize(
        object.motif,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DecisionRole object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecisionRoleBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ActionRoleDto),
          ) as ActionRoleDto;
          result.action = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
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
  DecisionRole deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecisionRoleBuilder();
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

