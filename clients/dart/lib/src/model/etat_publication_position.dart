//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_publication_position.g.dart';

/// Ce que la publication rend à l'app.
///
/// Properties:
/// * [dansLePool] - Vrai si le coursier est (re)devenu membre du pool.
/// * [prochainePublicationS] - Période attendue de la prochaine publication (secondes).
/// * [ttlS] - Durée de vie de l'inscription (secondes) — trois périodes manquées.
@BuiltValue()
abstract class EtatPublicationPosition implements Built<EtatPublicationPosition, EtatPublicationPositionBuilder> {
  /// Vrai si le coursier est (re)devenu membre du pool.
  @BuiltValueField(wireName: r'dans_le_pool')
  bool get dansLePool;

  /// Période attendue de la prochaine publication (secondes).
  @BuiltValueField(wireName: r'prochaine_publication_s')
  int get prochainePublicationS;

  /// Durée de vie de l'inscription (secondes) — trois périodes manquées.
  @BuiltValueField(wireName: r'ttl_s')
  int get ttlS;

  EtatPublicationPosition._();

  factory EtatPublicationPosition([void updates(EtatPublicationPositionBuilder b)]) = _$EtatPublicationPosition;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatPublicationPositionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatPublicationPosition> get serializer => _$EtatPublicationPositionSerializer();
}

class _$EtatPublicationPositionSerializer implements PrimitiveSerializer<EtatPublicationPosition> {
  @override
  final Iterable<Type> types = const [EtatPublicationPosition, _$EtatPublicationPosition];

  @override
  final String wireName = r'EtatPublicationPosition';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatPublicationPosition object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'dans_le_pool';
    yield serializers.serialize(
      object.dansLePool,
      specifiedType: const FullType(bool),
    );
    yield r'prochaine_publication_s';
    yield serializers.serialize(
      object.prochainePublicationS,
      specifiedType: const FullType(int),
    );
    yield r'ttl_s';
    yield serializers.serialize(
      object.ttlS,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatPublicationPosition object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatPublicationPositionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'dans_le_pool':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.dansLePool = valueDes;
          break;
        case r'prochaine_publication_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prochainePublicationS = valueDes;
          break;
        case r'ttl_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ttlS = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatPublicationPosition deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatPublicationPositionBuilder();
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

