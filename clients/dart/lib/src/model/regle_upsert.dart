//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'regle_upsert.g.dart';

/// Écriture d'une règle de brouillon. Montants en **unités mineures**.
///
/// Properties:
/// * [actif] - Règle active à l'évaluation.
/// * [categorieSlug] - Slug de catégorie, `null` = toutes catégories.
/// * [devise] - Devise ISO 4217 — DOIT égaler celle de la zone (FR-023).
/// * [distanceMaxM] - Borne haute INCLUSE, `null` = +∞.
/// * [distanceMinM] - Borne basse de la tranche de distance routière (mètres).
/// * [joursMasque] - Masque de jours (bit 0 = lundi … bit 6 = dimanche), `null` = tous.
/// * [marge] - Marge Mefali — DOIT être dans les bornes de la zone (FR-009).
/// * [partCoursierBase] - Part coursier de base (unités mineures).
/// * [plageDebutMin] - Début de plage horaire (minutes depuis minuit, fuseau de la zone).
/// * [plageFinMin] - Fin de plage horaire (exclue).
/// * [priorite] - Priorité de départage.
/// * [prixParKm] - Prix par kilomètre au-delà du seuil (abonde client ET coursier).
/// * [prixPlafond] - Plafond du prix client, `null` = aucun.
/// * [seuilKmM] - Seuil (mètres) au-delà duquel le kilométrage est facturé.
/// * [transportSlug] - Slug du véhicule (référentiel `zones.type_transport`).
@BuiltValue()
abstract class RegleUpsert implements Built<RegleUpsert, RegleUpsertBuilder> {
  /// Règle active à l'évaluation.
  @BuiltValueField(wireName: r'actif')
  bool get actif;

  /// Slug de catégorie, `null` = toutes catégories.
  @BuiltValueField(wireName: r'categorie_slug')
  String? get categorieSlug;

  /// Devise ISO 4217 — DOIT égaler celle de la zone (FR-023).
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Borne haute INCLUSE, `null` = +∞.
  @BuiltValueField(wireName: r'distance_max_m')
  int? get distanceMaxM;

  /// Borne basse de la tranche de distance routière (mètres).
  @BuiltValueField(wireName: r'distance_min_m')
  int get distanceMinM;

  /// Masque de jours (bit 0 = lundi … bit 6 = dimanche), `null` = tous.
  @BuiltValueField(wireName: r'jours_masque')
  int? get joursMasque;

  /// Marge Mefali — DOIT être dans les bornes de la zone (FR-009).
  @BuiltValueField(wireName: r'marge')
  int get marge;

  /// Part coursier de base (unités mineures).
  @BuiltValueField(wireName: r'part_coursier_base')
  int get partCoursierBase;

  /// Début de plage horaire (minutes depuis minuit, fuseau de la zone).
  @BuiltValueField(wireName: r'plage_debut_min')
  int? get plageDebutMin;

  /// Fin de plage horaire (exclue).
  @BuiltValueField(wireName: r'plage_fin_min')
  int? get plageFinMin;

  /// Priorité de départage.
  @BuiltValueField(wireName: r'priorite')
  int get priorite;

  /// Prix par kilomètre au-delà du seuil (abonde client ET coursier).
  @BuiltValueField(wireName: r'prix_par_km')
  int get prixParKm;

  /// Plafond du prix client, `null` = aucun.
  @BuiltValueField(wireName: r'prix_plafond')
  int? get prixPlafond;

  /// Seuil (mètres) au-delà duquel le kilométrage est facturé.
  @BuiltValueField(wireName: r'seuil_km_m')
  int get seuilKmM;

  /// Slug du véhicule (référentiel `zones.type_transport`).
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  RegleUpsert._();

  factory RegleUpsert([void updates(RegleUpsertBuilder b)]) = _$RegleUpsert;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegleUpsertBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<RegleUpsert> get serializer => _$RegleUpsertSerializer();
}

class _$RegleUpsertSerializer implements PrimitiveSerializer<RegleUpsert> {
  @override
  final Iterable<Type> types = const [RegleUpsert, _$RegleUpsert];

  @override
  final String wireName = r'RegleUpsert';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    RegleUpsert object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'actif';
    yield serializers.serialize(
      object.actif,
      specifiedType: const FullType(bool),
    );
    if (object.categorieSlug != null) {
      yield r'categorie_slug';
      yield serializers.serialize(
        object.categorieSlug,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    if (object.distanceMaxM != null) {
      yield r'distance_max_m';
      yield serializers.serialize(
        object.distanceMaxM,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'distance_min_m';
    yield serializers.serialize(
      object.distanceMinM,
      specifiedType: const FullType(int),
    );
    if (object.joursMasque != null) {
      yield r'jours_masque';
      yield serializers.serialize(
        object.joursMasque,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'marge';
    yield serializers.serialize(
      object.marge,
      specifiedType: const FullType(int),
    );
    yield r'part_coursier_base';
    yield serializers.serialize(
      object.partCoursierBase,
      specifiedType: const FullType(int),
    );
    if (object.plageDebutMin != null) {
      yield r'plage_debut_min';
      yield serializers.serialize(
        object.plageDebutMin,
        specifiedType: const FullType.nullable(int),
      );
    }
    if (object.plageFinMin != null) {
      yield r'plage_fin_min';
      yield serializers.serialize(
        object.plageFinMin,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'priorite';
    yield serializers.serialize(
      object.priorite,
      specifiedType: const FullType(int),
    );
    yield r'prix_par_km';
    yield serializers.serialize(
      object.prixParKm,
      specifiedType: const FullType(int),
    );
    if (object.prixPlafond != null) {
      yield r'prix_plafond';
      yield serializers.serialize(
        object.prixPlafond,
        specifiedType: const FullType.nullable(int),
      );
    }
    yield r'seuil_km_m';
    yield serializers.serialize(
      object.seuilKmM,
      specifiedType: const FullType(int),
    );
    yield r'transport_slug';
    yield serializers.serialize(
      object.transportSlug,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    RegleUpsert object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegleUpsertBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'actif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.actif = valueDes;
          break;
        case r'categorie_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.categorieSlug = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'distance_max_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.distanceMaxM = valueDes;
          break;
        case r'distance_min_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceMinM = valueDes;
          break;
        case r'jours_masque':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.joursMasque = valueDes;
          break;
        case r'marge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.marge = valueDes;
          break;
        case r'part_coursier_base':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.partCoursierBase = valueDes;
          break;
        case r'plage_debut_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.plageDebutMin = valueDes;
          break;
        case r'plage_fin_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.plageFinMin = valueDes;
          break;
        case r'priorite':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.priorite = valueDes;
          break;
        case r'prix_par_km':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixParKm = valueDes;
          break;
        case r'prix_plafond':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(int),
          ) as int?;
          if (valueDes == null) continue;
          result.prixPlafond = valueDes;
          break;
        case r'seuil_km_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seuilKmM = valueDes;
          break;
        case r'transport_slug':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.transportSlug = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  RegleUpsert deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegleUpsertBuilder();
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

