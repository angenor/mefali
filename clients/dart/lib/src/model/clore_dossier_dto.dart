//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'clore_dossier_dto.g.dart';

/// Corps de clôture — le motif est **obligatoire**.
///
/// Properties:
/// * [motifCle] - Clé i18n du motif de clôture. Un dossier clos sans motif ne dit pas ce qui a été fait de l'argent — c'est-à-dire rien.
@BuiltValue()
abstract class CloreDossierDto implements Built<CloreDossierDto, CloreDossierDtoBuilder> {
  /// Clé i18n du motif de clôture. Un dossier clos sans motif ne dit pas ce qui a été fait de l'argent — c'est-à-dire rien.
  @BuiltValueField(wireName: r'motif_cle')
  String get motifCle;

  CloreDossierDto._();

  factory CloreDossierDto([void updates(CloreDossierDtoBuilder b)]) = _$CloreDossierDto;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(CloreDossierDtoBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<CloreDossierDto> get serializer => _$CloreDossierDtoSerializer();
}

class _$CloreDossierDtoSerializer implements PrimitiveSerializer<CloreDossierDto> {
  @override
  final Iterable<Type> types = const [CloreDossierDto, _$CloreDossierDto];

  @override
  final String wireName = r'CloreDossierDto';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    CloreDossierDto object, {
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
    CloreDossierDto object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required CloreDossierDtoBuilder result,
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
  CloreDossierDto deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = CloreDossierDtoBuilder();
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

