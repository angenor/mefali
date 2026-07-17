//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'demande_otp.g.dart';

/// Corps de `POST /auth/otp/demander`.
///
/// Properties:
/// * [telephone] - Saisie locale ou E.164 — normalisée avec l'indicatif de la zone (R4).
/// * [zone] - Zone de l'app (bootstrap Tiassalé — R13).
@BuiltValue()
abstract class DemandeOtp implements Built<DemandeOtp, DemandeOtpBuilder> {
  /// Saisie locale ou E.164 — normalisée avec l'indicatif de la zone (R4).
  @BuiltValueField(wireName: r'telephone')
  String get telephone;

  /// Zone de l'app (bootstrap Tiassalé — R13).
  @BuiltValueField(wireName: r'zone')
  String get zone;

  DemandeOtp._();

  factory DemandeOtp([void updates(DemandeOtpBuilder b)]) = _$DemandeOtp;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(DemandeOtpBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<DemandeOtp> get serializer => _$DemandeOtpSerializer();
}

class _$DemandeOtpSerializer implements PrimitiveSerializer<DemandeOtp> {
  @override
  final Iterable<Type> types = const [DemandeOtp, _$DemandeOtp];

  @override
  final String wireName = r'DemandeOtp';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    DemandeOtp object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'telephone';
    yield serializers.serialize(
      object.telephone,
      specifiedType: const FullType(String),
    );
    yield r'zone';
    yield serializers.serialize(
      object.zone,
      specifiedType: const FullType(String),
    );
  }

  @override
  Object serialize(
    Serializers serializers,
    DemandeOtp object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required DemandeOtpBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'telephone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.telephone = valueDes;
          break;
        case r'zone':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.zone = valueDes;
          break;
        default:
          unhandled.add(key);
          unhandled.add(value);
          break;
      }
    }
  }

  @override
  DemandeOtp deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = DemandeOtpBuilder();
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

