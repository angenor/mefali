//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/indemnisation_vue.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'file_indemnisations.g.dart';

/// La file des indemnisations.
///
/// Properties:
/// * [indemnisations] - Indemnisations, la plus récente d'abord.
@BuiltValue()
abstract class FileIndemnisations implements Built<FileIndemnisations, FileIndemnisationsBuilder> {
  /// Indemnisations, la plus récente d'abord.
  @BuiltValueField(wireName: r'indemnisations')
  BuiltList<IndemnisationVue> get indemnisations;

  FileIndemnisations._();

  factory FileIndemnisations([void updates(FileIndemnisationsBuilder b)]) = _$FileIndemnisations;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FileIndemnisationsBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FileIndemnisations> get serializer => _$FileIndemnisationsSerializer();
}

class _$FileIndemnisationsSerializer implements PrimitiveSerializer<FileIndemnisations> {
  @override
  final Iterable<Type> types = const [FileIndemnisations, _$FileIndemnisations];

  @override
  final String wireName = r'FileIndemnisations';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FileIndemnisations object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'indemnisations';
    yield serializers.serialize(
      object.indemnisations,
      specifiedType: const FullType(BuiltList, [FullType(IndemnisationVue)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FileIndemnisations object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FileIndemnisationsBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'indemnisations':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(IndemnisationVue)]),
          ) as BuiltList<IndemnisationVue>;
          result.indemnisations.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FileIndemnisations deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FileIndemnisationsBuilder();
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

