//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_echec.g.dart';

/// Déclaration d'un échec (arbre §7.5).
///
/// Properties:
/// * [arretId] - Arrêt concerné — absent = à la remise.
/// * [motifCle] - Clé i18n du motif — jamais du texte libre.
/// * [typeIssue] - Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…).
/// * [uuidClient] - Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : un échec déclaré sans réseau se rejoue jusqu'à acquittement, et sans elle l'arbre §7.5 se déroulait deux fois — deux sanctions, deux indemnisations, deux litiges (R4).
@BuiltValue()
abstract class DemandeEchec implements Built<DemandeEchec, DemandeEchecBuilder> {
  /// Arrêt concerné — absent = à la remise.
  @BuiltValueField(wireName: r'arret_id')
  String? get arretId;

  /// Clé i18n du motif — jamais du texte libre.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  /// Ligne de l'arbre §7.5 (`refus_perissable`, `faux_billet`…).
  @BuiltValueField(wireName: r'type_issue')
  String get typeIssue;

  /// Clé d'idempotence (UUIDv7 produit par l'app, constitution V).  **Obligatoire** depuis CRS 010 : un échec déclaré sans réseau se rejoue jusqu'à acquittement, et sans elle l'arbre §7.5 se déroulait deux fois — deux sanctions, deux indemnisations, deux litiges (R4).
  @BuiltValueField(wireName: r'uuid_client')
  String get uuidClient;

  DemandeEchec._();

  factory DemandeEchec([void updates(DemandeEchecBuilder b)]) = _$DemandeEchec;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeEchecBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeEchec> get serializer => _$DemandeEchecSerializer();
}

class _$DemandeEchecSerializer implements PrimitiveSerializer<DemandeEchec> {
  @override
  final Iterable<Type> types = const [DemandeEchec, _$DemandeEchec];

  @override
  final String wireName = r'DemandeEchec';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeEchec object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.arretId != null) {
      yield r'arret_id';
      yield serializers.serialize(
        object.arretId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
    yield r'type_issue';
    yield serializers.serialize(
      object.typeIssue,
      specifiedType: const FullType(String),
    );
    yield r'uuid_client';
    yield serializers.serialize(
      object.uuidClient,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeEchec object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeEchecBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arret_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.arretId = valueDes;
          break;
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motifCle = valueDes;
          break;
        case r'type_issue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.typeIssue = valueDes;
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
  DemandeEchec deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeEchecBuilder();
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

