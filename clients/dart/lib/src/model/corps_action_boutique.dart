//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/action_boutique_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'corps_action_boutique.g.dart';

/// Corps du geste de boutique.
///
/// Properties:
/// * [action] - Le geste.
/// * [dureeMinutes] - Durée en minutes — REQUISE pour `mettre_en_pause` et `prolonger_pause` (30/60/120 et +30 côté app, constantes MVP).
@BuiltValue()
abstract class CorpsActionBoutique implements Built<CorpsActionBoutique, CorpsActionBoutiqueBuilder> {
  /// Le geste.
  @BuiltValueField(wireName: r'action')
  ActionBoutiqueDto get action;
  // enum actionEnum {  ouvrir,  fermer,  mettre_en_pause,  prolonger_pause,  fermer_pour_la_journee,  };

  /// Durée en minutes — REQUISE pour `mettre_en_pause` et `prolonger_pause` (30/60/120 et +30 côté app, constantes MVP).
  @BuiltValueField(wireName: r'duree_minutes')
  int? get dureeMinutes;

  CorpsActionBoutique._();

  factory CorpsActionBoutique([void updates(CorpsActionBoutiqueBuilder b)]) = _$CorpsActionBoutique;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CorpsActionBoutiqueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CorpsActionBoutique> get serializer => _$CorpsActionBoutiqueSerializer();
}

class _$CorpsActionBoutiqueSerializer implements PrimitiveSerializer<CorpsActionBoutique> {
  @override
  final Iterable<Type> types = const [CorpsActionBoutique, _$CorpsActionBoutique];

  @override
  final String wireName = r'CorpsActionBoutique';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CorpsActionBoutique object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'action';
    yield serializers.serialize(
      object.action,
      specifiedType: const FullType(ActionBoutiqueDto),
    );
    if (object.dureeMinutes != null) {
      yield r'duree_minutes';
      yield serializers.serialize(
        object.dureeMinutes,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CorpsActionBoutique object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CorpsActionBoutiqueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'action':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ActionBoutiqueDto),
          ) as ActionBoutiqueDto;
          result.action = valueDes;
          break;
        case r'duree_minutes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.dureeMinutes = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CorpsActionBoutique deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CorpsActionBoutiqueBuilder();
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

