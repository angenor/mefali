//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'arret_offre.g.dart';

/// Un arrêt de l'offre, tel que K2 l'affiche.
///
/// Properties:
/// * [distanceM] - Distance INTER-ARRÊTS (mètres) — « + 40 m » de la maquette.
/// * [nom] - Nom affiché sur la carte.
/// * [ordre] - Rang d'affichage (1 = premier arrêt).
/// * [prestataireId] - Prestataire visé.
@BuiltValue()
abstract class ArretOffre implements Built<ArretOffre, ArretOffreBuilder> {
  /// Distance INTER-ARRÊTS (mètres) — « + 40 m » de la maquette.
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Nom affiché sur la carte.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Rang d'affichage (1 = premier arrêt).
  @BuiltValueField(wireName: r'ordre')
  int get ordre;

  /// Prestataire visé.
  @BuiltValueField(wireName: r'prestataire_id')
  String? get prestataireId;

  ArretOffre._();

  factory ArretOffre([void updates(ArretOffreBuilder b)]) = _$ArretOffre;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArretOffreBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArretOffre> get serializer => _$ArretOffreSerializer();
}

class _$ArretOffreSerializer implements PrimitiveSerializer<ArretOffre> {
  @override
  final Iterable<Type> types = const [ArretOffre, _$ArretOffre];

  @override
  final String wireName = r'ArretOffre';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArretOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'distance_m';
    yield serializers.serialize(
      object.distanceM,
      specifiedType: const FullType(int),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'ordre';
    yield serializers.serialize(
      object.ordre,
      specifiedType: const FullType(int),
    );
    if (object.prestataireId != null) {
      yield r'prestataire_id';
      yield serializers.serialize(
        object.prestataireId,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ArretOffre object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArretOffreBuilder result,
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
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'ordre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ordre = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.prestataireId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ArretOffre deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArretOffreBuilder();
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

