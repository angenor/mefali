// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vue_caisse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$VueCaisse extends VueCaisse {
  @override
  final int avanceEnCoursUnites;
  @override
  final int avancesEnAttenteReglementUnites;
  @override
  final int coursesConcernees;
  @override
  final String devise;
  @override
  final bool ecartPlafond;
  @override
  final BuiltList<LigneHistoriqueCaisse> historiqueDuJour;
  @override
  final BuiltList<IndemnisationVue> indemnisations;
  @override
  final BuiltList<LitigeVu> litigesEnCours;
  @override
  final BuiltList<MouvementCaisse> mouvements;

  factory _$VueCaisse([void Function(VueCaisseBuilder)? updates]) =>
      (VueCaisseBuilder()..update(updates))._build();

  _$VueCaisse._(
      {required this.avanceEnCoursUnites,
      required this.avancesEnAttenteReglementUnites,
      required this.coursesConcernees,
      required this.devise,
      required this.ecartPlafond,
      required this.historiqueDuJour,
      required this.indemnisations,
      required this.litigesEnCours,
      required this.mouvements})
      : super._();
  @override
  VueCaisse rebuild(void Function(VueCaisseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  VueCaisseBuilder toBuilder() => VueCaisseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is VueCaisse &&
        avanceEnCoursUnites == other.avanceEnCoursUnites &&
        avancesEnAttenteReglementUnites ==
            other.avancesEnAttenteReglementUnites &&
        coursesConcernees == other.coursesConcernees &&
        devise == other.devise &&
        ecartPlafond == other.ecartPlafond &&
        historiqueDuJour == other.historiqueDuJour &&
        indemnisations == other.indemnisations &&
        litigesEnCours == other.litigesEnCours &&
        mouvements == other.mouvements;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, avanceEnCoursUnites.hashCode);
    _$hash = $jc(_$hash, avancesEnAttenteReglementUnites.hashCode);
    _$hash = $jc(_$hash, coursesConcernees.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, ecartPlafond.hashCode);
    _$hash = $jc(_$hash, historiqueDuJour.hashCode);
    _$hash = $jc(_$hash, indemnisations.hashCode);
    _$hash = $jc(_$hash, litigesEnCours.hashCode);
    _$hash = $jc(_$hash, mouvements.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'VueCaisse')
          ..add('avanceEnCoursUnites', avanceEnCoursUnites)
          ..add('avancesEnAttenteReglementUnites',
              avancesEnAttenteReglementUnites)
          ..add('coursesConcernees', coursesConcernees)
          ..add('devise', devise)
          ..add('ecartPlafond', ecartPlafond)
          ..add('historiqueDuJour', historiqueDuJour)
          ..add('indemnisations', indemnisations)
          ..add('litigesEnCours', litigesEnCours)
          ..add('mouvements', mouvements))
        .toString();
  }
}

class VueCaisseBuilder implements Builder<VueCaisse, VueCaisseBuilder> {
  _$VueCaisse? _$v;

  int? _avanceEnCoursUnites;
  int? get avanceEnCoursUnites => _$this._avanceEnCoursUnites;
  set avanceEnCoursUnites(int? avanceEnCoursUnites) =>
      _$this._avanceEnCoursUnites = avanceEnCoursUnites;

  int? _avancesEnAttenteReglementUnites;
  int? get avancesEnAttenteReglementUnites =>
      _$this._avancesEnAttenteReglementUnites;
  set avancesEnAttenteReglementUnites(int? avancesEnAttenteReglementUnites) =>
      _$this._avancesEnAttenteReglementUnites = avancesEnAttenteReglementUnites;

  int? _coursesConcernees;
  int? get coursesConcernees => _$this._coursesConcernees;
  set coursesConcernees(int? coursesConcernees) =>
      _$this._coursesConcernees = coursesConcernees;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  bool? _ecartPlafond;
  bool? get ecartPlafond => _$this._ecartPlafond;
  set ecartPlafond(bool? ecartPlafond) => _$this._ecartPlafond = ecartPlafond;

  ListBuilder<LigneHistoriqueCaisse>? _historiqueDuJour;
  ListBuilder<LigneHistoriqueCaisse> get historiqueDuJour =>
      _$this._historiqueDuJour ??= ListBuilder<LigneHistoriqueCaisse>();
  set historiqueDuJour(ListBuilder<LigneHistoriqueCaisse>? historiqueDuJour) =>
      _$this._historiqueDuJour = historiqueDuJour;

  ListBuilder<IndemnisationVue>? _indemnisations;
  ListBuilder<IndemnisationVue> get indemnisations =>
      _$this._indemnisations ??= ListBuilder<IndemnisationVue>();
  set indemnisations(ListBuilder<IndemnisationVue>? indemnisations) =>
      _$this._indemnisations = indemnisations;

  ListBuilder<LitigeVu>? _litigesEnCours;
  ListBuilder<LitigeVu> get litigesEnCours =>
      _$this._litigesEnCours ??= ListBuilder<LitigeVu>();
  set litigesEnCours(ListBuilder<LitigeVu>? litigesEnCours) =>
      _$this._litigesEnCours = litigesEnCours;

  ListBuilder<MouvementCaisse>? _mouvements;
  ListBuilder<MouvementCaisse> get mouvements =>
      _$this._mouvements ??= ListBuilder<MouvementCaisse>();
  set mouvements(ListBuilder<MouvementCaisse>? mouvements) =>
      _$this._mouvements = mouvements;

  VueCaisseBuilder() {
    VueCaisse._defaults(this);
  }

  VueCaisseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _avanceEnCoursUnites = $v.avanceEnCoursUnites;
      _avancesEnAttenteReglementUnites = $v.avancesEnAttenteReglementUnites;
      _coursesConcernees = $v.coursesConcernees;
      _devise = $v.devise;
      _ecartPlafond = $v.ecartPlafond;
      _historiqueDuJour = $v.historiqueDuJour.toBuilder();
      _indemnisations = $v.indemnisations.toBuilder();
      _litigesEnCours = $v.litigesEnCours.toBuilder();
      _mouvements = $v.mouvements.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(VueCaisse other) {
    _$v = other as _$VueCaisse;
  }

  @override
  void update(void Function(VueCaisseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  VueCaisse build() => _build();

  _$VueCaisse _build() {
    _$VueCaisse _$result;
    try {
      _$result = _$v ??
          _$VueCaisse._(
            avanceEnCoursUnites: BuiltValueNullFieldError.checkNotNull(
                avanceEnCoursUnites, r'VueCaisse', 'avanceEnCoursUnites'),
            avancesEnAttenteReglementUnites:
                BuiltValueNullFieldError.checkNotNull(
                    avancesEnAttenteReglementUnites,
                    r'VueCaisse',
                    'avancesEnAttenteReglementUnites'),
            coursesConcernees: BuiltValueNullFieldError.checkNotNull(
                coursesConcernees, r'VueCaisse', 'coursesConcernees'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'VueCaisse', 'devise'),
            ecartPlafond: BuiltValueNullFieldError.checkNotNull(
                ecartPlafond, r'VueCaisse', 'ecartPlafond'),
            historiqueDuJour: historiqueDuJour.build(),
            indemnisations: indemnisations.build(),
            litigesEnCours: litigesEnCours.build(),
            mouvements: mouvements.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'historiqueDuJour';
        historiqueDuJour.build();
        _$failedField = 'indemnisations';
        indemnisations.build();
        _$failedField = 'litigesEnCours';
        litigesEnCours.build();
        _$failedField = 'mouvements';
        mouvements.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'VueCaisse', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
