//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'seuils_preuves.g.dart';

/// Les seuils de preuve d'échec de la zone.
///
/// Properties:
/// * [appelsMin] - Appels `client_absent` exigés.
/// * [espacementS] - Espacement minimal entre deux appels retenus (s).
/// * [photosMin] - Photos exigées.
/// * [presenceS] - Présence continue exigée (s).
/// * [rayonM] - Rayon dans lequel un relevé compte (m).
@BuiltValue()
abstract class SeuilsPreuves implements Built<SeuilsPreuves, SeuilsPreuvesBuilder> {
  /// Appels `client_absent` exigés.
  @BuiltValueField(wireName: r'appels_min')
  int get appelsMin;

  /// Espacement minimal entre deux appels retenus (s).
  @BuiltValueField(wireName: r'espacement_s')
  int get espacementS;

  /// Photos exigées.
  @BuiltValueField(wireName: r'photos_min')
  int get photosMin;

  /// Présence continue exigée (s).
  @BuiltValueField(wireName: r'presence_s')
  int get presenceS;

  /// Rayon dans lequel un relevé compte (m).
  @BuiltValueField(wireName: r'rayon_m')
  int get rayonM;

  SeuilsPreuves._();

  factory SeuilsPreuves([void updates(SeuilsPreuvesBuilder b)]) = _$SeuilsPreuves;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(SeuilsPreuvesBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<SeuilsPreuves> get serializer => _$SeuilsPreuvesSerializer();
}

class _$SeuilsPreuvesSerializer implements PrimitiveSerializer<SeuilsPreuves> {
  @override
  final Iterable<Type> types = const [SeuilsPreuves, _$SeuilsPreuves];

  @override
  final String wireName = r'SeuilsPreuves';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    SeuilsPreuves object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appels_min';
    yield serializers.serialize(
      object.appelsMin,
      specifiedType: const FullType(int),
    );
    yield r'espacement_s';
    yield serializers.serialize(
      object.espacementS,
      specifiedType: const FullType(int),
    );
    yield r'photos_min';
    yield serializers.serialize(
      object.photosMin,
      specifiedType: const FullType(int),
    );
    yield r'presence_s';
    yield serializers.serialize(
      object.presenceS,
      specifiedType: const FullType(int),
    );
    yield r'rayon_m';
    yield serializers.serialize(
      object.rayonM,
      specifiedType: const FullType(int),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    SeuilsPreuves object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required SeuilsPreuvesBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appels_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.appelsMin = valueDes;
          break;
        case r'espacement_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.espacementS = valueDes;
          break;
        case r'photos_min':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.photosMin = valueDes;
          break;
        case r'presence_s':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.presenceS = valueDes;
          break;
        case r'rayon_m':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(int),
          ) as int;
          result.rayonM = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  SeuilsPreuves deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = SeuilsPreuvesBuilder();
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

