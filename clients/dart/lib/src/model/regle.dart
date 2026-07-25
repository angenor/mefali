//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'regle.g.dart';

/// Règle servie à l'admin.
///
/// Properties:
/// * [actif] - Active.
/// * [categorieSlug] - Catégorie, `null` = toutes.
/// * [devise] - Devise ISO 4217.
/// * [distanceMaxM] - Borne haute incluse.
/// * [distanceMinM] - Borne basse de tranche (mètres).
/// * [id] - Identifiant.
/// * [joursMasque] - Masque de jours.
/// * [marge] - Marge Mefali.
/// * [partCoursierBase] - Part coursier de base.
/// * [plageDebutMin] - Début de plage horaire.
/// * [plageFinMin] - Fin de plage horaire.
/// * [priorite] - Priorité.
/// * [prixClientBase] - Prix client de base DÉRIVÉ (`part_coursier_base + marge`) — jamais stocké, servi pour que l'admin lise le tarif sans le recalculer.
/// * [prixParKm] - Prix par km au-delà du seuil.
/// * [prixPlafond] - Plafond du prix client.
/// * [seuilKmM] - Seuil de kilométrage facturé (mètres).
/// * [transportSlug] - Véhicule.
@BuiltValue()
abstract class Regle implements Built<Regle, RegleBuilder> {
  /// Active.
  @BuiltValueField(wireName: r'actif')
  bool get actif;

  /// Catégorie, `null` = toutes.
  @BuiltValueField(wireName: r'categorie_slug')
  String? get categorieSlug;

  /// Devise ISO 4217.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Borne haute incluse.
  @BuiltValueField(wireName: r'distance_max_m')
  int? get distanceMaxM;

  /// Borne basse de tranche (mètres).
  @BuiltValueField(wireName: r'distance_min_m')
  int get distanceMinM;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Masque de jours.
  @BuiltValueField(wireName: r'jours_masque')
  int? get joursMasque;

  /// Marge Mefali.
  @BuiltValueField(wireName: r'marge')
  int get marge;

  /// Part coursier de base.
  @BuiltValueField(wireName: r'part_coursier_base')
  int get partCoursierBase;

  /// Début de plage horaire.
  @BuiltValueField(wireName: r'plage_debut_min')
  int? get plageDebutMin;

  /// Fin de plage horaire.
  @BuiltValueField(wireName: r'plage_fin_min')
  int? get plageFinMin;

  /// Priorité.
  @BuiltValueField(wireName: r'priorite')
  int get priorite;

  /// Prix client de base DÉRIVÉ (`part_coursier_base + marge`) — jamais stocké, servi pour que l'admin lise le tarif sans le recalculer.
  @BuiltValueField(wireName: r'prix_client_base')
  int get prixClientBase;

  /// Prix par km au-delà du seuil.
  @BuiltValueField(wireName: r'prix_par_km')
  int get prixParKm;

  /// Plafond du prix client.
  @BuiltValueField(wireName: r'prix_plafond')
  int? get prixPlafond;

  /// Seuil de kilométrage facturé (mètres).
  @BuiltValueField(wireName: r'seuil_km_m')
  int get seuilKmM;

  /// Véhicule.
  @BuiltValueField(wireName: r'transport_slug')
  String get transportSlug;

  Regle._();

  factory Regle([void updates(RegleBuilder b)]) = _$Regle;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(RegleBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Regle> get serializer => _$RegleSerializer();
}

class _$RegleSerializer implements PrimitiveSerializer<Regle> {
  @override
  final Iterable<Type> types = const [Regle, _$Regle];

  @override
  final String wireName = r'Regle';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Regle object, {
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
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
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
    yield r'prix_client_base';
    yield serializers.serialize(
      object.prixClientBase,
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
    Regle object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required RegleBuilder result,
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
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
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
        case r'prix_client_base':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixClientBase = valueDes;
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
  Regle deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = RegleBuilder();
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

