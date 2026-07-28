//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'client_course.g.dart';

/// Le client et son repère (K3-1c, K4).
///
/// Properties:
/// * [depotAutorise] - La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ?
/// * [lieuLat] - Point de livraison.
/// * [lieuLon] - Point de livraison.
/// * [nomUsage] - Nom d'usage. **Absent** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — l'app affiche le repère.
/// * [repereTexte] - Repère écrit.
/// * [repereVocalDureeS] - Durée de la note vocale (s).
/// * [repereVocalUrl] - URL **présignée** de la note vocale — à télécharger tout de suite pour la jouer hors ligne (FR-024).
/// * [telephone] - Contact du client. Jamais journalisé, effacé du cache à la clôture (R6).
@BuiltValue()
abstract class ClientCourse implements Built<ClientCourse, ClientCourseBuilder> {
  /// La voie « dépôt » est-elle ouverte sur cette commande (FR-039) ?
  @BuiltValueField(wireName: r'depot_autorise')
  bool get depotAutorise;

  /// Point de livraison.
  @BuiltValueField(wireName: r'lieu_lat')
  double? get lieuLat;

  /// Point de livraison.
  @BuiltValueField(wireName: r'lieu_lon')
  double? get lieuLon;

  /// Nom d'usage. **Absent** tant que le produit n'en porte aucun (cycle CPT 003 : « un numéro vérifié, rien d'autre ») — l'app affiche le repère.
  @BuiltValueField(wireName: r'nom_usage')
  String? get nomUsage;

  /// Repère écrit.
  @BuiltValueField(wireName: r'repere_texte')
  String? get repereTexte;

  /// Durée de la note vocale (s).
  @BuiltValueField(wireName: r'repere_vocal_duree_s')
  int? get repereVocalDureeS;

  /// URL **présignée** de la note vocale — à télécharger tout de suite pour la jouer hors ligne (FR-024).
  @BuiltValueField(wireName: r'repere_vocal_url')
  String? get repereVocalUrl;

  /// Contact du client. Jamais journalisé, effacé du cache à la clôture (R6).
  @BuiltValueField(wireName: r'telephone')
  String? get telephone;

  ClientCourse._();

  factory ClientCourse([void updates(ClientCourseBuilder b)]) = _$ClientCourse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ClientCourseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ClientCourse> get serializer => _$ClientCourseSerializer();
}

class _$ClientCourseSerializer implements PrimitiveSerializer<ClientCourse> {
  @override
  final Iterable<Type> types = const [ClientCourse, _$ClientCourse];

  @override
  final String wireName = r'ClientCourse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ClientCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'depot_autorise';
    yield serializers.serialize(
      object.depotAutorise,
      specifiedType: const FullType(bool),
    );
    if (object.lieuLat != null) {
      yield r'lieu_lat';
      yield serializers.serialize(
        object.lieuLat,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.lieuLon != null) {
      yield r'lieu_lon';
      yield serializers.serialize(
        object.lieuLon,
        specifiedType: const FullType.nullable(double),
      );
    }
    if (object.nomUsage != null) {
      yield r'nom_usage';
      yield serializers.serialize(
        object.nomUsage,
        specifiedType: const FullType.nullable(String),
      );
    }
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
    if (object.repereVocalUrl != null) {
      yield r'repere_vocal_url';
      yield serializers.serialize(
        object.repereVocalUrl,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.telephone != null) {
      yield r'telephone';
      yield serializers.serialize(
        object.telephone,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ClientCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ClientCourseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'depot_autorise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.depotAutorise = valueDes;
          break;
        case r'lieu_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.lieuLat = valueDes;
          break;
        case r'lieu_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(double),
          ) as double?;
          if (valueDes == null) continue;
          result.lieuLon = valueDes;
          break;
        case r'nom_usage':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.nomUsage = valueDes;
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
        case r'repere_vocal_url':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.repereVocalUrl = valueDes;
          break;
        case r'telephone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.telephone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ClientCourse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ClientCourseBuilder();
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

