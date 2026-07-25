//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/devis.dart';
import 'package:mefali_api_client/src/model/drapeaux_zone.dart';
import 'package:mefali_api_client/src/model/itineraire_simule.dart';
import 'package:mefali_api_client/src/model/regle_retenue.dart';
import 'package:mefali_api_client/src/model/composantes.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resultat_simulation.g.dart';

/// Résultat COMPLET d'une simulation (FR-020).
///
/// Properties:
/// * [composantes] - Détail des composantes.
/// * [devis] - Devis final.
/// * [drapeaux] - Drapeaux appliqués.
/// * [effortNonFacture] - Vrai si l'effort a été calculé mais NON facturé (promo — FR-033).
/// * [itineraire] - Itinéraire utilisé.
/// * [regleRetenue] - Règle retenue.
@BuiltValue()
abstract class ResultatSimulation implements Built<ResultatSimulation, ResultatSimulationBuilder> {
  /// Détail des composantes.
  @BuiltValueField(wireName: r'composantes')
  Composantes get composantes;

  /// Devis final.
  @BuiltValueField(wireName: r'devis')
  Devis get devis;

  /// Drapeaux appliqués.
  @BuiltValueField(wireName: r'drapeaux')
  DrapeauxZone get drapeaux;

  /// Vrai si l'effort a été calculé mais NON facturé (promo — FR-033).
  @BuiltValueField(wireName: r'effort_non_facture')
  bool get effortNonFacture;

  /// Itinéraire utilisé.
  @BuiltValueField(wireName: r'itineraire')
  ItineraireSimule get itineraire;

  /// Règle retenue.
  @BuiltValueField(wireName: r'regle_retenue')
  RegleRetenue get regleRetenue;

  ResultatSimulation._();

  factory ResultatSimulation([void updates(ResultatSimulationBuilder b)]) = _$ResultatSimulation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatSimulationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatSimulation> get serializer => _$ResultatSimulationSerializer();
}

class _$ResultatSimulationSerializer implements PrimitiveSerializer<ResultatSimulation> {
  @override
  final Iterable<Type> types = const [ResultatSimulation, _$ResultatSimulation];

  @override
  final String wireName = r'ResultatSimulation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatSimulation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'composantes';
    yield serializers.serialize(
      object.composantes,
      specifiedType: const FullType(Composantes),
    );
    yield r'devis';
    yield serializers.serialize(
      object.devis,
      specifiedType: const FullType(Devis),
    );
    yield r'drapeaux';
    yield serializers.serialize(
      object.drapeaux,
      specifiedType: const FullType(DrapeauxZone),
    );
    yield r'effort_non_facture';
    yield serializers.serialize(
      object.effortNonFacture,
      specifiedType: const FullType(bool),
    );
    yield r'itineraire';
    yield serializers.serialize(
      object.itineraire,
      specifiedType: const FullType(ItineraireSimule),
    );
    yield r'regle_retenue';
    yield serializers.serialize(
      object.regleRetenue,
      specifiedType: const FullType(RegleRetenue),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatSimulation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResultatSimulationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'composantes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Composantes),
          ) as Composantes;
          result.composantes.replace(valueDes);
          break;
        case r'devis':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(Devis),
          ) as Devis;
          result.devis.replace(valueDes);
          break;
        case r'drapeaux':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DrapeauxZone),
          ) as DrapeauxZone;
          result.drapeaux.replace(valueDes);
          break;
        case r'effort_non_facture':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.effortNonFacture = valueDes;
          break;
        case r'itineraire':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(ItineraireSimule),
          ) as ItineraireSimule;
          result.itineraire.replace(valueDes);
          break;
        case r'regle_retenue':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(RegleRetenue),
          ) as RegleRetenue;
          result.regleRetenue.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResultatSimulation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatSimulationBuilder();
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

