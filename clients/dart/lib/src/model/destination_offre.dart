//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'destination_offre.g.dart';

/// La destination, **avant** acceptation : jamais de coordonnée (ARTCI).
///
/// Properties:
/// * [distanceM] - Distance approximative depuis le dernier arrêt (mètres arrondis).
/// * [mentionCle] - Clé i18n de la mention « adresse exacte après acceptation ».
/// * [zoneNom] - Nom de la zone de livraison.
@BuiltValue()
abstract class DestinationOffre implements Built<DestinationOffre, DestinationOffreBuilder> {
  /// Distance approximative depuis le dernier arrêt (mètres arrondis).
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Clé i18n de la mention « adresse exacte après acceptation ».
  @BuiltValueField(wireName: r'mention_cle')
  String get mentionCle;

  /// Nom de la zone de livraison.
  @BuiltValueField(wireName: r'zone_nom')
  String get zoneNom;

  DestinationOffre._();

  factory DestinationOffre([void updates(DestinationOffreBuilder b)]) = _$DestinationOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DestinationOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DestinationOffre> get serializer => _$DestinationOffreSerializer();
}

class _$DestinationOffreSerializer implements PrimitiveSerializer<DestinationOffre> {
  @override
  final Iterable<Type> types = const [DestinationOffre, _$DestinationOffre];

  @override
  final String wireName = r'DestinationOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DestinationOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'distance_m';
    yield serializers.serialize(
      object.distanceM,
      specifiedType: const FullType(int),
    );
    yield r'mention_cle';
    yield serializers.serialize(
      object.mentionCle,
      specifiedType: const FullType(String),
    );
    yield r'zone_nom';
    yield serializers.serialize(
      object.zoneNom,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DestinationOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DestinationOffreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'distance_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceM = valueDes;
          break;
        case r'mention_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mentionCle = valueDes;
          break;
        case r'zone_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneNom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DestinationOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DestinationOffreBuilder();
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

