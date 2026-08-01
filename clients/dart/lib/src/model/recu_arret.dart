//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/ligne_recu.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'recu_arret.g.dart';

/// Reçu vendeur d'un arrêt collecté — **les mêmes trois chiffres** que le reçu client (FR-053, FR-071).
///
/// Properties:
/// * [arretId] - Arrêt collecté.
/// * [collecteLe] - Instant du scan (horloge SERVEUR).
/// * [devise] - Devise ISO 4217.
/// * [lignes] - Lignes de cet arrêt, retirées comprises.
/// * [montantArticlesUnites] - Articles bruts, AVANT retenue.
/// * [motifRetenueCle] - Clé i18n du motif de retenue, `null` s'il n'y en a pas.
/// * [netVerseUnites] - Ce que le coursier a effectivement versé — `articles − retenue`.
/// * [prestataireId] - Prestataire chez qui la collecte a eu lieu.
/// * [retenueLivraisonOfferteUnites] - Retenue au titre de la livraison offerte.
@BuiltValue()
abstract class RecuArret implements Built<RecuArret, RecuArretBuilder> {
  /// Arrêt collecté.
  @BuiltValueField(wireName: r'arret_id')
  String get arretId;

  /// Instant du scan (horloge SERVEUR).
  @BuiltValueField(wireName: r'collecte_le')
  DateTime? get collecteLe;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Lignes de cet arrêt, retirées comprises.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LigneRecu> get lignes;

  /// Articles bruts, AVANT retenue.
  @BuiltValueField(wireName: r'montant_articles_unites')
  int get montantArticlesUnites;

  /// Clé i18n du motif de retenue, `null` s'il n'y en a pas.
  @BuiltValueField(wireName: r'motif_retenue_cle')
  String? get motifRetenueCle;

  /// Ce que le coursier a effectivement versé — `articles − retenue`.
  @BuiltValueField(wireName: r'net_verse_unites')
  int get netVerseUnites;

  /// Prestataire chez qui la collecte a eu lieu.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Retenue au titre de la livraison offerte.
  @BuiltValueField(wireName: r'retenue_livraison_offerte_unites')
  int get retenueLivraisonOfferteUnites;

  RecuArret._();

  factory RecuArret([void updates(RecuArretBuilder b)]) = _$RecuArret;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RecuArretBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RecuArret> get serializer => _$RecuArretSerializer();
}

class _$RecuArretSerializer implements PrimitiveSerializer<RecuArret> {
  @override
  final Iterable<Type> types = const [RecuArret, _$RecuArret];

  @override
  final String wireName = r'RecuArret';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RecuArret object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_id';
    yield serializers.serialize(
      object.arretId,
      specifiedType: const FullType(String),
    );
    if (object.collecteLe != null) {
      yield r'collecte_le';
      yield serializers.serialize(
        object.collecteLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LigneRecu)]),
    );
    yield r'montant_articles_unites';
    yield serializers.serialize(
      object.montantArticlesUnites,
      specifiedType: const FullType(int),
    );
    if (object.motifRetenueCle != null) {
      yield r'motif_retenue_cle';
      yield serializers.serialize(
        object.motifRetenueCle,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'net_verse_unites';
    yield serializers.serialize(
      object.netVerseUnites,
      specifiedType: const FullType(int),
    );
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'retenue_livraison_offerte_unites';
    yield serializers.serialize(
      object.retenueLivraisonOfferteUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RecuArret object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RecuArretBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.arretId = valueDes;
          break;
        case r'collecte_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.collecteLe = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneRecu)]),
          ) as BuiltList<LigneRecu>;
          result.lignes.replace(valueDes);
          break;
        case r'montant_articles_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantArticlesUnites = valueDes;
          break;
        case r'motif_retenue_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motifRetenueCle = valueDes;
          break;
        case r'net_verse_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.netVerseUnites = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'retenue_livraison_offerte_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.retenueLivraisonOfferteUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RecuArret deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RecuArretBuilder();
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

