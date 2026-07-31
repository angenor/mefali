//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_deblocage.g.dart';

/// Motif d'une décision d'exploitation — **jamais du texte libre**.
///
/// Properties:
/// * [motifCle] - Clé i18n du motif (obligatoire).
@BuiltValue()
abstract class DemandeDeblocage implements Built<DemandeDeblocage, DemandeDeblocageBuilder> {
  /// Clé i18n du motif (obligatoire).
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  DemandeDeblocage._();

  factory DemandeDeblocage([void updates(DemandeDeblocageBuilder b)]) = _$DemandeDeblocage;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeDeblocageBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeDeblocage> get serializer => _$DemandeDeblocageSerializer();
}

class _$DemandeDeblocageSerializer implements PrimitiveSerializer<DemandeDeblocage> {
  @override
  final Iterable<Type> types = const [DemandeDeblocage, _$DemandeDeblocage];

  @override
  final String wireName = r'DemandeDeblocage';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeDeblocage object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'motif_cle';
    yield serializers.serialize(
      object.motifCle,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeDeblocage object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeDeblocageBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
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
  DemandeDeblocage deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeDeblocageBuilder();
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

