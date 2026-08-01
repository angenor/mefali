//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/creance.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'file_creances.g.dart';

/// La file des créances, avec son total dû.
///
/// Properties:
/// * [creances] - Créances, la plus récente d'abord.
/// * [totalDuUnites] - Somme des créances **dues** de la sélection — l'exposition de Mefali envers ses coursiers (FR-065).
@BuiltValue()
abstract class FileCreances implements Built<FileCreances, FileCreancesBuilder> {
  /// Créances, la plus récente d'abord.
  @BuiltValueField(wireName: r'creances')
  BuiltList<Creance> get creances;

  /// Somme des créances **dues** de la sélection — l'exposition de Mefali envers ses coursiers (FR-065).
  @BuiltValueField(wireName: r'total_du_unites')
  int get totalDuUnites;

  FileCreances._();

  factory FileCreances([void updates(FileCreancesBuilder b)]) = _$FileCreances;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FileCreancesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FileCreances> get serializer => _$FileCreancesSerializer();
}

class _$FileCreancesSerializer implements PrimitiveSerializer<FileCreances> {
  @override
  final Iterable<Type> types = const [FileCreances, _$FileCreances];

  @override
  final String wireName = r'FileCreances';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FileCreances object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'creances';
    yield serializers.serialize(
      object.creances,
      specifiedType: const FullType(BuiltList, [FullType(Creance)]),
    );
    yield r'total_du_unites';
    yield serializers.serialize(
      object.totalDuUnites,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FileCreances object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FileCreancesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'creances':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(Creance)]),
          ) as BuiltList<Creance>;
          result.creances.replace(valueDes);
          break;
        case r'total_du_unites':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.totalDuUnites = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FileCreances deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FileCreancesBuilder();
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

