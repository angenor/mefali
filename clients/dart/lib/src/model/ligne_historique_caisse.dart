//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'ligne_historique_caisse.g.dart';

/// Une course de l'historique du jour — **trois chiffres** (K5-1a).
///
/// Properties:
/// * [avanceUnites] - Ce que le coursier a avancé (positif).
/// * [commandeId] - Commande concernée.
/// * [enAttenteReglement] - Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
/// * [gainUnites] - Sa part sur cette course (devis figé du cycle 007).
/// * [heure] - Heure de la première écriture (horodatage serveur).
/// * [livraisonId] - Livraison concernée.
/// * [reference] - Référence lisible (`#418`) — de quoi se parler au téléphone.
/// * [rembourseUnites] - Ce qu'il a récupéré (positif).
/// * [terminee] - La course est-elle terminée ?
@BuiltValue()
abstract class LigneHistoriqueCaisse implements Built<LigneHistoriqueCaisse, LigneHistoriqueCaisseBuilder> {
  /// Ce que le coursier a avancé (positif).
  @BuiltValueField(wireName: r'avance_unites')
  int get avanceUnites;

  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Avance NON SOLDÉE parce que la commande était prépayée (R10, FR-117).
  @BuiltValueField(wireName: r'en_attente_reglement')
  bool get enAttenteReglement;

  /// Sa part sur cette course (devis figé du cycle 007).
  @BuiltValueField(wireName: r'gain_unites')
  int get gainUnites;

  /// Heure de la première écriture (horodatage serveur).
  @BuiltValueField(wireName: r'heure')
  DateTime get heure;

  /// Livraison concernée.
  @BuiltValueField(wireName: r'livraison_id')
  String? get livraisonId;

  /// Référence lisible (`#418`) — de quoi se parler au téléphone.
  @BuiltValueField(wireName: r'reference')
  String get reference;

  /// Ce qu'il a récupéré (positif).
  @BuiltValueField(wireName: r'rembourse_unites')
  int get rembourseUnites;

  /// La course est-elle terminée ?
  @BuiltValueField(wireName: r'terminee')
  bool get terminee;

  LigneHistoriqueCaisse._();

  factory LigneHistoriqueCaisse([void updates(LigneHistoriqueCaisseBuilder b)]) = _$LigneHistoriqueCaisse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(LigneHistoriqueCaisseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<LigneHistoriqueCaisse> get serializer => _$LigneHistoriqueCaisseSerializer();
}

class _$LigneHistoriqueCaisseSerializer implements PrimitiveSerializer<LigneHistoriqueCaisse> {
  @override
  final Iterable<Type> types = const [LigneHistoriqueCaisse, _$LigneHistoriqueCaisse];

  @override
  final String wireName = r'LigneHistoriqueCaisse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    LigneHistoriqueCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'avance_unites';
    yield serializers.serialize(
      object.avanceUnites,
      specifiedType: const FullType(int),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'en_attente_reglement';
    yield serializers.serialize(
      object.enAttenteReglement,
      specifiedType: const FullType(bool),
    );
    yield r'gain_unites';
    yield serializers.serialize(
      object.gainUnites,
      specifiedType: const FullType(int),
    );
    yield r'heure';
    yield serializers.serialize(
      object.heure,
      specifiedType: const FullType(DateTime),
    );
    if (object.livraisonId != null) {
      yield r'livraison_id';
      yield serializers.serialize(
        object.livraisonId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'reference';
    yield serializers.serialize(
      object.reference,
      specifiedType: const FullType(String),
    );
    yield r'rembourse_unites';
    yield serializers.serialize(
      object.rembourseUnites,
      specifiedType: const FullType(int),
    );
    yield r'terminee';
    yield serializers.serialize(
      object.terminee,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    LigneHistoriqueCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required LigneHistoriqueCaisseBuilder result,
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
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'en_attente_reglement':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.enAttenteReglement = valueDes;
          break;
        case r'gain_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.gainUnites = valueDes;
          break;
        case r'heure':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.heure = valueDes;
          break;
        case r'livraison_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.livraisonId = valueDes;
          break;
        case r'reference':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.reference = valueDes;
          break;
        case r'rembourse_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rembourseUnites = valueDes;
          break;
        case r'terminee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.terminee = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  LigneHistoriqueCaisse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = LigneHistoriqueCaisseBuilder();
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

