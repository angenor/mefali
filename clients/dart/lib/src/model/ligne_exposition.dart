//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_exposition.g.dart';

/// L'exposition d'un coursier.
///
/// Properties:
/// * [avanceUnites] - Avance en cours (unités mineures, positif).
/// * [courses] - Courses concernées.
/// * [coursierId] - Coursier.
/// * [nom] - Nom d'usage. **Vide** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — un nom fabriqué depuis le numéro serait pire qu'une absence.
@BuiltValue()
abstract class LigneExposition implements Built<LigneExposition, LigneExpositionBuilder> {
  /// Avance en cours (unités mineures, positif).
  @BuiltValueField(wireName: r'avance_unites')
  int get avanceUnites;

  /// Courses concernées.
  @BuiltValueField(wireName: r'courses')
  int get courses;

  /// Coursier.
  @BuiltValueField(wireName: r'coursier_id')
  String get coursierId;

  /// Nom d'usage. **Vide** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — un nom fabriqué depuis le numéro serait pire qu'une absence.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  LigneExposition._();

  factory LigneExposition([void updates(LigneExpositionBuilder b)]) = _$LigneExposition;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneExpositionBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneExposition> get serializer => _$LigneExpositionSerializer();
}

class _$LigneExpositionSerializer implements PrimitiveSerializer<LigneExposition> {
  @override
  final Iterable<Type> types = const [LigneExposition, _$LigneExposition];

  @override
  final String wireName = r'LigneExposition';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneExposition object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'avance_unites';
    yield serializers.serialize(
      object.avanceUnites,
      specifiedType: const FullType(int),
    );
    yield r'courses';
    yield serializers.serialize(
      object.courses,
      specifiedType: const FullType(int),
    );
    yield r'coursier_id';
    yield serializers.serialize(
      object.coursierId,
      specifiedType: const FullType(String),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneExposition object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneExpositionBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'avance_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.avanceUnites = valueDes;
          break;
        case r'courses':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.courses = valueDes;
          break;
        case r'coursier_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.coursierId = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneExposition deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneExpositionBuilder();
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

