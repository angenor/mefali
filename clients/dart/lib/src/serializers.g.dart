// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add(Accepte.serializer)
      ..add(ActionBoutiqueDto.serializer)
      ..add(ActionRoleDto.serializer)
      ..add(Adresse.serializer)
      ..add(AffichageRupture.serializer)
      ..add(AppareilDto.serializer)
      ..add(ArretPreProvisionne.serializer)
      ..add(ArticlePublic.serializer)
      ..add(ArticleVendeur.serializer)
      ..add(Attente.serializer)
      ..add(BasculeDisponibiliteDto.serializer)
      ..add(BoutiqueVendeur.serializer)
      ..add(CategorieDto.serializer)
      ..add(CharteAdminDto.serializer)
      ..add(Commande.serializer)
      ..add(CommandeProposee.serializer)
      ..add(Composantes.serializer)
      ..add(ComposantesDevis.serializer)
      ..add(CompteMoi.serializer)
      ..add(ConfigZone.serializer)
      ..add(ConsentementRequis.serializer)
      ..add(CorpsActionBoutique.serializer)
      ..add(CorpsForcage.serializer)
      ..add(CorrigerDto.serializer)
      ..add(CourseActive.serializer)
      ..add(CreerArticleDto.serializer)
      ..add(CreerPrestataireDto.serializer)
      ..add(DecisionRole.serializer)
      ..add(DemandeCollecte.serializer)
      ..add(DemandeCreationCommande.serializer)
      ..add(DemandeDevisPanier.serializer)
      ..add(DemandeOtp.serializer)
      ..add(DemandeRafraichissement.serializer)
      ..add(DemandeSimulation.serializer)
      ..add(Devis.serializer)
      ..add(DevisLivraison.serializer)
      ..add(DevisPanier.serializer)
      ..add(DeviseDto.serializer)
      ..add(DiscriminantConsentement.serializer)
      ..add(DiscriminantSession.serializer)
      ..add(DossierCoursier.serializer)
      ..add(DossierCoursierAdmin.serializer)
      ..add(DrapeauxZone.serializer)
      ..add(ErreurApi.serializer)
      ..add(EtatCategorie.serializer)
      ..add(EtatEffectifBoutique.serializer)
      ..add(EtatRoleDto.serializer)
      ..add(FichePublique.serializer)
      ..add(ForcageDto.serializer)
      ..add(Grille.serializer)
      ..add(GrillesZone.serializer)
      ..add(GroupeVendeur.serializer)
      ..add(HealthResponse.serializer)
      ..add(HorairesSemaineDto.serializer)
      ..add(Inscription.serializer)
      ..add(ItineraireSimule.serializer)
      ..add(JetonsDto.serializer)
      ..add(Lieu.serializer)
      ..add(LigneDevis.serializer)
      ..add(LignePanier.serializer)
      ..add(LivraisonCommande.serializer)
      ..add(ModeCollecte.serializer)
      ..add(ModifierAdresse.serializer)
      ..add(ModifierArticleDto.serializer)
      ..add(ModifierPrestataireDto.serializer)
      ..add(OffreLivraisonVendeur.serializer)
      ..add(PaiementCommande.serializer)
      ..add(PaiementPanier.serializer)
      ..add(PhotoAdminDto.serializer)
      ..add(PlageDto.serializer)
      ..add(PlaqueUrl.serializer)
      ..add(PlateformeDto.serializer)
      ..add(Point.serializer)
      ..add(PrestataireAdmin.serializer)
      ..add(PrestataireAdminDetail.serializer)
      ..add(PrestatairePilotable.serializer)
      ..add(RattachementDto.serializer)
      ..add(RattacherCompteDto.serializer)
      ..add(Regle.serializer)
      ..add(RegleRetenue.serializer)
      ..add(RegleUpsert.serializer)
      ..add(ResolutionPlaque.serializer)
      ..add(ResultatCollecte.serializer)
      ..add(ResultatSimulation.serializer)
      ..add(ResultatVerification.serializer)
      ..add(ScissionProposee.serializer)
      ..add(SecretsRemise.serializer)
      ..add(SessionAppareil.serializer)
      ..add(SessionOuverte.serializer)
      ..add(SignalementRecuDto.serializer)
      ..add(SignalerRuptureDto.serializer)
      ..add(SiteAdminDto.serializer)
      ..add(SiteAdminVueDto.serializer)
      ..add(SourceBascule.serializer)
      ..add(StatutBoutique.serializer)
      ..add(StatutPrestataire.serializer)
      ..add(SuspendreDto.serializer)
      ..add(UrlPresignee.serializer)
      ..add(VehiculeDeclare.serializer)
      ..add(VerificationOtp.serializer)
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(ArretPreProvisionne)]),
          () => ListBuilder<ArretPreProvisionne>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ArticlePublic)]),
          () => ListBuilder<ArticlePublic>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Attente)]),
          () => ListBuilder<Attente>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Point)]),
          () => ListBuilder<Point>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [
            const FullType(BuiltList, const [const FullType(PlageDto)])
          ]),
          () => ListBuilder<BuiltList<PlageDto>>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CategorieDto)]),
          () => ListBuilder<CategorieDto>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(bool)]),
          () => MapBuilder<String, bool>())
      ..addBuilderFactory(
          const FullType(
              BuiltMap, const [const FullType(String), const FullType(String)]),
          () => MapBuilder<String, String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CharteAdminDto)]),
          () => ListBuilder<CharteAdminDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PhotoAdminDto)]),
          () => ListBuilder<PhotoAdminDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(RattachementDto)]),
          () => ListBuilder<RattachementDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CommandeProposee)]),
          () => ListBuilder<CommandeProposee>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EtatRoleDto)]),
          () => ListBuilder<EtatRoleDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(GroupeVendeur)]),
          () => ListBuilder<GroupeVendeur>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneDevis)]),
          () => ListBuilder<LigneDevis>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LignePanier)]),
          () => ListBuilder<LignePanier>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LignePanier)]),
          () => ListBuilder<LignePanier>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlageDto)]),
          () => ListBuilder<PlageDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Regle)]),
          () => ListBuilder<Regle>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(VehiculeDeclare)]),
          () => ListBuilder<VehiculeDeclare>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(VehiculeDeclare)]),
          () => ListBuilder<VehiculeDeclare>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(int)]),
          () => ListBuilder<int>()))
    .build();

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
