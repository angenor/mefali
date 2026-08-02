//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offre_livraison_reglee.g.dart';

/// Offre en vigueur après le geste.  ⚠ Le nom de schéma est `OffreLivraisonReglee`, PAS `OffreLivraisonVendeur` : ce dernier est déjà pris par l'**entrée de calcul** de `tarification` (`admin_tarification_http`), dont la forme est tout autre (`toujours`, `au_dela`). Deux types qui revendiquent le même nom de schéma n'en laissent qu'un dans `openapi.json` — et le client généré désérialise alors la réponse de cette route avec le mauvais modèle. Trouvé sur appareil en T085 : le vendeur voyait « Impossible de charger la boutique » sur un réglage **pourtant enregistré**.
///
/// Properties:
/// * [messageCle] - Rappel en clair que les commandes en cours ne bougent pas (FR-048).
/// * [offre] - `jamais` | `toujours` | `au_dela`.
/// * [seuilUnites] - Seuil déclaré (`null` hors `au_dela`).
@BuiltValue()
abstract class OffreLivraisonReglee implements Built<OffreLivraisonReglee, OffreLivraisonRegleeBuilder> {
  /// Rappel en clair que les commandes en cours ne bougent pas (FR-048).
  @BuiltValueField(wireName: r'message_cle')
  String get messageCle;

  /// `jamais` | `toujours` | `au_dela`.
  @BuiltValueField(wireName: r'offre')
  String get offre;

  /// Seuil déclaré (`null` hors `au_dela`).
  @BuiltValueField(wireName: r'seuil_unites')
  int? get seuilUnites;

  OffreLivraisonReglee._();

  factory OffreLivraisonReglee([void updates(OffreLivraisonRegleeBuilder b)]) = _$OffreLivraisonReglee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OffreLivraisonRegleeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OffreLivraisonReglee> get serializer => _$OffreLivraisonRegleeSerializer();
}

class _$OffreLivraisonRegleeSerializer implements PrimitiveSerializer<OffreLivraisonReglee> {
  @override
  final Iterable<Type> types = const [OffreLivraisonReglee, _$OffreLivraisonReglee];

  @override
  final String wireName = r'OffreLivraisonReglee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OffreLivraisonReglee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'message_cle';
    yield serializers.serialize(
      object.messageCle,
      specifiedType: const FullType(String),
    );
    yield r'offre';
    yield serializers.serialize(
      object.offre,
      specifiedType: const FullType(String),
    );
    if (object.seuilUnites != null) {
      yield r'seuil_unites';
      yield serializers.serialize(
        object.seuilUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    OffreLivraisonReglee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OffreLivraisonRegleeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'message_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.messageCle = valueDes;
          break;
        case r'offre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offre = valueDes;
          break;
        case r'seuil_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.seuilUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OffreLivraisonReglee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OffreLivraisonRegleeBuilder();
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

