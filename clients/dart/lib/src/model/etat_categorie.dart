//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/forcage_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'etat_categorie.g.dart';

/// État effectif d'une catégorie renvoyé après forçage (contrat).
///
/// Properties:
/// * [actif] - État EFFECTIF après application.
/// * [categorie] - Slug de la catégorie.
/// * [forcage] - Mode de forçage appliqué.
/// * [zone] - Ville concernée.
@BuiltValue()
abstract class EtatCategorie implements Built<EtatCategorie, EtatCategorieBuilder> {
  /// État EFFECTIF après application.
  @BuiltValueField(wireName: r'actif')
  bool get actif;

  /// Slug de la catégorie.
  @BuiltValueField(wireName: r'categorie')
  String get categorie;

  /// Mode de forçage appliqué.
  @BuiltValueField(wireName: r'forcage')
  ForcageDto get forcage;
  // enum forcageEnum {  automatique,  force_actif,  force_inactif,  };

  /// Ville concernée.
  @BuiltValueField(wireName: r'zone')
  String get zone;

  EtatCategorie._();

  factory EtatCategorie([void updates(EtatCategorieBuilder b)]) = _$EtatCategorie;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EtatCategorieBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EtatCategorie> get serializer => _$EtatCategorieSerializer();
}

class _$EtatCategorieSerializer implements PrimitiveSerializer<EtatCategorie> {
  @override
  final Iterable<Type> types = const [EtatCategorie, _$EtatCategorie];

  @override
  final String wireName = r'EtatCategorie';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EtatCategorie object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'actif';
    yield serializers.serialize(
      object.actif,
      specifiedType: const FullType(bool),
    );
    yield r'categorie';
    yield serializers.serialize(
      object.categorie,
      specifiedType: const FullType(String),
    );
    yield r'forcage';
    yield serializers.serialize(
      object.forcage,
      specifiedType: const FullType(ForcageDto),
    );
    yield r'zone';
    yield serializers.serialize(
      object.zone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EtatCategorie object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EtatCategorieBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'actif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.actif = valueDes;
          break;
        case r'categorie':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.categorie = valueDes;
          break;
        case r'forcage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ForcageDto),
          ) as ForcageDto;
          result.forcage = valueDes;
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  EtatCategorie deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EtatCategorieBuilder();
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

