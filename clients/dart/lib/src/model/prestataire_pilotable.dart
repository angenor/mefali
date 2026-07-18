//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/statut_prestataire.dart';
import 'package:mefali_api_client/src/model/etat_effectif_boutique.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'prestataire_pilotable.g.dart';

/// Prestataire pilotable par le compte (résumé — l'app prend le premier).
///
/// Properties:
/// * [boutique] - État effectif de la boutique.
/// * [id] - Identifiant.
/// * [nom] - Nom public.
/// * [statut] - Cycle de vie — `suspendu` : l'app affiche le refus, le rôle est intact.
@BuiltValue()
abstract class PrestatairePilotable implements Built<PrestatairePilotable, PrestatairePilotableBuilder> {
  /// État effectif de la boutique.
  @BuiltValueField(wireName: r'boutique')
  EtatEffectifBoutique get boutique;

  /// Identifiant.
  @BuiltValueField(wireName: r'id')
  String get id;

  /// Nom public.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Cycle de vie — `suspendu` : l'app affiche le refus, le rôle est intact.
  @BuiltValueField(wireName: r'statut')
  StatutPrestataire get statut;
  // enum statutEnum {  prospect,  agree,  suspendu,  };

  PrestatairePilotable._();

  factory PrestatairePilotable([void updates(PrestatairePilotableBuilder b)]) = _$PrestatairePilotable;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(PrestatairePilotableBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<PrestatairePilotable> get serializer => _$PrestatairePilotableSerializer();
}

class _$PrestatairePilotableSerializer implements PrimitiveSerializer<PrestatairePilotable> {
  @override
  final Iterable<Type> types = const [PrestatairePilotable, _$PrestatairePilotable];

  @override
  final String wireName = r'PrestatairePilotable';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    PrestatairePilotable object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'boutique';
    yield serializers.serialize(
      object.boutique,
      specifiedType: const FullType(EtatEffectifBoutique),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'statut';
    yield serializers.serialize(
      object.statut,
      specifiedType: const FullType(StatutPrestataire),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    PrestatairePilotable object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required PrestatairePilotableBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'boutique':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(EtatEffectifBoutique),
          ) as EtatEffectifBoutique;
          result.boutique.replace(valueDes);
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'statut':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(StatutPrestataire),
          ) as StatutPrestataire;
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
  PrestatairePilotable deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = PrestatairePilotableBuilder();
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

