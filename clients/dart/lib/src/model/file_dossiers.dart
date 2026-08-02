//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/dossier_paiement.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'file_dossiers.g.dart';

/// La file des anomalies d'argent.
///
/// Properties:
/// * [dossiers] - Dossiers, le plus récent d'abord.
@BuiltValue()
abstract class FileDossiers implements Built<FileDossiers, FileDossiersBuilder> {
  /// Dossiers, le plus récent d'abord.
  @BuiltValueField(wireName: r'dossiers')
  BuiltList<DossierPaiement> get dossiers;

  FileDossiers._();

  factory FileDossiers([void updates(FileDossiersBuilder b)]) = _$FileDossiers;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(FileDossiersBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<FileDossiers> get serializer => _$FileDossiersSerializer();
}

class _$FileDossiersSerializer implements PrimitiveSerializer<FileDossiers> {
  @override
  final Iterable<Type> types = const [FileDossiers, _$FileDossiers];

  @override
  final String wireName = r'FileDossiers';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    FileDossiers object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'dossiers';
    yield serializers.serialize(
      object.dossiers,
      specifiedType: const FullType(BuiltList, [FullType(DossierPaiement)]),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    FileDossiers object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required FileDossiersBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'dossiers':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(BuiltList, [FullType(DossierPaiement)]),
          ) as BuiltList<DossierPaiement>;
          result.dossiers.replace(valueDes);
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  FileDossiers deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = FileDossiersBuilder();
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

