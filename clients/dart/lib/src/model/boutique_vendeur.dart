//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/horaires_semaine_dto.dart';
import 'package:mefali_api_client/src/model/etat_effectif_boutique.dart';
import 'package:mefali_api_client/src/model/plage_dto.dart';
import 'package:mefali_api_client/src/model/statut_boutique.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'boutique_vendeur.g.dart';

/// Données de l'écran V1 (FR-044).
///
/// Properties:
/// * [etatEffectif] - État EFFECTIF dérivé.
/// * [horaires] - Horaires hebdomadaires.
/// * [horairesDuJour] - Plages du jour courant (fuseau de la zone).
/// * [pauseFin] - Échéance de la pause en cours.
/// * [rappelOuverture] - FR-035 — rappel non bloquant à afficher (fermé manuel dans les horaires) ; « rester fermé » = fermer pour la journée, qui l'éteint.
/// * [statut] - Statut DÉCLARÉ (l'effectif peut différer — FR-032).
@BuiltValue()
abstract class BoutiqueVendeur implements Built<BoutiqueVendeur, BoutiqueVendeurBuilder> {
  /// État EFFECTIF dérivé.
  @BuiltValueField(wireName: r'etat_effectif')
  EtatEffectifBoutique get etatEffectif;

  /// Horaires hebdomadaires.
  @BuiltValueField(wireName: r'horaires')
  HorairesSemaineDto get horaires;

  /// Plages du jour courant (fuseau de la zone).
  @BuiltValueField(wireName: r'horaires_du_jour')
  BuiltList<PlageDto> get horairesDuJour;

  /// Échéance de la pause en cours.
  @BuiltValueField(wireName: r'pause_fin')
  DateTime? get pauseFin;

  /// FR-035 — rappel non bloquant à afficher (fermé manuel dans les horaires) ; « rester fermé » = fermer pour la journée, qui l'éteint.
  @BuiltValueField(wireName: r'rappel_ouverture')
  bool get rappelOuverture;

  /// Statut DÉCLARÉ (l'effectif peut différer — FR-032).
  @BuiltValueField(wireName: r'statut')
  StatutBoutique get statut;
  // enum statutEnum {  ouvert,  ferme,  ferme_journee,  en_pause,  };

  BoutiqueVendeur._();

  factory BoutiqueVendeur([void updates(BoutiqueVendeurBuilder b)]) = _$BoutiqueVendeur;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(BoutiqueVendeurBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<BoutiqueVendeur> get serializer => _$BoutiqueVendeurSerializer();
}

class _$BoutiqueVendeurSerializer implements PrimitiveSerializer<BoutiqueVendeur> {
  @override
  final Iterable<Type> types = const [BoutiqueVendeur, _$BoutiqueVendeur];

  @override
  final String wireName = r'BoutiqueVendeur';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    BoutiqueVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'etat_effectif';
    yield serializers.serialize(
      object.etatEffectif,
      specifiedType: const FullType(EtatEffectifBoutique),
    );
    yield r'horaires';
    yield serializers.serialize(
      object.horaires,
      specifiedType: const FullType(HorairesSemaineDto),
    );
    yield r'horaires_du_jour';
    yield serializers.serialize(
      object.horairesDuJour,
      specifiedType: const FullType(BuiltList, [FullType(PlageDto)]),
    );
    if (object.pauseFin != null) {
      yield r'pause_fin';
      yield serializers.serialize(
        object.pauseFin,
        specifiedType: const FullType.nullable(DateTime),
      );
    }
    yield r'rappel_ouverture';
    yield serializers.serialize(
      object.rappelOuverture,
      specifiedType: const FullType(bool),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(StatutBoutique),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    BoutiqueVendeur object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required BoutiqueVendeurBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'etat_effectif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EtatEffectifBoutique),
          ) as EtatEffectifBoutique;
          result.etatEffectif.replace(valueDes);
          break;
        case r'horaires':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(HorairesSemaineDto),
          ) as HorairesSemaineDto;
          result.horaires.replace(valueDes);
          break;
        case r'horaires_du_jour':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(PlageDto)]),
          ) as BuiltList<PlageDto>;
          result.horairesDuJour.replace(valueDes);
          break;
        case r'pause_fin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(DateTime),
          ) as DateTime?;
          if (valueDes == null) continue;
          result.pauseFin = valueDes;
          break;
        case r'rappel_ouverture':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.rappelOuverture = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatutBoutique),
          ) as StatutBoutique;
          result.statut = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  BoutiqueVendeur deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = BoutiqueVendeurBuilder();
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

