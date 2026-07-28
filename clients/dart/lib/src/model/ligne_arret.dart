//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_arret.g.dart';

/// Une ligne d'article à acheter chez un vendeur (K3).
///
/// Properties:
/// * [libelle] - Libellé de l'article.
/// * [ligneId] - Ligne de commande.
/// * [preferenceSubstitution] - `remplacer` | `appeler` | `retirer`.
/// * [prixUnitaireUnites] - Prix unitaire VERROUILLÉ à la création (unités mineures).
/// * [quantite] - Quantité commandée.
/// * [statut] - `presente` | `remplacee` | `retiree`.
@BuiltValue()
abstract class LigneArret implements Built<LigneArret, LigneArretBuilder> {
  /// Libellé de l'article.
  @BuiltValueField(wireName: r'libelle')
  String get libelle;

  /// Ligne de commande.
  @BuiltValueField(wireName: r'ligne_id')
  String get ligneId;

  /// `remplacer` | `appeler` | `retirer`.
  @BuiltValueField(wireName: r'preference_substitution')
  String get preferenceSubstitution;

  /// Prix unitaire VERROUILLÉ à la création (unités mineures).
  @BuiltValueField(wireName: r'prix_unitaire_unites')
  int get prixUnitaireUnites;

  /// Quantité commandée.
  @BuiltValueField(wireName: r'quantite')
  int get quantite;

  /// `presente` | `remplacee` | `retiree`.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  LigneArret._();

  factory LigneArret([void updates(LigneArretBuilder b)]) = _$LigneArret;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneArretBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneArret> get serializer => _$LigneArretSerializer();
}

class _$LigneArretSerializer implements PrimitiveSerializer<LigneArret> {
  @override
  final Iterable<Type> types = const [LigneArret, _$LigneArret];

  @override
  final String wireName = r'LigneArret';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneArret object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'libelle';
    yield serializers.serialize(
      object.libelle,
      specifiedType: const FullType(String),
    );
    yield r'ligne_id';
    yield serializers.serialize(
      object.ligneId,
      specifiedType: const FullType(String),
    );
    yield r'preference_substitution';
    yield serializers.serialize(
      object.preferenceSubstitution,
      specifiedType: const FullType(String),
    );
    yield r'prix_unitaire_unites';
    yield serializers.serialize(
      object.prixUnitaireUnites,
      specifiedType: const FullType(int),
    );
    yield r'quantite';
    yield serializers.serialize(
      object.quantite,
      specifiedType: const FullType(int),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneArret object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneArretBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'libelle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.libelle = valueDes;
          break;
        case r'ligne_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.ligneId = valueDes;
          break;
        case r'preference_substitution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.preferenceSubstitution = valueDes;
          break;
        case r'prix_unitaire_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixUnitaireUnites = valueDes;
          break;
        case r'quantite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.quantite = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneArret deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneArretBuilder();
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

