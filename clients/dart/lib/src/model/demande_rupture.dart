//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_rupture.g.dart';

/// Partie JSON `demande` du multipart de rupture.
///
/// Properties:
/// * [articleProposeId] - Article proposé — obligatoire pour `remplacer`, **du même vendeur**.
/// * [ligneId] - Ligne de commande devenue indisponible.
/// * [prixProposeUnites] - Prix unitaire proposé (unités mineures) — obligatoire pour `remplacer`.
/// * [resolution] - `retirer` | `remplacer`. Absent = suivre la préférence du client, dont le défaut sûr est le retrait : on ne fait jamais payer par défaut.
/// * [uuidClient] - Clé d'idempotence (UUIDv7 client, constitution V).
@BuiltValue()
abstract class DemandeRupture implements Built<DemandeRupture, DemandeRuptureBuilder> {
  /// Article proposé — obligatoire pour `remplacer`, **du même vendeur**.
  @BuiltValueField(wireName: r'article_propose_id')
  String? get articleProposeId;

  /// Ligne de commande devenue indisponible.
  @BuiltValueField(wireName: r'ligne_id')
  String get ligneId;

  /// Prix unitaire proposé (unités mineures) — obligatoire pour `remplacer`.
  @BuiltValueField(wireName: r'prix_propose_unites')
  int? get prixProposeUnites;

  /// `retirer` | `remplacer`. Absent = suivre la préférence du client, dont le défaut sûr est le retrait : on ne fait jamais payer par défaut.
  @BuiltValueField(wireName: r'resolution')
  String? get resolution;

  /// Clé d'idempotence (UUIDv7 client, constitution V).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DemandeRupture._();

  factory DemandeRupture([void updates(DemandeRuptureBuilder b)]) = _$DemandeRupture;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeRuptureBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeRupture> get serializer => _$DemandeRuptureSerializer();
}

class _$DemandeRuptureSerializer implements PrimitiveSerializer<DemandeRupture> {
  @override
  final Iterable<Type> types = const [DemandeRupture, _$DemandeRupture];

  @override
  final String wireName = r'DemandeRupture';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeRupture object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.articleProposeId != null) {
      yield r'article_propose_id';
      yield serializers.serialize(
        object.articleProposeId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'ligne_id';
    yield serializers.serialize(
      object.ligneId,
      specifiedType: const FullType(String),
    );
    if (object.prixProposeUnites != null) {
      yield r'prix_propose_unites';
      yield serializers.serialize(
        object.prixProposeUnites,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.resolution != null) {
      yield r'resolution';
      yield serializers.serialize(
        object.resolution,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeRupture object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeRuptureBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'article_propose_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.articleProposeId = valueDes;
          break;
        case r'ligne_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.ligneId = valueDes;
          break;
        case r'prix_propose_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.prixProposeUnites = valueDes;
          break;
        case r'resolution':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.resolution = valueDes;
          break;
        case r'uuid_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.uuidClient = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeRupture deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeRuptureBuilder();
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

