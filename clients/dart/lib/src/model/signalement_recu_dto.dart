//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'signalement_recu_dto.g.dart';

/// Issue du signalement.
///
/// Properties:
/// * [masquageAutomatique] - CE signalement a déclenché le masquage automatique (FR-040).
/// * [recu] - Reçu (vrai aussi pour un rejeu — même réponse, rien recompté).
@BuiltValue()
abstract class SignalementRecuDto implements Built<SignalementRecuDto, SignalementRecuDtoBuilder> {
  /// CE signalement a déclenché le masquage automatique (FR-040).
  @BuiltValueField(wireName: r'masquage_automatique')
  bool get masquageAutomatique;

  /// Reçu (vrai aussi pour un rejeu — même réponse, rien recompté).
  @BuiltValueField(wireName: r'recu')
  bool get recu;

  SignalementRecuDto._();

  factory SignalementRecuDto([void updates(SignalementRecuDtoBuilder b)]) = _$SignalementRecuDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SignalementRecuDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SignalementRecuDto> get serializer => _$SignalementRecuDtoSerializer();
}

class _$SignalementRecuDtoSerializer implements PrimitiveSerializer<SignalementRecuDto> {
  @override
  final Iterable<Type> types = const [SignalementRecuDto, _$SignalementRecuDto];

  @override
  final String wireName = r'SignalementRecuDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SignalementRecuDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'masquage_automatique';
    yield serializers.serialize(
      object.masquageAutomatique,
      specifiedType: const FullType(bool),
    );
    yield r'recu';
    yield serializers.serialize(
      object.recu,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SignalementRecuDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SignalementRecuDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'masquage_automatique':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.masquageAutomatique = valueDes;
          break;
        case r'recu':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.recu = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SignalementRecuDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SignalementRecuDtoBuilder();
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

