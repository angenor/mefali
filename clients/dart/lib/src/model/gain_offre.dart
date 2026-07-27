//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'gain_offre.g.dart';

/// Le gain, détaillé comme sur K2.
///
/// Properties:
/// * [arretsUnites] - Part des arrêts supplémentaires.
/// * [deplacementUnites] - Part de déplacement.
/// * [devise] - Devise ISO 4217.
/// * [effortUnites] - Part d'effort.
/// * [totalUnites] - Gain total (unités mineures).
@BuiltValue()
abstract class GainOffre implements Built<GainOffre, GainOffreBuilder> {
  /// Part des arrêts supplémentaires.
  @BuiltValueField(wireName: r'arrets_unites')
  int get arretsUnites;

  /// Part de déplacement.
  @BuiltValueField(wireName: r'deplacement_unites')
  int get deplacementUnites;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Part d'effort.
  @BuiltValueField(wireName: r'effort_unites')
  int get effortUnites;

  /// Gain total (unités mineures).
  @BuiltValueField(wireName: r'total_unites')
  int get totalUnites;

  GainOffre._();

  factory GainOffre([void updates(GainOffreBuilder b)]) = _$GainOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GainOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GainOffre> get serializer => _$GainOffreSerializer();
}

class _$GainOffreSerializer implements PrimitiveSerializer<GainOffre> {
  @override
  final Iterable<Type> types = const [GainOffre, _$GainOffre];

  @override
  final String wireName = r'GainOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GainOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrets_unites';
    yield serializers.serialize(
      object.arretsUnites,
      specifiedType: const FullType(int),
    );
    yield r'deplacement_unites';
    yield serializers.serialize(
      object.deplacementUnites,
      specifiedType: const FullType(int),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'effort_unites';
    yield serializers.serialize(
      object.effortUnites,
      specifiedType: const FullType(int),
    );
    yield r'total_unites';
    yield serializers.serialize(
      object.totalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GainOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GainOffreBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrets_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.arretsUnites = valueDes;
          break;
        case r'deplacement_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.deplacementUnites = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'effort_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.effortUnites = valueDes;
          break;
        case r'total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GainOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GainOffreBuilder();
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

