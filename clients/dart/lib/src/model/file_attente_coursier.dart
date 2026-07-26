//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/commande_en_attente.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'file_attente_coursier.g.dart';

/// La file d'attente d'une zone.
///
/// Properties:
/// * [commandes] - Commandes en attente, **la plus ancienne d'abord** (FIFO par âge).
@BuiltValue()
abstract class FileAttenteCoursier implements Built<FileAttenteCoursier, FileAttenteCoursierBuilder> {
  /// Commandes en attente, **la plus ancienne d'abord** (FIFO par âge).
  @BuiltValueField(wireName: r'commandes')
  BuiltList<CommandeEnAttente> get commandes;

  FileAttenteCoursier._();

  factory FileAttenteCoursier([void updates(FileAttenteCoursierBuilder b)]) = _$FileAttenteCoursier;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FileAttenteCoursierBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FileAttenteCoursier> get serializer => _$FileAttenteCoursierSerializer();
}

class _$FileAttenteCoursierSerializer implements PrimitiveSerializer<FileAttenteCoursier> {
  @override
  final Iterable<Type> types = const [FileAttenteCoursier, _$FileAttenteCoursier];

  @override
  final String wireName = r'FileAttenteCoursier';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FileAttenteCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'commandes';
    yield serializers.serialize(
      object.commandes,
      specifiedType: const FullType(BuiltList, [FullType(CommandeEnAttente)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FileAttenteCoursier object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FileAttenteCoursierBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'commandes':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(CommandeEnAttente)]),
          ) as BuiltList<CommandeEnAttente>;
          result.commandes.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FileAttenteCoursier deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FileAttenteCoursierBuilder();
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

