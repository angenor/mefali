// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suivi_commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SuiviCommande extends SuiviCommande {
  @override
  final CoursierSuivi? coursier;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String etatCle;
  @override
  final DateTime etatLe;
  @override
  final String id;
  @override
  final String? livraisonEtat;
  @override
  final String? livraisonId;
  @override
  final int montantArticlesUnites;
  @override
  final PositionSuivi? position;
  @override
  final ProgressionSuivi progression;
  @override
  final SecretsRemise remise;
  @override
  final SubstitutionSuivi? substitutionEnAttente;
  @override
  final int totalUnites;

  factory _$SuiviCommande([void Function(SuiviCommandeBuilder)? updates]) =>
      (SuiviCommandeBuilder()..update(updates))._build();

  _$SuiviCommande._(
      {this.coursier,
      required this.devise,
      required this.etat,
      required this.etatCle,
      required this.etatLe,
      required this.id,
      this.livraisonEtat,
      this.livraisonId,
      required this.montantArticlesUnites,
      this.position,
      required this.progression,
      required this.remise,
      this.substitutionEnAttente,
      required this.totalUnites})
      : super._();
  @override
  SuiviCommande rebuild(void Function(SuiviCommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SuiviCommandeBuilder toBuilder() => SuiviCommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SuiviCommande &&
        coursier == other.coursier &&
        devise == other.devise &&
        etat == other.etat &&
        etatCle == other.etatCle &&
        etatLe == other.etatLe &&
        id == other.id &&
        livraisonEtat == other.livraisonEtat &&
        livraisonId == other.livraisonId &&
        montantArticlesUnites == other.montantArticlesUnites &&
        position == other.position &&
        progression == other.progression &&
        remise == other.remise &&
        substitutionEnAttente == other.substitutionEnAttente &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, coursier.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, etatCle.hashCode);
    _$hash = $jc(_$hash, etatLe.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, livraisonEtat.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, position.hashCode);
    _$hash = $jc(_$hash, progression.hashCode);
    _$hash = $jc(_$hash, remise.hashCode);
    _$hash = $jc(_$hash, substitutionEnAttente.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SuiviCommande')
          ..add('coursier', coursier)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('etatCle', etatCle)
          ..add('etatLe', etatLe)
          ..add('id', id)
          ..add('livraisonEtat', livraisonEtat)
          ..add('livraisonId', livraisonId)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('position', position)
          ..add('progression', progression)
          ..add('remise', remise)
          ..add('substitutionEnAttente', substitutionEnAttente)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class SuiviCommandeBuilder
    implements Builder<SuiviCommande, SuiviCommandeBuilder> {
  _$SuiviCommande? _$v;

  CoursierSuiviBuilder? _coursier;
  CoursierSuiviBuilder get coursier =>
      _$this._coursier ??= CoursierSuiviBuilder();
  set coursier(CoursierSuiviBuilder? coursier) => _$this._coursier = coursier;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _etatCle;
  String? get etatCle => _$this._etatCle;
  set etatCle(String? etatCle) => _$this._etatCle = etatCle;

  DateTime? _etatLe;
  DateTime? get etatLe => _$this._etatLe;
  set etatLe(DateTime? etatLe) => _$this._etatLe = etatLe;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _livraisonEtat;
  String? get livraisonEtat => _$this._livraisonEtat;
  set livraisonEtat(String? livraisonEtat) =>
      _$this._livraisonEtat = livraisonEtat;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  PositionSuiviBuilder? _position;
  PositionSuiviBuilder get position =>
      _$this._position ??= PositionSuiviBuilder();
  set position(PositionSuiviBuilder? position) => _$this._position = position;

  ProgressionSuiviBuilder? _progression;
  ProgressionSuiviBuilder get progression =>
      _$this._progression ??= ProgressionSuiviBuilder();
  set progression(ProgressionSuiviBuilder? progression) =>
      _$this._progression = progression;

  SecretsRemiseBuilder? _remise;
  SecretsRemiseBuilder get remise => _$this._remise ??= SecretsRemiseBuilder();
  set remise(SecretsRemiseBuilder? remise) => _$this._remise = remise;

  SubstitutionSuiviBuilder? _substitutionEnAttente;
  SubstitutionSuiviBuilder get substitutionEnAttente =>
      _$this._substitutionEnAttente ??= SubstitutionSuiviBuilder();
  set substitutionEnAttente(SubstitutionSuiviBuilder? substitutionEnAttente) =>
      _$this._substitutionEnAttente = substitutionEnAttente;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  SuiviCommandeBuilder() {
    SuiviCommande._defaults(this);
  }

  SuiviCommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _coursier = $v.coursier?.toBuilder();
      _devise = $v.devise;
      _etat = $v.etat;
      _etatCle = $v.etatCle;
      _etatLe = $v.etatLe;
      _id = $v.id;
      _livraisonEtat = $v.livraisonEtat;
      _livraisonId = $v.livraisonId;
      _montantArticlesUnites = $v.montantArticlesUnites;
      _position = $v.position?.toBuilder();
      _progression = $v.progression.toBuilder();
      _remise = $v.remise.toBuilder();
      _substitutionEnAttente = $v.substitutionEnAttente?.toBuilder();
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SuiviCommande other) {
    _$v = other as _$SuiviCommande;
  }

  @override
  void update(void Function(SuiviCommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SuiviCommande build() => _build();

  _$SuiviCommande _build() {
    _$SuiviCommande _$result;
    try {
      _$result = _$v ??
          _$SuiviCommande._(
            coursier: _coursier?.build(),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'SuiviCommande', 'devise'),
            etat: BuiltValueNullFieldError.checkNotNull(
                etat, r'SuiviCommande', 'etat'),
            etatCle: BuiltValueNullFieldError.checkNotNull(
                etatCle, r'SuiviCommande', 'etatCle'),
            etatLe: BuiltValueNullFieldError.checkNotNull(
                etatLe, r'SuiviCommande', 'etatLe'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'SuiviCommande', 'id'),
            livraisonEtat: livraisonEtat,
            livraisonId: livraisonId,
            montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                montantArticlesUnites,
                r'SuiviCommande',
                'montantArticlesUnites'),
            position: _position?.build(),
            progression: progression.build(),
            remise: remise.build(),
            substitutionEnAttente: _substitutionEnAttente?.build(),
            totalUnites: BuiltValueNullFieldError.checkNotNull(
                totalUnites, r'SuiviCommande', 'totalUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'coursier';
        _coursier?.build();

        _$failedField = 'position';
        _position?.build();
        _$failedField = 'progression';
        progression.build();
        _$failedField = 'remise';
        remise.build();
        _$failedField = 'substitutionEnAttente';
        _substitutionEnAttente?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'SuiviCommande', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
