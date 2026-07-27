//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'coursier_du_pool.g.dart';

/// Un coursier du pool, tel que la carte d'ADM-02 le montrera.
///
/// Properties:
/// * [ageS] - Âge de la dernière publication (secondes) — l'exploitation doit savoir si elle regarde une position fraîche ou un point figé.
/// * [capacites] - Capacités déclarées (slugs).
/// * [courseActive] - Course en cours, s'il y en a une.
/// * [coursierId] - Compte du coursier.
/// * [devise] - Devise ISO 4217.
/// * [lat] - Dernière latitude publiée.
/// * [lon] - Dernière longitude publiée.
/// * [plafondUnites] - Plafond d'avance RETENU du jour — `min(palier de la grille, déclaré)`.
@BuiltValue()
abstract class CoursierDuPool implements Built<CoursierDuPool, CoursierDuPoolBuilder> {
  /// Âge de la dernière publication (secondes) — l'exploitation doit savoir si elle regarde une position fraîche ou un point figé.
  @BuiltValueField(wireName: r'age_s')
  int get ageS;

  /// Capacités déclarées (slugs).
  @BuiltValueField(wireName: r'capacites')
  BuiltList<String> get capacites;

  /// Course en cours, s'il y en a une.
  @BuiltValueField(wireName: r'course_active')
  String? get courseActive;

  /// Compte du coursier.
  @BuiltValueField(wireName: r'coursier_id')
  String get coursierId;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Dernière latitude publiée.
  @BuiltValueField(wireName: r'lat')
  double get lat;

  /// Dernière longitude publiée.
  @BuiltValueField(wireName: r'lon')
  double get lon;

  /// Plafond d'avance RETENU du jour — `min(palier de la grille, déclaré)`.
  @BuiltValueField(wireName: r'plafond_unites')
  int get plafondUnites;

  CoursierDuPool._();

  factory CoursierDuPool([void updates(CoursierDuPoolBuilder b)]) = _$CoursierDuPool;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CoursierDuPoolBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CoursierDuPool> get serializer => _$CoursierDuPoolSerializer();
}

class _$CoursierDuPoolSerializer implements PrimitiveSerializer<CoursierDuPool> {
  @override
  final Iterable<Type> types = const [CoursierDuPool, _$CoursierDuPool];

  @override
  final String wireName = r'CoursierDuPool';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CoursierDuPool object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'age_s';
    yield serializers.serialize(
      object.ageS,
      specifiedType: const FullType(int),
    );
    yield r'capacites';
    yield serializers.serialize(
      object.capacites,
      specifiedType: const FullType(BuiltList, [FullType(String)]),
    );
    if (object.courseActive != null) {
      yield r'course_active';
      yield serializers.serialize(
        object.courseActive,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'coursier_id';
    yield serializers.serialize(
      object.coursierId,
      specifiedType: const FullType(String),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(double),
    );
    yield r'lon';
    yield serializers.serialize(
      object.lon,
      specifiedType: const FullType(double),
    );
    yield r'plafond_unites';
    yield serializers.serialize(
      object.plafondUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    CoursierDuPool object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CoursierDuPoolBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'age_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ageS = valueDes;
          break;
        case r'capacites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(String)]),
          ) as BuiltList<String>;
          result.capacites.replace(valueDes);
          break;
        case r'course_active':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.courseActive = valueDes;
          break;
        case r'coursier_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.coursierId = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lat = valueDes;
          break;
        case r'lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lon = valueDes;
          break;
        case r'plafond_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.plafondUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CoursierDuPool deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CoursierDuPoolBuilder();
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

