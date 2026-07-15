//
// AUTO-GENERATED FILE, DO NOT MODIFY!
//

// ignore_for_file: unused_import

import 'package:one_of_serializer/any_of_serializer.dart';
import 'package:one_of_serializer/one_of_serializer.dart';
import 'package:built_collection/built_collection.dart';
import 'package:built_value/json_object.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
import 'package:built_value/iso_8601_date_time_serializer.dart';
import 'package:mefali_api_client/src/date_serializer.dart';
import 'package:mefali_api_client/src/model/date.dart';

import 'package:mefali_api_client/src/model/accepte.dart';
import 'package:mefali_api_client/src/model/appareil_dto.dart';
import 'package:mefali_api_client/src/model/categorie_dto.dart';
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:mefali_api_client/src/model/config_zone.dart';
import 'package:mefali_api_client/src/model/corps_forcage.dart';
import 'package:mefali_api_client/src/model/demande_otp.dart';
import 'package:mefali_api_client/src/model/demande_rafraichissement.dart';
import 'package:mefali_api_client/src/model/devise_dto.dart';
import 'package:mefali_api_client/src/model/erreur_api.dart';
import 'package:mefali_api_client/src/model/etat_categorie.dart';
import 'package:mefali_api_client/src/model/etat_role_dto.dart';
import 'package:mefali_api_client/src/model/forcage_dto.dart';
import 'package:mefali_api_client/src/model/health_response.dart';
import 'package:mefali_api_client/src/model/inscription.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:mefali_api_client/src/model/plateforme_dto.dart';
import 'package:mefali_api_client/src/model/resultat_verification.dart';
import 'package:mefali_api_client/src/model/resultat_verification_one_of.dart';
import 'package:mefali_api_client/src/model/resultat_verification_one_of1.dart';
import 'package:mefali_api_client/src/model/session_appareil.dart';
import 'package:mefali_api_client/src/model/verification_otp.dart';

part 'serializers.g.dart';

@SerializersFor([
  Accepte,
  AppareilDto,
  CategorieDto,
  CompteMoi,
  ConfigZone,
  CorpsForcage,
  DemandeOtp,
  DemandeRafraichissement,
  DeviseDto,
  ErreurApi,
  EtatCategorie,
  EtatRoleDto,
  ForcageDto,
  HealthResponse,
  Inscription,
  JetonsDto,
  PlateformeDto,
  ResultatVerification,
  ResultatVerificationOneOf,
  ResultatVerificationOneOf1,
  SessionAppareil,
  VerificationOtp,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SessionAppareil)]),
        () => ListBuilder<SessionAppareil>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
