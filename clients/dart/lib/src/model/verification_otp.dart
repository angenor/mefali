//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/appareil_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';

part 'verification_otp.g.dart';

/// Corps de `POST /auth/otp/verifier`.
///
/// Properties:
/// * [appareil] - Appareil — capté ici, conservé jusqu'à l'inscription (R3).
/// * [code] - Code à 6 chiffres.
/// * [telephone] - Le MÊME numéro que celui de la demande.
/// * [zone] - Zone de l'app.
@BuiltValue()
abstract class VerificationOtp implements Built<VerificationOtp, VerificationOtpBuilder> {
  /// Appareil — capté ici, conservé jusqu'à l'inscription (R3).
  @BuiltValueField(wireName: r'appareil')
  AppareilDto get appareil;

  /// Code à 6 chiffres.
  @BuiltValueField(wireName: r'code')
  String get code;

  /// Le MÊME numéro que celui de la demande.
  @BuiltValueField(wireName: r'telephone')
  String get telephone;

  /// Zone de l'app.
  @BuiltValueField(wireName: r'zone')
  String get zone;

  VerificationOtp._();

  factory VerificationOtp([void updates(VerificationOtpBuilder b)]) = _$VerificationOtp;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(VerificationOtpBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<VerificationOtp> get serializer => _$VerificationOtpSerializer();
}

class _$VerificationOtpSerializer implements PrimitiveSerializer<VerificationOtp> {
  @override
  final Iterable<Type> types = const [VerificationOtp, _$VerificationOtp];

  @override
  final String wireName = r'VerificationOtp';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    VerificationOtp object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
    yield r'appareil';
    yield serializers.serialize(
      object.appareil,
      specifiedType: const FullType(AppareilDto),
    );
    yield r'code';
    yield serializers.serialize(
      object.code,
      specifiedType: const FullType(String),
    );
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
    VerificationOtp object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    return _serializeProperties(serializers, object, specifiedType: specifiedType).toList();
  }

  void _deserializeProperties(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
    required List<Object?> serializedList,
    required VerificationOtpBuilder result,
    required List<Object?> unhandled,
  }) {
    for (var i = 0; i < serializedList.length; i += 2) {
      final key = serializedList[i] as String;
      final value = serializedList[i + 1];
      switch (key) {
        case r'appareil':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(AppareilDto),
          ) as AppareilDto;
          result.appareil.replace(valueDes);
          break;
        case r'code':
          final valueDes = serializers.deserialize(
            value,
            specifiedType: const FullType(String),
          ) as String;
          result.code = valueDes;
          break;
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
  VerificationOtp deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = VerificationOtpBuilder();
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

