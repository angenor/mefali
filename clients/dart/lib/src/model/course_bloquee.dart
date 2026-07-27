//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'course_bloquee.g.dart';

/// Une course assignée qui n'avance pas (FR-075).
///
/// Properties:
/// * [commandeId] - Commande concernée.
/// * [coursierId] - Coursier assigné.
/// * [livraisonId] - Livraison concernée.
/// * [motif] - Critère constaté : `sans_mouvement` | `sans_scan`.
/// * [nbArretsCollectes] - Arrêts déjà collectés. **`> 0` ⇒ aucune reprise automatique possible.**
/// * [repriseAutomatiquePossible] - Faux quand un arrêt est collecté : seule une décision humaine motivée peut alors trancher, parce que le coursier a engagé ses fonds propres.
/// * [stagnationS] - Durée de stagnation constatée (secondes).
@BuiltValue()
abstract class CourseBloquee implements Built<CourseBloquee, CourseBloqueeBuilder> {
  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Coursier assigné.
  @BuiltValueField(wireName: r'coursier_id')
  String? get coursierId;

  /// Livraison concernée.
  @BuiltValueField(wireName: r'livraison_id')
  String get livraisonId;

  /// Critère constaté : `sans_mouvement` | `sans_scan`.
  @BuiltValueField(wireName: r'motif')
  String get motif;

  /// Arrêts déjà collectés. **`> 0` ⇒ aucune reprise automatique possible.**
  @BuiltValueField(wireName: r'nb_arrets_collectes')
  int get nbArretsCollectes;

  /// Faux quand un arrêt est collecté : seule une décision humaine motivée peut alors trancher, parce que le coursier a engagé ses fonds propres.
  @BuiltValueField(wireName: r'reprise_automatique_possible')
  bool get repriseAutomatiquePossible;

  /// Durée de stagnation constatée (secondes).
  @BuiltValueField(wireName: r'stagnation_s')
  int get stagnationS;

  CourseBloquee._();

  factory CourseBloquee([void updates(CourseBloqueeBuilder b)]) = _$CourseBloquee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CourseBloqueeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CourseBloquee> get serializer => _$CourseBloqueeSerializer();
}

class _$CourseBloqueeSerializer implements PrimitiveSerializer<CourseBloquee> {
  @override
  final Iterable<Type> types = const [CourseBloquee, _$CourseBloquee];

  @override
  final String wireName = r'CourseBloquee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CourseBloquee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    if (object.coursierId != null) {
      yield r'coursier_id';
      yield serializers.serialize(
        object.coursierId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'livraison_id';
    yield serializers.serialize(
      object.livraisonId,
      specifiedType: const FullType(String),
    );
    yield r'motif';
    yield serializers.serialize(
      object.motif,
      specifiedType: const FullType(String),
    );
    yield r'nb_arrets_collectes';
    yield serializers.serialize(
      object.nbArretsCollectes,
      specifiedType: const FullType(int),
    );
    yield r'reprise_automatique_possible';
    yield serializers.serialize(
      object.repriseAutomatiquePossible,
      specifiedType: const FullType(bool),
    );
    yield r'stagnation_s';
    yield serializers.serialize(
      object.stagnationS,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CourseBloquee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CourseBloqueeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'coursier_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.coursierId = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.livraisonId = valueDes;
          break;
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motif = valueDes;
          break;
        case r'nb_arrets_collectes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbArretsCollectes = valueDes;
          break;
        case r'reprise_automatique_possible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.repriseAutomatiquePossible = valueDes;
          break;
        case r'stagnation_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.stagnationS = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CourseBloquee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CourseBloqueeBuilder();
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

