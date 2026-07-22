//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/plage_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'horaires_semaine_dto.g.dart';

/// Horaires hebdomadaires : 7 tableaux de plages, index 0 = lundi ; un jour sans plage est un jour de fermeture.
///
/// Properties:
/// * [jours] - Plages par jour (lundi → dimanche).
@BuiltValue()
abstract class HorairesSemaineDto implements Built<HorairesSemaineDto, HorairesSemaineDtoBuilder> {
  /// Plages par jour (lundi → dimanche).
  @BuiltValueField(wireName: r'jours')
  BuiltList<BuiltList<PlageDto>> get jours;

  HorairesSemaineDto._();

  factory HorairesSemaineDto([void updates(HorairesSemaineDtoBuilder b)]) = _$HorairesSemaineDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(HorairesSemaineDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<HorairesSemaineDto> get serializer => _$HorairesSemaineDtoSerializer();
}

class _$HorairesSemaineDtoSerializer implements PrimitiveSerializer<HorairesSemaineDto> {
  @override
  final Iterable<Type> types = const [HorairesSemaineDto, _$HorairesSemaineDto];

  @override
  final String wireName = r'HorairesSemaineDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    HorairesSemaineDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'jours';
    yield serializers.serialize(
      object.jours,
      specifiedType: const FullType(BuiltList, [FullType(BuiltList, [FullType(PlageDto)])]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    HorairesSemaineDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required HorairesSemaineDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'jours':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(BuiltList, [FullType(PlageDto)])]),
          ) as BuiltList<BuiltList<PlageDto>>;
          result.jours.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  HorairesSemaineDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = HorairesSemaineDtoBuilder();
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

