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
import 'package:mefali_api_client/src/model/action_role_dto.dart';
import 'package:mefali_api_client/src/model/adresse.dart';
import 'package:mefali_api_client/src/model/affichage_rupture.dart';
import 'package:mefali_api_client/src/model/appareil_dto.dart';
import 'package:mefali_api_client/src/model/article_public.dart';
import 'package:mefali_api_client/src/model/categorie_dto.dart';
import 'package:mefali_api_client/src/model/charte_admin_dto.dart';
import 'package:mefali_api_client/src/model/compte_moi.dart';
import 'package:mefali_api_client/src/model/config_zone.dart';
import 'package:mefali_api_client/src/model/consentement_requis.dart';
import 'package:mefali_api_client/src/model/corps_forcage.dart';
import 'package:mefali_api_client/src/model/creer_prestataire_dto.dart';
import 'package:mefali_api_client/src/model/decision_role.dart';
import 'package:mefali_api_client/src/model/demande_otp.dart';
import 'package:mefali_api_client/src/model/demande_rafraichissement.dart';
import 'package:mefali_api_client/src/model/devise_dto.dart';
import 'package:mefali_api_client/src/model/discriminant_consentement.dart';
import 'package:mefali_api_client/src/model/discriminant_session.dart';
import 'package:mefali_api_client/src/model/dossier_coursier.dart';
import 'package:mefali_api_client/src/model/dossier_coursier_admin.dart';
import 'package:mefali_api_client/src/model/erreur_api.dart';
import 'package:mefali_api_client/src/model/etat_categorie.dart';
import 'package:mefali_api_client/src/model/etat_effectif_boutique.dart';
import 'package:mefali_api_client/src/model/etat_role_dto.dart';
import 'package:mefali_api_client/src/model/fiche_publique.dart';
import 'package:mefali_api_client/src/model/forcage_dto.dart';
import 'package:mefali_api_client/src/model/health_response.dart';
import 'package:mefali_api_client/src/model/horaires_semaine_dto.dart';
import 'package:mefali_api_client/src/model/inscription.dart';
import 'package:mefali_api_client/src/model/jetons_dto.dart';
import 'package:mefali_api_client/src/model/modifier_adresse.dart';
import 'package:mefali_api_client/src/model/modifier_prestataire_dto.dart';
import 'package:mefali_api_client/src/model/photo_admin_dto.dart';
import 'package:mefali_api_client/src/model/plage_dto.dart';
import 'package:mefali_api_client/src/model/plateforme_dto.dart';
import 'package:mefali_api_client/src/model/prestataire_admin.dart';
import 'package:mefali_api_client/src/model/prestataire_admin_detail.dart';
import 'package:mefali_api_client/src/model/prestataire_pilotable.dart';
import 'package:mefali_api_client/src/model/rattachement_dto.dart';
import 'package:mefali_api_client/src/model/rattacher_compte_dto.dart';
import 'package:mefali_api_client/src/model/resolution_plaque.dart';
import 'package:mefali_api_client/src/model/resultat_verification.dart';
import 'package:mefali_api_client/src/model/session_appareil.dart';
import 'package:mefali_api_client/src/model/session_ouverte.dart';
import 'package:mefali_api_client/src/model/site_admin_dto.dart';
import 'package:mefali_api_client/src/model/site_admin_vue_dto.dart';
import 'package:mefali_api_client/src/model/statut_boutique.dart';
import 'package:mefali_api_client/src/model/statut_prestataire.dart';
import 'package:mefali_api_client/src/model/url_presignee.dart';
import 'package:mefali_api_client/src/model/vehicule_declare.dart';
import 'package:mefali_api_client/src/model/verification_otp.dart';

part 'serializers.g.dart';

@SerializersFor([
  Accepte,
  ActionRoleDto,
  Adresse,
  AffichageRupture,
  AppareilDto,
  ArticlePublic,
  CategorieDto,
  CharteAdminDto,
  CompteMoi,
  ConfigZone,
  ConsentementRequis,
  CorpsForcage,
  CreerPrestataireDto,
  DecisionRole,
  DemandeOtp,
  DemandeRafraichissement,
  DeviseDto,
  DiscriminantConsentement,
  DiscriminantSession,
  DossierCoursier,
  DossierCoursierAdmin,
  ErreurApi,
  EtatCategorie,
  EtatEffectifBoutique,
  EtatRoleDto,
  FichePublique,
  ForcageDto,
  HealthResponse,
  HorairesSemaineDto,
  Inscription,
  JetonsDto,
  ModifierAdresse,
  ModifierPrestataireDto,
  PhotoAdminDto,
  PlageDto,
  PlateformeDto,
  PrestataireAdmin,
  PrestataireAdminDetail,
  PrestatairePilotable,
  RattachementDto,
  RattacherCompteDto,
  ResolutionPlaque,
  ResultatVerification,
  SessionAppareil,
  SessionOuverte,
  SiteAdminDto,
  SiteAdminVueDto,
  StatutBoutique,
  StatutPrestataire,
  UrlPresignee,
  VehiculeDeclare,
  VerificationOtp,
])
Serializers serializers = (_$serializers.toBuilder()
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(Adresse)]),
        () => ListBuilder<Adresse>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PrestataireAdmin)]),
        () => ListBuilder<PrestataireAdmin>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(SessionAppareil)]),
        () => ListBuilder<SessionAppareil>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(String)]),
        () => ListBuilder<String>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(PrestatairePilotable)]),
        () => ListBuilder<PrestatairePilotable>(),
      )
      ..addBuilderFactory(
        const FullType(BuiltList, [FullType(DossierCoursierAdmin)]),
        () => ListBuilder<DossierCoursierAdmin>(),
      )
      ..add(const OneOfSerializer())
      ..add(const AnyOfSerializer())
      ..add(const DateSerializer())
      ..add(Iso8601DateTimeSerializer())
    ).build();

Serializers standardSerializers =
    (serializers.toBuilder()..addPlugin(StandardJsonPlugin())).build();
