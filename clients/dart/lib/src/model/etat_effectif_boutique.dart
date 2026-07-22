//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_effectif_boutique.g.dart';

/// État EFFECTIF de la boutique — dérivé, jamais stocké (FR-032).
///
/// Properties:
/// * [ouvert] - La boutique reçoit-elle des commandes en cet instant ?
/// * [reouvertureEstimee] - Prochaine réouverture estimée quand fermée (FR-029).
@BuiltValue()
abstract class EtatEffectifBoutique implements Built<EtatEffectifBoutique, EtatEffectifBoutiqueBuilder> {
  /// La boutique reçoit-elle des commandes en cet instant ?
  @BuiltValueField(wireName: r'ouvert')
  bool get ouvert;

  /// Prochaine réouverture estimée quand fermée (FR-029).
  @BuiltValueField(wireName: r'reouverture_estimee')
  DateTime? get reouvertureEstimee;

  EtatEffectifBoutique._();

  factory EtatEffectifBoutique([void updates(EtatEffectifBoutiqueBuilder b)]) = _$EtatEffectifBoutique;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatEffectifBoutiqueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatEffectifBoutique> get serializer => _$EtatEffectifBoutiqueSerializer();
}

class _$EtatEffectifBoutiqueSerializer implements PrimitiveSerializer<EtatEffectifBoutique> {
  @override
  final Iterable<Type> types = const [EtatEffectifBoutique, _$EtatEffectifBoutique];

  @override
  final String wireName = r'EtatEffectifBoutique';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatEffectifBoutique object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ouvert';
    yield serializers.serialize(
      object.ouvert,
      specifiedType: const FullType(bool),
    );
    if (object.reouvertureEstimee != null) {
      yield r'reouverture_estimee';
      yield serializers.serialize(
        object.reouvertureEstimee,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatEffectifBoutique object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatEffectifBoutiqueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ouvert':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ouvert = valueDes;
          break;
        case r'reouverture_estimee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.reouvertureEstimee = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatEffectifBoutique deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatEffectifBoutiqueBuilder();
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

