//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_element
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:mefali_api_client/src/model/discriminant_consentement.dart';
import 'package:mefali_api_client/src/model/session_ouverte.dart';
import 'package:mefali_api_client/src/model/consentement_requis.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:built_value/built_value.dart';
import 'package:built_value/serializer.dart';
import 'package:one_of/one_of.dart';

part 'resultat_verification.g.dart';

/// Issue de `/auth/otp/verifier` — `oneOf` discriminé par `resultat`.  `untagged` : chaque membre porte DÉJÀ son `resultat`, si bien que le JSON du câble est celui d'un `oneOf` discriminé, tandis que le contrat, lui, expose deux schémas NOMMÉS et réutilisables plutôt que deux objets anonymes.
///
/// Properties:
/// * [compte] - Compte connecté.
/// * [jetons] - Jetons de l'appareil.
/// * [resultat] - Discrimine ce membre du `oneOf` de `/auth/otp/verifier`.
/// * [jetonInscription] - Jeton d'inscription à usage unique.
@BuiltValue()
abstract class ResultatVerification implements Built<ResultatVerification, ResultatVerificationBuilder> {
  /// One Of [ConsentementRequis], [SessionOuverte]
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
    final targetType = const FullType(OneOf, [FullType(SessionOuverte), FullType(ConsentementRequis), ]);
    oneOfDataSrc = serialized;
    result.oneOf = serializers.deserialize(oneOfDataSrc, specifiedType: targetType) as OneOf;
    return result.build();
  }
}

