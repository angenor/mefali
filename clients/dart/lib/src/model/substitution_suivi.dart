//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'substitution_suivi.g.dart';

/// Proposition de remplacement en attente de décision (maquette C4-4c).
///
/// Properties:
/// * [ancienPrixUnites] - Prix de la ligne d'origine (unités mineures).
/// * [articleNom] - Nom de l'article proposé.
/// * [id] - Proposition.
/// * [ligneId] - Ligne concernée.
/// * [photoCle] - Clé de la photo déposée par le coursier.
/// * [prixUnites] - Prix proposé (unités mineures).
/// * [resteS] - Secondes restantes pour décider.
@BuiltValue()
abstract class SubstitutionSuivi implements Built<SubstitutionSuivi, SubstitutionSuiviBuilder> {
  /// Prix de la ligne d'origine (unités mineures).
  @BuiltValueField(wireName: r'ancien_prix_unites')
  int get ancienPrixUnites;

  /// Nom de l'article proposé.
  @BuiltValueField(wireName: r'article_nom')
  String get articleNom;

  /// Proposition.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Ligne concernée.
  @BuiltValueField(wireName: r'ligne_id')
  String get ligneId;

  /// Clé de la photo déposée par le coursier.
  @BuiltValueField(wireName: r'photo_cle')
  String get photoCle;

  /// Prix proposé (unités mineures).
  @BuiltValueField(wireName: r'prix_unites')
  int get prixUnites;

  /// Secondes restantes pour décider.
  @BuiltValueField(wireName: r'reste_s')
  int get resteS;

  SubstitutionSuivi._();

  factory SubstitutionSuivi([void updates(SubstitutionSuiviBuilder b)]) = _$SubstitutionSuivi;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SubstitutionSuiviBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SubstitutionSuivi> get serializer => _$SubstitutionSuiviSerializer();
}

class _$SubstitutionSuiviSerializer implements PrimitiveSerializer<SubstitutionSuivi> {
  @override
  final Iterable<Type> types = const [SubstitutionSuivi, _$SubstitutionSuivi];

  @override
  final String wireName = r'SubstitutionSuivi';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SubstitutionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'ancien_prix_unites';
    yield serializers.serialize(
      object.ancienPrixUnites,
      specifiedType: const FullType(int),
    );
    yield r'article_nom';
    yield serializers.serialize(
      object.articleNom,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'ligne_id';
    yield serializers.serialize(
      object.ligneId,
      specifiedType: const FullType(String),
    );
    yield r'photo_cle';
    yield serializers.serialize(
      object.photoCle,
      specifiedType: const FullType(String),
    );
    yield r'prix_unites';
    yield serializers.serialize(
      object.prixUnites,
      specifiedType: const FullType(int),
    );
    yield r'reste_s';
    yield serializers.serialize(
      object.resteS,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SubstitutionSuivi object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SubstitutionSuiviBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ancien_prix_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ancienPrixUnites = valueDes;
          break;
        case r'article_nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.articleNom = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'ligne_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.ligneId = valueDes;
          break;
        case r'photo_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.photoCle = valueDes;
          break;
        case r'prix_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixUnites = valueDes;
          break;
        case r'reste_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.resteS = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SubstitutionSuivi deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SubstitutionSuiviBuilder();
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

