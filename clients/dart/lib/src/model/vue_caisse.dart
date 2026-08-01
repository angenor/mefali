//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/indemnisation_vue.dart';
import 'package:mefali_api_client/src/model/ligne_historique_caisse.dart';
import 'package:mefali_api_client/src/model/litige_vu.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'vue_caisse.g.dart';

/// Tout l'écran caisse (K5-1a), en une lecture.
///
/// Properties:
/// * [avanceEnCoursUnites] - Argent avancé et non encore récupéré (FR-067) — toujours positif.
/// * [avancesEnAttenteReglementUnites] - Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117).
/// * [coursesConcernees] - Combien de courses portent cette avance.
/// * [devise] - Devise ISO 4217 de la zone.
/// * [ecartPlafond] - Les avances en cours dépassent le plafond déclaré du jour (FR-078).
/// * [historiqueDuJour] - Historique du jour civil **de la zone**.
/// * [indemnisations] - Indemnisations rattachées.
/// * [litigesEnCours] - Litiges en cours — vide tant qu'AVI-04 n'existe pas.
@BuiltValue()
abstract class VueCaisse implements Built<VueCaisse, VueCaisseBuilder> {
  /// Argent avancé et non encore récupéré (FR-067) — toujours positif.
  @BuiltValueField(wireName: r'avance_en_cours_unites')
  int get avanceEnCoursUnites;

  /// Part que le cash ne soldera jamais (commandes prépayées, R10, FR-117).
  @BuiltValueField(wireName: r'avances_en_attente_reglement_unites')
  int get avancesEnAttenteReglementUnites;

  /// Combien de courses portent cette avance.
  @BuiltValueField(wireName: r'courses_concernees')
  int get coursesConcernees;

  /// Devise ISO 4217 de la zone.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Les avances en cours dépassent le plafond déclaré du jour (FR-078).
  @BuiltValueField(wireName: r'ecart_plafond')
  bool get ecartPlafond;

  /// Historique du jour civil **de la zone**.
  @BuiltValueField(wireName: r'historique_du_jour')
  BuiltList<LigneHistoriqueCaisse> get historiqueDuJour;

  /// Indemnisations rattachées.
  @BuiltValueField(wireName: r'indemnisations')
  BuiltList<IndemnisationVue> get indemnisations;

  /// Litiges en cours — vide tant qu'AVI-04 n'existe pas.
  @BuiltValueField(wireName: r'litiges_en_cours')
  BuiltList<LitigeVu> get litigesEnCours;

  VueCaisse._();

  factory VueCaisse([void updates(VueCaisseBuilder b)]) = _$VueCaisse;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VueCaisseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VueCaisse> get serializer => _$VueCaisseSerializer();
}

class _$VueCaisseSerializer implements PrimitiveSerializer<VueCaisse> {
  @override
  final Iterable<Type> types = const [VueCaisse, _$VueCaisse];

  @override
  final String wireName = r'VueCaisse';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VueCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'avance_en_cours_unites';
    yield serializers.serialize(
      object.avanceEnCoursUnites,
      specifiedType: const FullType(int),
    );
    yield r'avances_en_attente_reglement_unites';
    yield serializers.serialize(
      object.avancesEnAttenteReglementUnites,
      specifiedType: const FullType(int),
    );
    yield r'courses_concernees';
    yield serializers.serialize(
      object.coursesConcernees,
      specifiedType: const FullType(int),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'ecart_plafond';
    yield serializers.serialize(
      object.ecartPlafond,
      specifiedType: const FullType(bool),
    );
    yield r'historique_du_jour';
    yield serializers.serialize(
      object.historiqueDuJour,
      specifiedType: const FullType(BuiltList, [FullType(LigneHistoriqueCaisse)]),
    );
    yield r'indemnisations';
    yield serializers.serialize(
      object.indemnisations,
      specifiedType: const FullType(BuiltList, [FullType(IndemnisationVue)]),
    );
    yield r'litiges_en_cours';
    yield serializers.serialize(
      object.litigesEnCours,
      specifiedType: const FullType(BuiltList, [FullType(LitigeVu)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    VueCaisse object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VueCaisseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'avance_en_cours_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.avanceEnCoursUnites = valueDes;
          break;
        case r'avances_en_attente_reglement_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.avancesEnAttenteReglementUnites = valueDes;
          break;
        case r'courses_concernees':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.coursesConcernees = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'ecart_plafond':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.ecartPlafond = valueDes;
          break;
        case r'historique_du_jour':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LigneHistoriqueCaisse)]),
          ) as BuiltList<LigneHistoriqueCaisse>;
          result.historiqueDuJour.replace(valueDes);
          break;
        case r'indemnisations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(IndemnisationVue)]),
          ) as BuiltList<IndemnisationVue>;
          result.indemnisations.replace(valueDes);
          break;
        case r'litiges_en_cours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(LitigeVu)]),
          ) as BuiltList<LitigeVu>;
          result.litigesEnCours.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  VueCaisse deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VueCaisseBuilder();
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

