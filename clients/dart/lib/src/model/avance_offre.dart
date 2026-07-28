//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'avance_offre.g.dart';

/// Ce que le coursier devra avancer, avec son plafond.
///
/// Properties:
/// * [devise] - Devise ISO 4217.
/// * [montantUnites] - Montant à avancer (unités mineures).
/// * [plafondRetenuUnites] - Plafond RETENU du coursier — pourquoi il peut la prendre.
@BuiltValue()
abstract class AvanceOffre implements Built<AvanceOffre, AvanceOffreBuilder> {
  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Montant à avancer (unités mineures).
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Plafond RETENU du coursier — pourquoi il peut la prendre.
  @BuiltValueField(wireName: r'plafond_retenu_unites')
  int get plafondRetenuUnites;

  AvanceOffre._();

  factory AvanceOffre([void updates(AvanceOffreBuilder b)]) = _$AvanceOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AvanceOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AvanceOffre> get serializer => _$AvanceOffreSerializer();
}

class _$AvanceOffreSerializer implements PrimitiveSerializer<AvanceOffre> {
  @override
  final Iterable<Type> types = const [AvanceOffre, _$AvanceOffre];

  @override
  final String wireName = r'AvanceOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AvanceOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    yield r'plafond_retenu_unites';
    yield serializers.serialize(
      object.plafondRetenuUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AvanceOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AvanceOffreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'plafond_retenu_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plafondRetenuUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AvanceOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AvanceOffreBuilder();
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

