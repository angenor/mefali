//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/ligne_devis.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'groupe_vendeur.g.dart';

/// Les lignes d'un vendeur, regroupées (maquette C3-3a).
///
/// Properties:
/// * [lignes] - Lignes du vendeur.
/// * [nbArticles] - Nombre d'articles du groupe.
/// * [nom] - Nom affiché sur la carte vendeur.
/// * [prestataireId] - Vendeur.
/// * [sousTotalUnites] - Sous-total du vendeur (unités mineures).
@BuiltValue()
abstract class GroupeVendeur implements Built<GroupeVendeur, GroupeVendeurBuilder> {
  /// Lignes du vendeur.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LigneDevis> get lignes;

  /// Nombre d'articles du groupe.
  @BuiltValueField(wireName: r'nb_articles')
  int get nbArticles;

  /// Nom affiché sur la carte vendeur.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Vendeur.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Sous-total du vendeur (unités mineures).
  @BuiltValueField(wireName: r'sous_total_unites')
  int get sousTotalUnites;

  GroupeVendeur._();

  factory GroupeVendeur([void updates(GroupeVendeurBuilder b)]) = _$GroupeVendeur;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(GroupeVendeurBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<GroupeVendeur> get serializer => _$GroupeVendeurSerializer();
}

class _$GroupeVendeurSerializer implements PrimitiveSerializer<GroupeVendeur> {
  @override
  final Iterable<Type> types = const [GroupeVendeur, _$GroupeVendeur];

  @override
  final String wireName = r'GroupeVendeur';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    GroupeVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LigneDevis)]),
    );
    yield r'nb_articles';
    yield serializers.serialize(
      object.nbArticles,
      specifiedType: const FullType(int),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'sous_total_unites';
    yield serializers.serialize(
      object.sousTotalUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    GroupeVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required GroupeVendeurBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneDevis)]),
          ) as BuiltList<LigneDevis>;
          result.lignes.replace(valueDes);
          break;
        case r'nb_articles':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbArticles = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'sous_total_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.sousTotalUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  GroupeVendeur deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = GroupeVendeurBuilder();
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

