//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:built_collection/built_collection.dart';
import 'package:mefali_api_client/src/model/resultat_verification_one_of.dart';
import 'package:mefali_api_client/src/model/resultat_verification_one_of1.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'resultat_verification.g.dart';

/// Issue de `/auth/otp/verifier` — `oneOf` discriminé par `resultat`.
///
/// Properties:
/// * [compte] - Compte connecté.
/// * [jetons] - Jetons de l'appareil.
/// * [resultat] 
/// * [jetonInscription] - Jeton d'inscription à usage unique.
@BuiltValue()
abstract class ResultatVerification implements Built<ResultatVerification, ResultatVerificationBuilder> {
  /// One Of [ResultatVerificationOneOf], [ResultatVerificationOneOf1]
  OneOf get oneOf;

  ResultatVerification._();

  factory ResultatVerification([void updates(ResultatVerificationBuilder b)]) = _$ResultatVerification;

  @BuiltValueHook(initializeBuilder: true)
  static void _defaults(ResultatVerificationBuilder b) => b;

  @BuiltValueSerializer(custom: true)
  static Serializer<ResultatVerification> get serializer => _$ResultatVerificationSerializer();
}

class _$ResultatVerificationSerializer implements PrimitiveSerializer<ResultatVerification> {
  @override
  final Iterable<Type> types = const [ResultatVerification, _$ResultatVerification];

  @override
  final String wireName = r'ResultatVerification';

  Iterable<Object?> _serializeProperties(
    Serializers serializers,
    ResultatVerification object, {
    FullType specifiedType = FullType.unspecified,
  }) sync* {
  }

  @override
  Object serialize(
    Serializers serializers,
    ResultatVerification object, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final oneOf = object.oneOf;
    return serializers.serialize(oneOf.value, specifiedType: FullType(oneOf.valueType))!;
  }

  @override
  ResultatVerification deserialize(
    Serializers serializers,
    Object serialized, {
    FullType specifiedType = FullType.unspecified,
  }) {
    final result = ResultatVerificationBuilder();
    Object? oneOfDataSrc;
    final targetType = const FullType(OneOf, [FullType(ResultatVerificationOneOf), FullType(ResultatVerificationOneOf1), ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc, specifiedType: targetType) as OneOf;
    return result.build();
  }
}

class ResultatVerificationResultatEnum extends EnumClass {

  @BuiltValueEnumConst(wireName: r'consentement_requis')
  static const ResultatVerificationResultatEnum consentementRequis = _$resultatVerificationResultatEnum_consentementRequis;

  static Serializer<ResultatVerificationResultatEnum> get serializer => _$resultatVerificationResultatEnumSerializer;

  const ResultatVerificationResultatEnum._(String name): super(name);

  static BuiltSet<ResultatVerificationResultatEnum> get values => _$resultatVerificationResultatEnumValues;
  static ResultatVerificationResultatEnum valueOf(String name) => _$resultatVerificationResultatEnumValueOf(name);
}

