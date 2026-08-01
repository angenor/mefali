//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'decision_indemnisation.g.dart';

/// Corps d'une décision d'indemnisation.
///
/// Properties:
/// * [motifCle] - Clé i18n du motif — **obligatoire au refus** (FR-072). Un refus sans raison rend la promesse d'indemnisation invérifiable.
@BuiltValue()
abstract class DecisionIndemnisation implements Built<DecisionIndemnisation, DecisionIndemnisationBuilder> {
  /// Clé i18n du motif — **obligatoire au refus** (FR-072). Un refus sans raison rend la promesse d'indemnisation invérifiable.
  @BuiltValueField(wireName: r'motif_cle')
  String? get motifCle;

  DecisionIndemnisation._();

  factory DecisionIndemnisation([void updates(DecisionIndemnisationBuilder b)]) = _$DecisionIndemnisation;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DecisionIndemnisationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DecisionIndemnisation> get serializer => _$DecisionIndemnisationSerializer();
}

class _$DecisionIndemnisationSerializer implements PrimitiveSerializer<DecisionIndemnisation> {
  @override
  final Iterable<Type> types = const [DecisionIndemnisation, _$DecisionIndemnisation];

  @override
  final String wireName = r'DecisionIndemnisation';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DecisionIndemnisation object, {
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
    DecisionIndemnisation object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DecisionIndemnisationBuilder result,
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
  DecisionIndemnisation deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DecisionIndemnisationBuilder();
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

