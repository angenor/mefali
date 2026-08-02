// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'serializers.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

Serializers _$serializers = (Serializers().toBuilder()
      ..add(AcceptationOffre.serializer)
      ..add(Accepte.serializer)
      ..add(ActionArret.serializer)
      ..add(ActionBoutiqueDto.serializer)
      ..add(ActionRoleDto.serializer)
      ..add(Adresse.serializer)
      ..add(AffichageRupture.serializer)
      ..add(AlertesDispatch.serializer)
      ..add(AppareilDto.serializer)
      ..add(AppelEnregistre.serializer)
      ..add(AppelJournalise.serializer)
      ..add(ArretCourantSuivi.serializer)
      ..add(ArretCourse.serializer)
      ..add(ArretOffre.serializer)
      ..add(ArticlePublic.serializer)
      ..add(ArticleVendeur.serializer)
      ..add(Attente.serializer)
      ..add(AvanceOffre.serializer)
      ..add(BasculeDisponibilite.serializer)
      ..add(BasculeDisponibiliteDto.serializer)
      ..add(BoutiqueVendeur.serializer)
      ..add(CapaciteCoursier.serializer)
      ..add(CategorieDto.serializer)
      ..add(CharteAdminDto.serializer)
      ..add(ClientCourse.serializer)
      ..add(CloreDossierDto.serializer)
      ..add(Commande.serializer)
      ..add(CommandeEnAttente.serializer)
      ..add(CommandeProposee.serializer)
      ..add(CommandeResumee.serializer)
      ..add(Composantes.serializer)
      ..add(ComposantesDevis.serializer)
      ..add(CompteMoi.serializer)
      ..add(ConfigZone.serializer)
      ..add(ConsentementRequis.serializer)
      ..add(CorpsActionBoutique.serializer)
      ..add(CorpsForcage.serializer)
      ..add(CorrigerDto.serializer)
      ..add(CourseActiveComplete.serializer)
      ..add(CourseBloquee.serializer)
      ..add(CoursierDuPool.serializer)
      ..add(CoursierSuivi.serializer)
      ..add(Creance.serializer)
      ..add(CreerArticleDto.serializer)
      ..add(CreerPrestataireDto.serializer)
      ..add(DecisionDepot.serializer)
      ..add(DecisionIndemnisation.serializer)
      ..add(DecisionOffre.serializer)
      ..add(DecisionRole.serializer)
      ..add(DecisionSubstitution.serializer)
      ..add(DemandeAnnulation.serializer)
      ..add(DemandeAppel.serializer)
      ..add(DemandeCollecte.serializer)
      ..add(DemandeCreationCommande.serializer)
      ..add(DemandeDeblocage.serializer)
      ..add(DemandeDepot.serializer)
      ..add(DemandeDevisPanier.serializer)
      ..add(DemandeEchec.serializer)
      ..add(DemandeIssueAdmin.serializer)
      ..add(DemandeOtp.serializer)
      ..add(DemandePhotoPreuve.serializer)
      ..add(DemandeRafraichissement.serializer)
      ..add(DemandeRemise.serializer)
      ..add(DemandeReprise.serializer)
      ..add(DemandeRupture.serializer)
      ..add(DemandeSimulation.serializer)
      ..add(DestinationOffre.serializer)
      ..add(Devis.serializer)
      ..add(DevisLivraison.serializer)
      ..add(DevisPanier.serializer)
      ..add(DeviseDto.serializer)
      ..add(DiscriminantConsentement.serializer)
      ..add(DiscriminantSession.serializer)
      ..add(DossierCoursier.serializer)
      ..add(DossierCoursierAdmin.serializer)
      ..add(DossierPaiement.serializer)
      ..add(DrapeauxZone.serializer)
      ..add(ErreurApi.serializer)
      ..add(EscaladeDispatch.serializer)
      ..add(EtatArretCourse.serializer)
      ..add(EtatCategorie.serializer)
      ..add(EtatDisponibilite.serializer)
      ..add(EtatEffectifBoutique.serializer)
      ..add(EtatPreuves.serializer)
      ..add(EtatPublicationPosition.serializer)
      ..add(EtatRoleDto.serializer)
      ..add(ExpositionCash.serializer)
      ..add(FichePublique.serializer)
      ..add(FileAttenteCoursier.serializer)
      ..add(FileCreances.serializer)
      ..add(FileDossiers.serializer)
      ..add(FileIndemnisations.serializer)
      ..add(ForcageDto.serializer)
      ..add(GainOffre.serializer)
      ..add(Grille.serializer)
      ..add(GrillesZone.serializer)
      ..add(GroupeVendeur.serializer)
      ..add(HealthResponse.serializer)
      ..add(HorairesSemaineDto.serializer)
      ..add(IndemnisationDecidee.serializer)
      ..add(IndemnisationVue.serializer)
      ..add(Inscription.serializer)
      ..add(IntentionAppel.serializer)
      ..add(IssueAppelDeclaree.serializer)
      ..add(IssueEchec.serializer)
      ..add(IssueRupture.serializer)
      ..add(ItineraireSimule.serializer)
      ..add(JetonsDto.serializer)
      ..add(JourneeCoursier.serializer)
      ..add(Lieu.serializer)
      ..add(LigneArret.serializer)
      ..add(LigneDevis.serializer)
      ..add(LigneExposition.serializer)
      ..add(LigneHistoriqueCaisse.serializer)
      ..add(LignePanier.serializer)
      ..add(LigneRecu.serializer)
      ..add(LigneRegistre.serializer)
      ..add(LitigeVu.serializer)
      ..add(LivraisonCommande.serializer)
      ..add(LotDePresence.serializer)
      ..add(MesCommandes.serializer)
      ..add(ModeCollecte.serializer)
      ..add(ModifierAdresse.serializer)
      ..add(ModifierArticleDto.serializer)
      ..add(ModifierPrestataireDto.serializer)
      ..add(MouvementCaisse.serializer)
      ..add(OffreCourante.serializer)
      ..add(OffreLivraisonDeclaration.serializer)
      ..add(OffreLivraisonReglee.serializer)
      ..add(OffreLivraisonVendeur.serializer)
      ..add(PaiementCommande.serializer)
      ..add(PaiementPanier.serializer)
      ..add(PhotoAdminDto.serializer)
      ..add(PhotoPreuve.serializer)
      ..add(PhotoPreuveDeposee.serializer)
      ..add(PlageDto.serializer)
      ..add(PlaqueUrl.serializer)
      ..add(PlateformeDto.serializer)
      ..add(Point.serializer)
      ..add(PoolDeZone.serializer)
      ..add(PositionSuivi.serializer)
      ..add(PositionsCaisse.serializer)
      ..add(PresenceEnregistree.serializer)
      ..add(PrestataireAdmin.serializer)
      ..add(PrestataireAdminDetail.serializer)
      ..add(PrestatairePilotable.serializer)
      ..add(PreuveAppels.serializer)
      ..add(PreuvePhotos.serializer)
      ..add(PreuvePresence.serializer)
      ..add(PreuvesExploitation.serializer)
      ..add(ProgressionSuivi.serializer)
      ..add(PublicationPosition.serializer)
      ..add(RattachementDto.serializer)
      ..add(RattacherCompteDto.serializer)
      ..add(RecuArret.serializer)
      ..add(RecuCommande.serializer)
      ..add(RefusOffre.serializer)
      ..add(RegistreTransactions.serializer)
      ..add(Regle.serializer)
      ..add(RegleRetenue.serializer)
      ..add(RegleUpsert.serializer)
      ..add(ReglerCreanceDto.serializer)
      ..add(ReleveDePresence.serializer)
      ..add(RemiseBloquee.serializer)
      ..add(RemisePreprovisionnee.serializer)
      ..add(RemisesBloquees.serializer)
      ..add(ReponseNotification.serializer)
      ..add(RepriseFaite.serializer)
      ..add(ResolutionPlaque.serializer)
      ..add(ResultatAnnulation.serializer)
      ..add(ResultatCollecte.serializer)
      ..add(ResultatDecisionSubstitution.serializer)
      ..add(ResultatRemise.serializer)
      ..add(ResultatSimulation.serializer)
      ..add(ResultatVerification.serializer)
      ..add(ScissionProposee.serializer)
      ..add(SecretsRemise.serializer)
      ..add(SessionAppareil.serializer)
      ..add(SessionOuverte.serializer)
      ..add(SessionPaiement.serializer)
      ..add(SeuilsPreuves.serializer)
      ..add(SignalementRecuDto.serializer)
      ..add(SignalerRuptureDto.serializer)
      ..add(SiteAdminDto.serializer)
      ..add(SiteAdminVueDto.serializer)
      ..add(SourceBascule.serializer)
      ..add(StatutBoutique.serializer)
      ..add(StatutPrestataire.serializer)
      ..add(SubstitutionSuivi.serializer)
      ..add(SuiviCommande.serializer)
      ..add(SuspendreDto.serializer)
      ..add(UrlPresignee.serializer)
      ..add(VehiculeDeclare.serializer)
      ..add(VerificationOtp.serializer)
      ..add(VueCaisse.serializer)
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(AppelJournalise)]),
          () => ListBuilder<AppelJournalise>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PhotoPreuve)]),
          () => ListBuilder<PhotoPreuve>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ArretCourse)]),
          () => ListBuilder<ArretCourse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ArretOffre)]),
          () => ListBuilder<ArretOffre>())
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
          const FullType(BuiltList, const [const FullType(CapaciteCoursier)]),
          () => ListBuilder<CapaciteCoursier>())
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
          const FullType(BuiltList, const [const FullType(CommandeEnAttente)]),
          () => ListBuilder<CommandeEnAttente>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CommandeProposee)]),
          () => ListBuilder<CommandeProposee>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CommandeResumee)]),
          () => ListBuilder<CommandeResumee>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CourseBloquee)]),
          () => ListBuilder<CourseBloquee>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EscaladeDispatch)]),
          () => ListBuilder<EscaladeDispatch>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(CoursierDuPool)]),
          () => ListBuilder<CoursierDuPool>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Creance)]),
          () => ListBuilder<Creance>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Creance)]),
          () => ListBuilder<Creance>())
      ..addBuilderFactory(
          const FullType(
              BuiltList, const [const FullType(LigneHistoriqueCaisse)]),
          () => ListBuilder<LigneHistoriqueCaisse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(IndemnisationVue)]),
          () => ListBuilder<IndemnisationVue>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LitigeVu)]),
          () => ListBuilder<LitigeVu>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(MouvementCaisse)]),
          () => ListBuilder<MouvementCaisse>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(DateTime)]),
          () => ListBuilder<DateTime>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(DossierPaiement)]),
          () => ListBuilder<DossierPaiement>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(EtatRoleDto)]),
          () => ListBuilder<EtatRoleDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(GroupeVendeur)]),
          () => ListBuilder<GroupeVendeur>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(IndemnisationVue)]),
          () => ListBuilder<IndemnisationVue>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneArret)]),
          () => ListBuilder<LigneArret>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneDevis)]),
          () => ListBuilder<LigneDevis>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneExposition)]),
          () => ListBuilder<LigneExposition>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LignePanier)]),
          () => ListBuilder<LignePanier>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LignePanier)]),
          () => ListBuilder<LignePanier>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneRecu)]),
          () => ListBuilder<LigneRecu>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneRecu)]),
          () => ListBuilder<LigneRecu>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(LigneRegistre)]),
          () => ListBuilder<LigneRegistre>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(PlageDto)]),
          () => ListBuilder<PlageDto>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(Regle)]),
          () => ListBuilder<Regle>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(ReleveDePresence)]),
          () => ListBuilder<ReleveDePresence>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(RemiseBloquee)]),
          () => ListBuilder<RemiseBloquee>())
      ..addBuilderFactory(
          const FullType(BuiltList, const [const FullType(String)]),
          () => ListBuilder<String>())
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
