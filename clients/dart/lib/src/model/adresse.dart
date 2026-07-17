//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'adresse.g.dart';

/// Adresse enregistrée (contrat).  ⚠ N'expose NI `compte_id` (implicite : c'est le vôtre), NI la clé S3 du repère, NI `supprimee_le`, NI `livraison_origine` (provision CPT-06).
///
/// Properties:
/// * [aRepereVocal] - `false` après purge (12 mois sans utilisation — FR-022).
/// * [creeLe] - Enregistrement.
/// * [derniereUtilisationLe] - Base de la purge.
/// * [id] - Identifiant = `Idempotency-Key` du POST créateur (R14).
/// * [lat] - Latitude du pin GPS.
/// * [libelle] - « Maison », « Bureau » ou libre.
/// * [lng] - Longitude du pin GPS.
/// * [repereTexte] - Repère écrit.
/// * [repereVocalDureeS] - Durée du repère vocal.
/// * [zoneId] - Zone de l'adresse.
@BuiltValue()
abstract class Adresse implements Built<Adresse, AdresseBuilder> {
  /// `false` après purge (12 mois sans utilisation — FR-022).
  @BuiltValueField(wireName: r'a_repere_vocal')
  bool get aRepereVocal;

  /// Enregistrement.
  @BuiltValueField(wireName: r'cree_le')
  DateTime get creeLe;

  /// Base de la purge.
  @BuiltValueField(wireName: r'derniere_utilisation_le')
  DateTime get derniereUtilisationLe;

  /// Identifiant = `Idempotency-Key` du POST créateur (R14).
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Latitude du pin GPS.
  @BuiltValueField(wireName: r'lat')
  double get lat;

  /// « Maison », « Bureau » ou libre.
  @BuiltValueField(wireName: r'libelle')
  String get libelle;

  /// Longitude du pin GPS.
  @BuiltValueField(wireName: r'lng')
  double get lng;

  /// Repère écrit.
  @BuiltValueField(wireName: r'repere_texte')
  String? get repereTexte;

  /// Durée du repère vocal.
  @BuiltValueField(wireName: r'repere_vocal_duree_s')
  int? get repereVocalDureeS;

  /// Zone de l'adresse.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  Adresse._();

  factory Adresse([void updates(AdresseBuilder b)]) = _$Adresse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AdresseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Adresse> get serializer => _$AdresseSerializer();
}

class _$AdresseSerializer implements PrimitiveSerializer<Adresse> {
  @override
  final Iterable<Type> types = const [Adresse, _$Adresse];

  @override
  final String wireName = r'Adresse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Adresse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'a_repere_vocal';
    yield serializers.serialize(
      object.aRepereVocal,
      specifiedType: const FullType(bool),
    );
    yield r'cree_le';
    yield serializers.serialize(
      object.creeLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'derniere_utilisation_le';
    yield serializers.serialize(
      object.derniereUtilisationLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'lat';
    yield serializers.serialize(
      object.lat,
      specifiedType: const FullType(double),
    );
    yield r'libelle';
    yield serializers.serialize(
      object.libelle,
      specifiedType: const FullType(String),
    );
    yield r'lng';
    yield serializers.serialize(
      object.lng,
      specifiedType: const FullType(double),
    );
    if (object.repereTexte != null) {
      yield r'repere_texte';
      yield serializers.serialize(
        object.repereTexte,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.repereVocalDureeS != null) {
      yield r'repere_vocal_duree_s';
      yield serializers.serialize(
        object.repereVocalDureeS,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Adresse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AdresseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'a_repere_vocal':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.aRepereVocal = valueDes;
          break;
        case r'cree_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.creeLe = valueDes;
          break;
        case r'derniere_utilisation_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.derniereUtilisationLe = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lat = valueDes;
          break;
        case r'libelle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.libelle = valueDes;
          break;
        case r'lng':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.lng = valueDes;
          break;
        case r'repere_texte':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repereTexte = valueDes;
          break;
        case r'repere_vocal_duree_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.repereVocalDureeS = valueDes;
          break;
        case r'zone_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zoneId = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Adresse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AdresseBuilder();
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

