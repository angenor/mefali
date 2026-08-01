//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/ligne_arret.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'arret_course.g.dart';

/// Un arrêt de collecte, complet.
///
/// Properties:
/// * [arretId] - Arrêt de la course.
/// * [arriveLe] - Arrivée sur l'arrêt.
/// * [collecteLe] - Collecte validée.
/// * [distanceMaxM] - Rayon max de scan (m).
/// * [distancePrecedentM] - Distance depuis l'arrêt précédent (m). **Absente** : le tronçon n'est pas figé au devis et ce cycle ne recalcule aucun itinéraire (FR-009).
/// * [empreinteCode] - base16(sha256(prestataire ‖ code)) — mode dégradé hors-ligne.
/// * [empreinteJeton] - base16(sha256(jeton)) — match hors-ligne du QR de plaque.
/// * [enRouteLe] - Départ déclaré vers l'arrêt.
/// * [lignes] - Articles à acheter chez ce vendeur.
/// * [montantAvance] - Montant à avancer à CE vendeur, lignes retirées exclues (FR-013).
/// * [nom] - Nom du vendeur.
/// * [ordre] - Rang dans l'ordre optimisé.
/// * [photoExigee] - Photo de récupération exigée (politique résolue).
/// * [prestataireId] - Prestataire visé.
/// * [siteLat] - Position attendue du site.
/// * [siteLon] - Position attendue du site.
/// * [statut] - `a_collecter` | `en_route` | `arrive` | `collecte` | `indisponible`.
/// * [telephoneVendeur] - Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé.
@BuiltValue()
abstract class ArretCourse implements Built<ArretCourse, ArretCourseBuilder> {
  /// Arrêt de la course.
  @BuiltValueField(wireName: r'arret_id')
  String get arretId;

  /// Arrivée sur l'arrêt.
  @BuiltValueField(wireName: r'arrive_le')
  DateTime? get arriveLe;

  /// Collecte validée.
  @BuiltValueField(wireName: r'collecte_le')
  DateTime? get collecteLe;

  /// Rayon max de scan (m).
  @BuiltValueField(wireName: r'distance_max_m')
  int get distanceMaxM;

  /// Distance depuis l'arrêt précédent (m). **Absente** : le tronçon n'est pas figé au devis et ce cycle ne recalcule aucun itinéraire (FR-009).
  @BuiltValueField(wireName: r'distance_precedent_m')
  int? get distancePrecedentM;

  /// base16(sha256(prestataire ‖ code)) — mode dégradé hors-ligne.
  @BuiltValueField(wireName: r'empreinte_code')
  String get empreinteCode;

  /// base16(sha256(jeton)) — match hors-ligne du QR de plaque.
  @BuiltValueField(wireName: r'empreinte_jeton')
  String get empreinteJeton;

  /// Départ déclaré vers l'arrêt.
  @BuiltValueField(wireName: r'en_route_le')
  DateTime? get enRouteLe;

  /// Articles à acheter chez ce vendeur.
  @BuiltValueField(wireName: r'lignes')
  BuiltList<LigneArret> get lignes;

  /// Montant à avancer à CE vendeur, lignes retirées exclues (FR-013).
  @BuiltValueField(wireName: r'montant_avance')
  int get montantAvance;

  /// Nom du vendeur.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Rang dans l'ordre optimisé.
  @BuiltValueField(wireName: r'ordre')
  int get ordre;

  /// Photo de récupération exigée (politique résolue).
  @BuiltValueField(wireName: r'photo_exigee')
  bool get photoExigee;

  /// Prestataire visé.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Position attendue du site.
  @BuiltValueField(wireName: r'site_lat')
  double get siteLat;

  /// Position attendue du site.
  @BuiltValueField(wireName: r'site_lon')
  double get siteLon;

  /// `a_collecter` | `en_route` | `arrive` | `collecte` | `indisponible`.
  @BuiltValueField(wireName: r'statut')
  String get statut;

  /// Contact du vendeur — appel HORS LIGNE (R6). Jamais journalisé.
  @BuiltValueField(wireName: r'telephone_vendeur')
  String? get telephoneVendeur;

  ArretCourse._();

  factory ArretCourse([void updates(ArretCourseBuilder b)]) = _$ArretCourse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ArretCourseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ArretCourse> get serializer => _$ArretCourseSerializer();
}

class _$ArretCourseSerializer implements PrimitiveSerializer<ArretCourse> {
  @override
  final Iterable<Type> types = const [ArretCourse, _$ArretCourse];

  @override
  final String wireName = r'ArretCourse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ArretCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arret_id';
    yield serializers.serialize(
      object.arretId,
      specifiedType: const FullType(String),
    );
    if (object.arriveLe != null) {
      yield r'arrive_le';
      yield serializers.serialize(
        object.arriveLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    if (object.collecteLe != null) {
      yield r'collecte_le';
      yield serializers.serialize(
        object.collecteLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'distance_max_m';
    yield serializers.serialize(
      object.distanceMaxM,
      specifiedType: const FullType(int),
    );
    if (object.distancePrecedentM != null) {
      yield r'distance_precedent_m';
      yield serializers.serialize(
        object.distancePrecedentM,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'empreinte_code';
    yield serializers.serialize(
      object.empreinteCode,
      specifiedType: const FullType(String),
    );
    yield r'empreinte_jeton';
    yield serializers.serialize(
      object.empreinteJeton,
      specifiedType: const FullType(String),
    );
    if (object.enRouteLe != null) {
      yield r'en_route_le';
      yield serializers.serialize(
        object.enRouteLe,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'lignes';
    yield serializers.serialize(
      object.lignes,
      specifiedType: const FullType(BuiltList, [FullType(LigneArret)]),
    );
    yield r'montant_avance';
    yield serializers.serialize(
      object.montantAvance,
      specifiedType: const FullType(int),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'ordre';
    yield serializers.serialize(
      object.ordre,
      specifiedType: const FullType(int),
    );
    yield r'photo_exigee';
    yield serializers.serialize(
      object.photoExigee,
      specifiedType: const FullType(bool),
    );
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'site_lat';
    yield serializers.serialize(
      object.siteLat,
      specifiedType: const FullType(double),
    );
    yield r'site_lon';
    yield serializers.serialize(
      object.siteLon,
      specifiedType: const FullType(double),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(String),
    );
    if (object.telephoneVendeur != null) {
      yield r'telephone_vendeur';
      yield serializers.serialize(
        object.telephoneVendeur,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    ArretCourse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ArretCourseBuilder result,
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
        case r'arrive_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.arriveLe = valueDes;
          break;
        case r'collecte_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.collecteLe = valueDes;
          break;
        case r'distance_max_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceMaxM = valueDes;
          break;
        case r'distance_precedent_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.distancePrecedentM = valueDes;
          break;
        case r'empreinte_code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteCode = valueDes;
          break;
        case r'empreinte_jeton':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.empreinteJeton = valueDes;
          break;
        case r'en_route_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.enRouteLe = valueDes;
          break;
        case r'lignes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneArret)]),
          ) as BuiltList<LigneArret>;
          result.lignes.replace(valueDes);
          break;
        case r'montant_avance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.montantAvance = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'ordre':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ordre = valueDes;
          break;
        case r'photo_exigee':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.photoExigee = valueDes;
          break;
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'site_lat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.siteLat = valueDes;
          break;
        case r'site_lon':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(double),
          ) as double;
          result.siteLon = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.statut = valueDes;
          break;
        case r'telephone_vendeur':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.telephoneVendeur = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ArretCourse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ArretCourseBuilder();
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

