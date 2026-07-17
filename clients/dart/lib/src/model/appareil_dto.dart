//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/plateforme_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'appareil_dto.g.dart';

/// Appareil déclaré par l'app à l'ouverture de session.
///
/// Properties:
/// * [nom] - Nom lisible (« Pixel 7 de poche »), affiché tel quel dans la liste.
/// * [plateforme] - Plateforme.
@BuiltValue()
abstract class AppareilDto implements Built<AppareilDto, AppareilDtoBuilder> {
  /// Nom lisible (« Pixel 7 de poche »), affiché tel quel dans la liste.
  @BuiltValueField(wireName: r'nom')
  String get nom;

  /// Plateforme.
  @BuiltValueField(wireName: r'plateforme')
  PlateformeDto get plateforme;
  // enum plateformeEnum {  android,  ios,  };

  AppareilDto._();

  factory AppareilDto([void updates(AppareilDtoBuilder b)]) = _$AppareilDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(AppareilDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<AppareilDto> get serializer => _$AppareilDtoSerializer();
}

class _$AppareilDtoSerializer implements PrimitiveSerializer<AppareilDto> {
  @override
  final Iterable<Type> types = const [AppareilDto, _$AppareilDto];

  @override
  final String wireName = r'AppareilDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    AppareilDto object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'nom';
    yield serializers.serialize(
      object.nom,
      specifiedType: const FullType(String),
    );
    yield r'plateforme';
    yield serializers.serialize(
      object.plateforme,
      specifiedType: const FullType(PlateformeDto),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    AppareilDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required AppareilDtoBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'nom':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.nom = valueDes;
          break;
        case r'plateforme':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(PlateformeDto),
          ) as PlateformeDto;
          result.plateforme = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  AppareilDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = AppareilDtoBuilder();
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

