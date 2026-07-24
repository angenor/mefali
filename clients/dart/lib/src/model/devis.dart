//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'devis.g.dart';

/// Devis figé.
///
/// Properties:
/// * [degraded] - Distance issue du mode dégradé.
/// * [devise] - Devise ISO 4217 de la zone.
/// * [distanceM] - Distance routière totale (mètres).
/// * [etaS] - Durée estimée (secondes).
/// * [marge] - Marge Mefali.
/// * [partCoursier] - Part reversée au coursier.
/// * [prixClient] - Prix payé par le client (unités mineures).
/// * [proposerScission] - Le détour dépasse le plafond de zone : CMD proposera de scinder.
@BuiltValue()
abstract class Devis implements Built<Devis, DevisBuilder> {
  /// Distance issue du mode dégradé.
  @BuiltValueField(wireName: r'degraded')
  bool get degraded;

  /// Devise ISO 4217 de la zone.
  @BuiltValueField(wireName: r'devise')
  String get devise;

  /// Distance routière totale (mètres).
  @BuiltValueField(wireName: r'distance_m')
  int get distanceM;

  /// Durée estimée (secondes).
  @BuiltValueField(wireName: r'eta_s')
  int get etaS;

  /// Marge Mefali.
  @BuiltValueField(wireName: r'marge')
  int get marge;

  /// Part reversée au coursier.
  @BuiltValueField(wireName: r'part_coursier')
  int get partCoursier;

  /// Prix payé par le client (unités mineures).
  @BuiltValueField(wireName: r'prix_client')
  int get prixClient;

  /// Le détour dépasse le plafond de zone : CMD proposera de scinder.
  @BuiltValueField(wireName: r'proposer_scission')
  bool get proposerScission;

  Devis._();

  factory Devis([void updates(DevisBuilder b)]) = _$Devis;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DevisBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<Devis> get serializer => _$DevisSerializer();
}

class _$DevisSerializer implements PrimitiveSerializer<Devis> {
  @override
  final Iterable<Type> types = const [Devis, _$Devis];

  @override
  final String wireName = r'Devis';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    Devis object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'degraded';
    yield serializers.serialize(
      object.degraded,
      specifiedType: const FullType(bool),
    );
    yield r'devise';
    yield serializers.serialize(
      object.devise,
      specifiedType: const FullType(String),
    );
    yield r'distance_m';
    yield serializers.serialize(
      object.distanceM,
      specifiedType: const FullType(int),
    );
    yield r'eta_s';
    yield serializers.serialize(
      object.etaS,
      specifiedType: const FullType(int),
    );
    yield r'marge';
    yield serializers.serialize(
      object.marge,
      specifiedType: const FullType(int),
    );
    yield r'part_coursier';
    yield serializers.serialize(
      object.partCoursier,
      specifiedType: const FullType(int),
    );
    yield r'prix_client';
    yield serializers.serialize(
      object.prixClient,
      specifiedType: const FullType(int),
    );
    yield r'proposer_scission';
    yield serializers.serialize(
      object.proposerScission,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    Devis object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DevisBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'degraded':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.degraded = valueDes;
          break;
        case r'devise':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.devise = valueDes;
          break;
        case r'distance_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.distanceM = valueDes;
          break;
        case r'eta_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.etaS = valueDes;
          break;
        case r'marge':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.marge = valueDes;
          break;
        case r'part_coursier':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.partCoursier = valueDes;
          break;
        case r'prix_client':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.prixClient = valueDes;
          break;
        case r'proposer_scission':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.proposerScission = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  Devis deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DevisBuilder();
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

