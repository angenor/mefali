//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'escalade_dispatch.g.dart';

/// Une commande escaladée : personne ne l'a prise au seuil de zone (FR-064).
///
/// Properties:
/// * [ageS] - Ancienneté au moment de l'escalade (secondes).
/// * [chemin] - Par quel chemin elle est arrivée là : `file` | `pipeline`.
/// * [commandeId] - Commande concernée.
/// * [etat] - État courant du tronc.
/// * [nbOffresEmises] - Nombre d'offres déjà émises pour elle.
/// * [seuilS] - Seuil de zone franchi (secondes).
/// * [zoneId] - Zone de la commande.
@BuiltValue()
abstract class EscaladeDispatch implements Built<EscaladeDispatch, EscaladeDispatchBuilder> {
  /// Ancienneté au moment de l'escalade (secondes).
  @BuiltValueField(wireName: r'age_s')
  int get ageS;

  /// Par quel chemin elle est arrivée là : `file` | `pipeline`.
  @BuiltValueField(wireName: r'chemin')
  String get chemin;

  /// Commande concernée.
  @BuiltValueField(wireName: r'commande_id')
  String get commandeId;

  /// État courant du tronc.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Nombre d'offres déjà émises pour elle.
  @BuiltValueField(wireName: r'nb_offres_emises')
  int get nbOffresEmises;

  /// Seuil de zone franchi (secondes).
  @BuiltValueField(wireName: r'seuil_s')
  int get seuilS;

  /// Zone de la commande.
  @BuiltValueField(wireName: r'zone_id')
  String get zoneId;

  EscaladeDispatch._();

  factory EscaladeDispatch([void updates(EscaladeDispatchBuilder b)]) = _$EscaladeDispatch;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(EscaladeDispatchBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<EscaladeDispatch> get serializer => _$EscaladeDispatchSerializer();
}

class _$EscaladeDispatchSerializer implements PrimitiveSerializer<EscaladeDispatch> {
  @override
  final Iterable<Type> types = const [EscaladeDispatch, _$EscaladeDispatch];

  @override
  final String wireName = r'EscaladeDispatch';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    EscaladeDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'age_s';
    yield serializers.serialize(
      object.ageS,
      specifiedType: const FullType(int),
    );
    yield r'chemin';
    yield serializers.serialize(
      object.chemin,
      specifiedType: const FullType(String),
    );
    yield r'commande_id';
    yield serializers.serialize(
      object.commandeId,
      specifiedType: const FullType(String),
    );
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'nb_offres_emises';
    yield serializers.serialize(
      object.nbOffresEmises,
      specifiedType: const FullType(int),
    );
    yield r'seuil_s';
    yield serializers.serialize(
      object.seuilS,
      specifiedType: const FullType(int),
    );
    yield r'zone_id';
    yield serializers.serialize(
      object.zoneId,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    EscaladeDispatch object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required EscaladeDispatchBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'age_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.ageS = valueDes;
          break;
        case r'chemin':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.chemin = valueDes;
          break;
        case r'commande_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.commandeId = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'nb_offres_emises':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.nbOffresEmises = valueDes;
          break;
        case r'seuil_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.seuilS = valueDes;
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
  EscaladeDispatch deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = EscaladeDispatchBuilder();
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

