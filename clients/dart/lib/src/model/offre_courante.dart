//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/avance_offre.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/arret_offre.dart';
import 'package:mefali_api_client/src/model/destination_offre.dart';
import 'package:mefali_api_client/src/model/gain_offre.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'offre_courante.g.dart';

/// L'offre en vol, telle que l'écran K2 la rend.
///
/// Properties:
/// * [arrets] - Arrêts dans l'ordre optimisé du devis FIGÉ.
/// * [avance] - Avance et plafond.
/// * [commandeId] - Commande offerte.
/// * [degraded] - Vrai si les distances viennent du repli vol d'oiseau (constitution IV).
/// * [destination] - Destination approximative.
/// * [echeanceLe] - **AUTORITÉ** du compte à rebours : le widget compte, le serveur tranche.
/// * [gain] - Gain détaillé.
/// * [mode] - `cascade` | `broadcast`.
/// * [offreId] - Offre concernée.
/// * [restantS] - Secondes restantes à l'instant de la lecture.
/// * [timerS] - Durée totale du compte à rebours (secondes).
@BuiltValue()
abstract class OffreCourante implements Built<OffreCourante, OffreCouranteBuilder> {
  /// Arrêts dans l'ordre optimisé du devis FIGÉ.
  @BuiltValueField(wireName: r'arrets')
  BuiltList<ArretOffre> get arrets;

  /// Avance et plafond.
  @BuiltValueField(wireName: r'avance')
  AvanceOffre get avance;

  /// Commande offerte.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// Vrai si les distances viennent du repli vol d'oiseau (constitution IV).
  @BuiltValueField(wireName: r'degraded')
  bool get degraded;

  /// Destination approximative.
  @BuiltValueField(wireName: r'destination')
  DestinationOffre get destination;

  /// **AUTORITÉ** du compte à rebours : le widget compte, le serveur tranche.
  @BuiltValueField(wireName: r'echeance_le')
  DateTime get echeanceLe;

  /// Gain détaillé.
  @BuiltValueField(wireName: r'gain')
  GainOffre get gain;

  /// `cascade` | `broadcast`.
  @BuiltValueField(wireName: r'mode')
  String get mode;

  /// Offre concernée.
  @BuiltValueField(wireName: r'offre_id')
  String get offreId;

  /// Secondes restantes à l'instant de la lecture.
  @BuiltValueField(wireName: r'restant_s')
  int get restantS;

  /// Durée totale du compte à rebours (secondes).
  @BuiltValueField(wireName: r'timer_s')
  int get timerS;

  OffreCourante._();

  factory OffreCourante([void updates(OffreCouranteBuilder b)]) = _$OffreCourante;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(OffreCouranteBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<OffreCourante> get serializer => _$OffreCouranteSerializer();
}

class _$OffreCouranteSerializer implements PrimitiveSerializer<OffreCourante> {
  @override
  final Iterable<Type> types = const [OffreCourante, _$OffreCourante];

  @override
  final String wireName = r'OffreCourante';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    OffreCourante object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'arrets';
    yield serializers.serialize(
      object.arrets,
      specifiedType: const FullType(BuiltList, [FullType(ArretOffre)]),
    );
    yield r'avance';
    yield serializers.serialize(
      object.avance,
      specifiedType: const FullType(AvanceOffre),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'degraded';
    yield serializers.serialize(
      object.degraded,
      specifiedType: const FullType(bool),
    );
    yield r'destination';
    yield serializers.serialize(
      object.destination,
      specifiedType: const FullType(DestinationOffre),
    );
    yield r'echeance_le';
    yield serializers.serialize(
      object.echeanceLe,
      specifiedType: const FullType(DateTime),
    );
    yield r'gain';
    yield serializers.serialize(
      object.gain,
      specifiedType: const FullType(GainOffre),
    );
    yield r'mode';
    yield serializers.serialize(
      object.mode,
      specifiedType: const FullType(String),
    );
    yield r'offre_id';
    yield serializers.serialize(
      object.offreId,
      specifiedType: const FullType(String),
    );
    yield r'restant_s';
    yield serializers.serialize(
      object.restantS,
      specifiedType: const FullType(int),
    );
    yield r'timer_s';
    yield serializers.serialize(
      object.timerS,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    OffreCourante object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required OffreCouranteBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'arrets':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(ArretOffre)]),
          ) as BuiltList<ArretOffre>;
          result.arrets.replace(valueDes);
          break;
        case r'avance':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AvanceOffre),
          ) as AvanceOffre;
          result.avance.replace(valueDes);
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        case r'destination':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DestinationOffre),
          ) as DestinationOffre;
          result.destination.replace(valueDes);
          break;
        case r'echeance_le':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(DateTime),
          ) as DateTime;
          result.echeanceLe = valueDes;
          break;
        case r'gain':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(GainOffre),
          ) as GainOffre;
          result.gain.replace(valueDes);
          break;
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mode = valueDes;
          break;
        case r'offre_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.offreId = valueDes;
          break;
        case r'restant_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.restantS = valueDes;
          break;
        case r'timer_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.timerS = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  OffreCourante deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = OffreCouranteBuilder();
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

