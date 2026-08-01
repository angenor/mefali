// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_arret.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneArret extends LigneArret {
  @override
  final String libelle;
  @override
  final String ligneId;
  @override
  final String preferenceSubstitution;
  @override
  final int prixUnitaireUnites;
  @override
  final int quantite;
  @override
  final String statut;

  factory _$LigneArret([void Function(LigneArretBuilder)? updates]) =>
      (LigneArretBuilder()..update(updates))._build();

  _$LigneArret._(
      {required this.libelle,
      required this.ligneId,
      required this.preferenceSubstitution,
      required this.prixUnitaireUnites,
      required this.quantite,
      required this.statut})
      : super._();
  @override
  LigneArret rebuild(void Function(LigneArretBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneArretBuilder toBuilder() => LigneArretBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneArret &&
        libelle == other.libelle &&
        ligneId == other.ligneId &&
        preferenceSubstitution == other.preferenceSubstitution &&
        prixUnitaireUnites == other.prixUnitaireUnites &&
        quantite == other.quantite &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, libelle.hashCode);
    _$hash = $jc(_$hash, ligneId.hashCode);
    _$hash = $jc(_$hash, preferenceSubstitution.hashCode);
    _$hash = $jc(_$hash, prixUnitaireUnites.hashCode);
    _$hash = $jc(_$hash, quantite.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneArret')
          ..add('libelle', libelle)
          ..add('ligneId', ligneId)
          ..add('preferenceSubstitution', preferenceSubstitution)
          ..add('prixUnitaireUnites', prixUnitaireUnites)
          ..add('quantite', quantite)
          ..add('statut', statut))
        .toString();
  }
}

class LigneArretBuilder implements Builder<LigneArret, LigneArretBuilder> {
  _$LigneArret? _$v;

  String? _libelle;
  String? get libelle => _$this._libelle;
  set libelle(String? libelle) => _$this._libelle = libelle;

  String? _ligneId;
  String? get ligneId => _$this._ligneId;
  set ligneId(String? ligneId) => _$this._ligneId = ligneId;

  String? _preferenceSubstitution;
  String? get preferenceSubstitution => _$this._preferenceSubstitution;
  set preferenceSubstitution(String? preferenceSubstitution) =>
      _$this._preferenceSubstitution = preferenceSubstitution;

  int? _prixUnitaireUnites;
  int? get prixUnitaireUnites => _$this._prixUnitaireUnites;
  set prixUnitaireUnites(int? prixUnitaireUnites) =>
      _$this._prixUnitaireUnites = prixUnitaireUnites;

  int? _quantite;
  int? get quantite => _$this._quantite;
  set quantite(int? quantite) => _$this._quantite = quantite;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  LigneArretBuilder() {
    LigneArret._defaults(this);
  }

  LigneArretBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _libelle = $v.libelle;
      _ligneId = $v.ligneId;
      _preferenceSubstitution = $v.preferenceSubstitution;
      _prixUnitaireUnites = $v.prixUnitaireUnites;
      _quantite = $v.quantite;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneArret other) {
    _$v = other as _$LigneArret;
  }

  @override
  void update(void Function(LigneArretBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneArret build() => _build();

  _$LigneArret _build() {
    final _$result = _$v ??
        _$LigneArret._(
          libelle: BuiltValueNullFieldError.checkNotNull(
              libelle, r'LigneArret', 'libelle'),
          ligneId: BuiltValueNullFieldError.checkNotNull(
              ligneId, r'LigneArret', 'ligneId'),
          preferenceSubstitution: BuiltValueNullFieldError.checkNotNull(
              preferenceSubstitution, r'LigneArret', 'preferenceSubstitution'),
          prixUnitaireUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnitaireUnites, r'LigneArret', 'prixUnitaireUnites'),
          quantite: BuiltValueNullFieldError.checkNotNull(
              quantite, r'LigneArret', 'quantite'),
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'LigneArret', 'statut'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
