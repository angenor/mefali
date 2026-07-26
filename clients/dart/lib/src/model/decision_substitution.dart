//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decision_substitution.g.dart';

/// Décision du client sur une proposition de remplacement.
///
/// Properties:
/// * [accepte] - `true` = accepter le remplacement, `false` = le refuser (l'article est alors retiré, et rien n'est payé pour lui).
@BuiltValue()
abstract class DecisionSubstitution implements Built<DecisionSubstitution, DecisionSubstitutionBuilder> {
  /// `true` = accepter le remplacement, `false` = le refuser (l'article est alors retiré, et rien n'est payé pour lui).
  @BuiltValueField(wireName: r'accepte')
  bool get accepte;

  DecisionSubstitution._();

  factory DecisionSubstitution([void updates(DecisionSubstitutionBuilder b)]) = _$DecisionSubstitution;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecisionSubstitutionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecisionSubstitution> get serializer => _$DecisionSubstitutionSerializer();
}

class _$DecisionSubstitutionSerializer implements PrimitiveSerializer<DecisionSubstitution> {
  @override
  final Iterable<Type> types = const [DecisionSubstitution, _$DecisionSubstitution];

  @override
  final String wireName = r'DecisionSubstitution';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecisionSubstitution object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'accepte';
    yield serializers.serialize(
      object.accepte,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DecisionSubstitution object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecisionSubstitutionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'accepte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.accepte = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DecisionSubstitution deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecisionSubstitutionBuilder();
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

