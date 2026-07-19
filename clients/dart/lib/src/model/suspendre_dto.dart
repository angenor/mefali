//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'suspendre_dto.g.dart';

/// Corps de la suspension (motif REQUIS — FR-010).
///
/// Properties:
/// * [motif] - Motif de la décision, journalisé.
@BuiltValue()
abstract class SuspendreDto implements Built<SuspendreDto, SuspendreDtoBuilder> {
  /// Motif de la décision, journalisé.
  @BuiltValueField(wireName: r'motif')
  String get motif;

  SuspendreDto._();

  factory SuspendreDto([void updates(SuspendreDtoBuilder b)]) = _$SuspendreDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SuspendreDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SuspendreDto> get serializer => _$SuspendreDtoSerializer();
}

class _$SuspendreDtoSerializer implements PrimitiveSerializer<SuspendreDto> {
  @override
  final Iterable<Type> types = const [SuspendreDto, _$SuspendreDto];

  @override
  final String wireName = r'SuspendreDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SuspendreDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'motif';
    yield serializers.serialize(
      object.motif,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SuspendreDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SuspendreDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'motif':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.motif = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SuspendreDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SuspendreDtoBuilder();
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

