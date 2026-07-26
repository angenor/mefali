//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_annulation.g.dart';

/// Demande d'annulation.
///
/// Properties:
/// * [motifCle] - Clé i18n du motif. **Obligatoire pour un admin** (FR-054), facultative pour le client — il n'a pas à se justifier.
@BuiltValue()
abstract class DemandeAnnulation implements Built<DemandeAnnulation, DemandeAnnulationBuilder> {
  /// Clé i18n du motif. **Obligatoire pour un admin** (FR-054), facultative pour le client — il n'a pas à se justifier.
  @BuiltValueField(wireName: r'motif_cle')
  String? get motifCle;

  DemandeAnnulation._();

  factory DemandeAnnulation([void updates(DemandeAnnulationBuilder b)]) = _$DemandeAnnulation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeAnnulationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeAnnulation> get serializer => _$DemandeAnnulationSerializer();
}

class _$DemandeAnnulationSerializer implements PrimitiveSerializer<DemandeAnnulation> {
  @override
  final Iterable<Type> types = const [DemandeAnnulation, _$DemandeAnnulation];

  @override
  final String wireName = r'DemandeAnnulation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeAnnulation object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.motifCle != null) {
      yield r'motif_cle';
      yield serializers.serialize(
        object.motifCle,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeAnnulation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeAnnulationBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.motifCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeAnnulation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeAnnulationBuilder();
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

