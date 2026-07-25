// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_arret_course.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatArretCourse extends EtatArretCourse {
  @override
  final String arretId;
  @override
  final int collectesFaites;
  @override
  final int collectesTotal;
  @override
  final String commandeId;
  @override
  final bool enLivraison;
  @override
  final String livraisonEtat;
  @override
  final String livraisonId;
  @override
  final bool rejeu;
  @override
  final String statut;

  factory _$EtatArretCourse([void Function(EtatArretCourseBuilder)? updates]) =>
      (EtatArretCourseBuilder()..update(updates))._build();

  _$EtatArretCourse._(
      {required this.arretId,
      required this.collectesFaites,
      required this.collectesTotal,
      required this.commandeId,
      required this.enLivraison,
      required this.livraisonEtat,
      required this.livraisonId,
      required this.rejeu,
      required this.statut})
      : super._();
  @override
  EtatArretCourse rebuild(void Function(EtatArretCourseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatArretCourseBuilder toBuilder() => EtatArretCourseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatArretCourse &&
        arretId == other.arretId &&
        collectesFaites == other.collectesFaites &&
        collectesTotal == other.collectesTotal &&
        commandeId == other.commandeId &&
        enLivraison == other.enLivraison &&
        livraisonEtat == other.livraisonEtat &&
        livraisonId == other.livraisonId &&
        rejeu == other.rejeu &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, collectesFaites.hashCode);
    _$hash = $jc(_$hash, collectesTotal.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, enLivraison.hashCode);
    _$hash = $jc(_$hash, livraisonEtat.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, rejeu.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatArretCourse')
          ..add('arretId', arretId)
          ..add('collectesFaites', collectesFaites)
          ..add('collectesTotal', collectesTotal)
          ..add('commandeId', commandeId)
          ..add('enLivraison', enLivraison)
          ..add('livraisonEtat', livraisonEtat)
          ..add('livraisonId', livraisonId)
          ..add('rejeu', rejeu)
          ..add('statut', statut))
        .toString();
  }
}

class EtatArretCourseBuilder
    implements Builder<EtatArretCourse, EtatArretCourseBuilder> {
  _$EtatArretCourse? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  int? _collectesFaites;
  int? get collectesFaites => _$this._collectesFaites;
  set collectesFaites(int? collectesFaites) =>
      _$this._collectesFaites = collectesFaites;

  int? _collectesTotal;
  int? get collectesTotal => _$this._collectesTotal;
  set collectesTotal(int? collectesTotal) =>
      _$this._collectesTotal = collectesTotal;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _enLivraison;
  bool? get enLivraison => _$this._enLivraison;
  set enLivraison(bool? enLivraison) => _$this._enLivraison = enLivraison;

  String? _livraisonEtat;
  String? get livraisonEtat => _$this._livraisonEtat;
  set livraisonEtat(String? livraisonEtat) =>
      _$this._livraisonEtat = livraisonEtat;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  bool? _rejeu;
  bool? get rejeu => _$this._rejeu;
  set rejeu(bool? rejeu) => _$this._rejeu = rejeu;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  EtatArretCourseBuilder() {
    EtatArretCourse._defaults(this);
  }

  EtatArretCourseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _collectesFaites = $v.collectesFaites;
      _collectesTotal = $v.collectesTotal;
      _commandeId = $v.commandeId;
      _enLivraison = $v.enLivraison;
      _livraisonEtat = $v.livraisonEtat;
      _livraisonId = $v.livraisonId;
      _rejeu = $v.rejeu;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatArretCourse other) {
    _$v = other as _$EtatArretCourse;
  }

  @override
  void update(void Function(EtatArretCourseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatArretCourse build() => _build();

  _$EtatArretCourse _build() {
    final _$result = _$v ??
        _$EtatArretCourse._(
          arretId: BuiltValueNullFieldError.checkNotNull(
              arretId, r'EtatArretCourse', 'arretId'),
          collectesFaites: BuiltValueNullFieldError.checkNotNull(
              collectesFaites, r'EtatArretCourse', 'collectesFaites'),
          collectesTotal: BuiltValueNullFieldError.checkNotNull(
              collectesTotal, r'EtatArretCourse', 'collectesTotal'),
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'EtatArretCourse', 'commandeId'),
          enLivraison: BuiltValueNullFieldError.checkNotNull(
              enLivraison, r'EtatArretCourse', 'enLivraison'),
          livraisonEtat: BuiltValueNullFieldError.checkNotNull(
              livraisonEtat, r'EtatArretCourse', 'livraisonEtat'),
          livraisonId: BuiltValueNullFieldError.checkNotNull(
              livraisonId, r'EtatArretCourse', 'livraisonId'),
          rejeu: BuiltValueNullFieldError.checkNotNull(
              rejeu, r'EtatArretCourse', 'rejeu'),
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'EtatArretCourse', 'statut'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
