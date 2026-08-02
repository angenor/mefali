//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'mouvement_caisse.g.dart';

/// Un **mouvement du livre de caisse** (cycle PAY 011, T050).  Additif : l'historique agrégé par course reste servi tel quel, et l'app livrée continue de fonctionner pendant la transition.
///
/// Properties:
/// * [commandeId] - Commande concernée — `null` pour un règlement ou un reversement, qui portent sur un solde et non sur une course.
/// * [entree] - Vrai si l'argent entre dans la poche du coursier.
/// * [heure] - Horodatage serveur de l'écriture.
/// * [id] - Écriture.
/// * [montantUnites] - Montant **signé** : négatif quand l'argent sort de la poche.  L'app dérive « entrée » ou « sortie » de ce SIGNE, jamais d'une table de types recopiée — une table qui divergerait le jour où une nature changerait de sens.
/// * [reference] - Référence lisible de la commande, quand il y en a une.
/// * [typeEcriture] - Nature : `avance` | `remboursement` | `indemnisation` | `correction` | `frais_encaisses` | `reglement` | `reversement`.
@BuiltValue()
abstract class MouvementCaisse implements Built<MouvementCaisse, MouvementCaisseBuilder> {
  /// Commande concernée — `null` pour un règlement ou un reversement, qui portent sur un solde et non sur une course.
  @BuiltValueField(wireName: r'commande_id')
  String? get commandeId;

  /// Vrai si l'argent entre dans la poche du coursier.
  @BuiltValueField(wireName: r'entree')
  bool get entree;

  /// Horodatage serveur de l'écriture.
  @BuiltValueField(wireName: r'heure')
  DateTime get heure;

  /// Écriture.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Montant **signé** : négatif quand l'argent sort de la poche.  L'app dérive « entrée » ou « sortie » de ce SIGNE, jamais d'une table de types recopiée — une table qui divergerait le jour où une nature changerait de sens.
  @BuiltValueField(wireName: r'montant_unites')
  int get montantUnites;

  /// Référence lisible de la commande, quand il y en a une.
  @BuiltValueField(wireName: r'reference')
  String? get reference;

  /// Nature : `avance` | `remboursement` | `indemnisation` | `correction` | `frais_encaisses` | `reglement` | `reversement`.
  @BuiltValueField(wireName: r'type_ecriture')
  String get typeEcriture;

  MouvementCaisse._();

  factory MouvementCaisse([void updates(MouvementCaisseBuilder b)]) = _$MouvementCaisse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(MouvementCaisseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<MouvementCaisse> get serializer => _$MouvementCaisseSerializer();
}

class _$MouvementCaisseSerializer implements PrimitiveSerializer<MouvementCaisse> {
  @override
  final Iterable<Type> types = const [MouvementCaisse, _$MouvementCaisse];

  @override
  final String wireName = r'MouvementCaisse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    MouvementCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.commandeId != null) {
      yield r'commande_id';
      yield serializers.serialize(
        object.commandeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'entree';
    yield serializers.serialize(
      object.entree,
      specifiedType: const FullType(bool),
    );
    yield r'heure';
    yield serializers.serialize(
      object.heure,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'montant_unites';
    yield serializers.serialize(
      object.montantUnites,
      specifiedType: const FullType(int),
    );
    if (object.reference != null) {
      yield r'reference';
      yield serializers.serialize(
        object.reference,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'type_ecriture';
    yield serializers.serialize(
      object.typeEcriture,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    MouvementCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required MouvementCaisseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.commandeId = valueDes;
          break;
        case r'entree':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.entree = valueDes;
          break;
        case r'heure':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.heure = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'montant_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantUnites = valueDes;
          break;
        case r'reference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.reference = valueDes;
          break;
        case r'type_ecriture':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.typeEcriture = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  MouvementCaisse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = MouvementCaisseBuilder();
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

