//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'indemnisation_decidee.g.dart';

/// Ce qu'une décision produit.
///
/// Properties:
/// * [ecritureId] - Écriture de caisse produite — **seulement** à la validation.
/// * [etat] - `validee` | `refusee`.
/// * [id] - Indemnisation décidée.
@BuiltValue()
abstract class IndemnisationDecidee implements Built<IndemnisationDecidee, IndemnisationDecideeBuilder> {
  /// Écriture de caisse produite — **seulement** à la validation.
  @BuiltValueField(wireName: r'ecriture_id')
  String? get ecritureId;

  /// `validee` | `refusee`.
  @BuiltValueField(wireName: r'etat')
  String get etat;

  /// Indemnisation décidée.
  @BuiltValueField(wireName: r'id')
  String get id;

  IndemnisationDecidee._();

  factory IndemnisationDecidee([void updates(IndemnisationDecideeBuilder b)]) = _$IndemnisationDecidee;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(IndemnisationDecideeBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<IndemnisationDecidee> get serializer => _$IndemnisationDecideeSerializer();
}

class _$IndemnisationDecideeSerializer implements PrimitiveSerializer<IndemnisationDecidee> {
  @override
  final Iterable<Type> types = const [IndemnisationDecidee, _$IndemnisationDecidee];

  @override
  final String wireName = r'IndemnisationDecidee';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    IndemnisationDecidee object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.ecritureId != null) {
      yield r'ecriture_id';
      yield serializers.serialize(
        object.ecritureId,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'etat';
    yield serializers.serialize(
      object.etat,
      specifiedType: const FullType(String),
    );
    yield r'id';
    yield serializers.serialize(
      object.id,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    IndemnisationDecidee object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required IndemnisationDecideeBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'ecriture_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.ecritureId = valueDes;
          break;
        case r'etat':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.etat = valueDes;
          break;
        case r'id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.id = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  IndemnisationDecidee deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = IndemnisationDecideeBuilder();
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

