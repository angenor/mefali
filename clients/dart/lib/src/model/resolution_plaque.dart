//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'resolution_plaque.g.dart';

/// Résolution d'un jeton de plaque (contrat).
///
/// Properties:
/// * [prestataireId] - Prestataire que la plaque désigne.
/// * [valide] - Validité courante — DÉRIVÉE de l'état d'agrément (FR-015).
@BuiltValue()
abstract class ResolutionPlaque implements Built<ResolutionPlaque, ResolutionPlaqueBuilder> {
  /// Prestataire que la plaque désigne.
  @BuiltValueField(wireName: r'prestataire_id')
  String get prestataireId;

  /// Validité courante — DÉRIVÉE de l'état d'agrément (FR-015).
  @BuiltValueField(wireName: r'valide')
  bool get valide;

  ResolutionPlaque._();

  factory ResolutionPlaque([void updates(ResolutionPlaqueBuilder b)]) = _$ResolutionPlaque;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResolutionPlaqueBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResolutionPlaque> get serializer => _$ResolutionPlaqueSerializer();
}

class _$ResolutionPlaqueSerializer implements PrimitiveSerializer<ResolutionPlaque> {
  @override
  final Iterable<Type> types = const [ResolutionPlaque, _$ResolutionPlaque];

  @override
  final String wireName = r'ResolutionPlaque';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResolutionPlaque object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'prestataire_id';
    yield serializers.serialize(
      object.prestataireId,
      specifiedType: const FullType(String),
    );
    yield r'valide';
    yield serializers.serialize(
      object.valide,
      specifiedType: const FullType(bool),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    ResolutionPlaque object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required ResolutionPlaqueBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'prestataire_id':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.prestataireId = valueDes;
          break;
        case r'valide':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(bool),
          ) as bool;
          result.valide = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  ResolutionPlaque deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResolutionPlaqueBuilder();
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

