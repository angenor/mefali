//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'coursier_suivi.g.dart';

/// Le coursier affecté, tel que l'écran de suivi le montre.
///
/// Properties:
/// * [appelPossible] - Vrai si l'app peut proposer d'appeler.
/// * [id] - Identifiant du coursier.
/// * [note] - Note moyenne — **toujours `null` ce cycle** : les avis appartiennent au cycle AVI, qui n'existe pas encore.
/// * [prenom] - Prénom — **toujours `null` ce cycle** : `comptes.compte` ne porte aucun nom (cycle CPT), et rien ne sera inventé pour remplir un champ.
@BuiltValue()
abstract class CoursierSuivi implements Built<CoursierSuivi, CoursierSuiviBuilder> {
  /// Vrai si l'app peut proposer d'appeler.
  @BuiltValueField(wireName: r'appel_possible')
  bool get appelPossible;

  /// Identifiant du coursier.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Note moyenne — **toujours `null` ce cycle** : les avis appartiennent au cycle AVI, qui n'existe pas encore.
  @BuiltValueField(wireName: r'note')
  double? get note;

  /// Prénom — **toujours `null` ce cycle** : `comptes.compte` ne porte aucun nom (cycle CPT), et rien ne sera inventé pour remplir un champ.
  @BuiltValueField(wireName: r'prenom')
  String? get prenom;

  CoursierSuivi._();

  factory CoursierSuivi([void updates(CoursierSuiviBuilder b)]) = _$CoursierSuivi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CoursierSuiviBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CoursierSuivi> get serializer => _$CoursierSuiviSerializer();
}

class _$CoursierSuiviSerializer implements PrimitiveSerializer<CoursierSuivi> {
  @override
  final Iterable<Type> types = const [CoursierSuivi, _$CoursierSuivi];

  @override
  final String wireName = r'CoursierSuivi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CoursierSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appel_possible';
    yield serializers.serialize(
      object.appelPossible,
      specifiedType: const FullType(bool),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    if (object.note != null) {
      yield r'note';
      yield serializers.serialize(
        object.note,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.prenom != null) {
      yield r'prenom';
      yield serializers.serialize(
        object.prenom,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    CoursierSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CoursierSuiviBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appel_possible':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.appelPossible = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'note':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.note = valueDes;
          break;
        case r'prenom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.prenom = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  CoursierSuivi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CoursierSuiviBuilder();
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

