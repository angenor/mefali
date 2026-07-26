//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_remise.g.dart';

/// Preuve de remise présentée par le coursier.
///
/// Properties:
/// * [code] - Code à 4 chiffres dicté par le client (mode `code`).
/// * [jeton] - Jeton lu dans le QR de réception (mode `qr`).
/// * [mode] - `qr` | `code` | `depot`.
/// * [photoCle] - Clé de la photo déposée sur place (mode `depot`).
@BuiltValue()
abstract class DemandeRemise implements Built<DemandeRemise, DemandeRemiseBuilder> {
  /// Code à 4 chiffres dicté par le client (mode `code`).
  @BuiltValueField(wireName: r'code')
  String? get code;

  /// Jeton lu dans le QR de réception (mode `qr`).
  @BuiltValueField(wireName: r'jeton')
  String? get jeton;

  /// `qr` | `code` | `depot`.
  @BuiltValueField(wireName: r'mode')
  String get mode;

  /// Clé de la photo déposée sur place (mode `depot`).
  @BuiltValueField(wireName: r'photo_cle')
  String? get photoCle;

  DemandeRemise._();

  factory DemandeRemise([void updates(DemandeRemiseBuilder b)]) = _$DemandeRemise;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeRemiseBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeRemise> get serializer => _$DemandeRemiseSerializer();
}

class _$DemandeRemiseSerializer implements PrimitiveSerializer<DemandeRemise> {
  @override
  final Iterable<Type> types = const [DemandeRemise, _$DemandeRemise];

  @override
  final String wireName = r'DemandeRemise';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    if (object.code != null) {
      yield r'code';
      yield serializers.serialize(
        object.code,
        specifiedType: const FullType.nullable(String),
      );
    }
    if (object.jeton != null) {
      yield r'jeton';
      yield serializers.serialize(
        object.jeton,
        specifiedType: const FullType.nullable(String),
      );
    }
    yield r'mode';
    yield serializers.serialize(
      object.mode,
      specifiedType: const FullType(String),
    );
    if (object.photoCle != null) {
      yield r'photo_cle';
      yield serializers.serialize(
        object.photoCle,
        specifiedType: const FullType.nullable(String),
      );
    }
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeRemise object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeRemiseBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.code = valueDes;
          break;
        case r'jeton':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.jeton = valueDes;
          break;
        case r'mode':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.mode = valueDes;
          break;
        case r'photo_cle':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType.nullable(String),
          ) as String?;
          if (valueDes == null) continue;
          result.photoCle = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeRemise deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeRemiseBuilder();
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

