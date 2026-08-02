// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_recu.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LigneRecu extends LigneRecu {
  @override
  final String libelle;
  @override
  final int prixUnitaire;
  @override
  final int quantite;
  @override
  final int sousTotalUnites;
  @override
  final String statut;

  factory _$LigneRecu([void Function(LigneRecuBuilder)? updates]) =>
      (LigneRecuBuilder()..update(updates))._build();

  _$LigneRecu._(
      {required this.libelle,
      required this.prixUnitaire,
      required this.quantite,
      required this.sousTotalUnites,
      required this.statut})
      : super._();
  @override
  LigneRecu rebuild(void Function(LigneRecuBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LigneRecuBuilder toBuilder() => LigneRecuBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LigneRecu &&
        libelle == other.libelle &&
        prixUnitaire == other.prixUnitaire &&
        quantite == other.quantite &&
        sousTotalUnites == other.sousTotalUnites &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, libelle.hashCode);
    _$hash = $jc(_$hash, prixUnitaire.hashCode);
    _$hash = $jc(_$hash, quantite.hashCode);
    _$hash = $jc(_$hash, sousTotalUnites.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LigneRecu')
          ..add('libelle', libelle)
          ..add('prixUnitaire', prixUnitaire)
          ..add('quantite', quantite)
          ..add('sousTotalUnites', sousTotalUnites)
          ..add('statut', statut))
        .toString();
  }
}

class LigneRecuBuilder implements Builder<LigneRecu, LigneRecuBuilder> {
  _$LigneRecu? _$v;

  String? _libelle;
  String? get libelle => _$this._libelle;
  set libelle(String? libelle) => _$this._libelle = libelle;

  int? _prixUnitaire;
  int? get prixUnitaire => _$this._prixUnitaire;
  set prixUnitaire(int? prixUnitaire) => _$this._prixUnitaire = prixUnitaire;

  int? _quantite;
  int? get quantite => _$this._quantite;
  set quantite(int? quantite) => _$this._quantite = quantite;

  int? _sousTotalUnites;
  int? get sousTotalUnites => _$this._sousTotalUnites;
  set sousTotalUnites(int? sousTotalUnites) =>
      _$this._sousTotalUnites = sousTotalUnites;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  LigneRecuBuilder() {
    LigneRecu._defaults(this);
  }

  LigneRecuBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _libelle = $v.libelle;
      _prixUnitaire = $v.prixUnitaire;
      _quantite = $v.quantite;
      _sousTotalUnites = $v.sousTotalUnites;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LigneRecu other) {
    _$v = other as _$LigneRecu;
  }

  @override
  void update(void Function(LigneRecuBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LigneRecu build() => _build();

  _$LigneRecu _build() {
    final _$result = _$v ??
        _$LigneRecu._(
          libelle: BuiltValueNullFieldError.checkNotNull(
              libelle, r'LigneRecu', 'libelle'),
          prixUnitaire: BuiltValueNullFieldError.checkNotNull(
              prixUnitaire, r'LigneRecu', 'prixUnitaire'),
          quantite: BuiltValueNullFieldError.checkNotNull(
              quantite, r'LigneRecu', 'quantite'),
          sousTotalUnites: BuiltValueNullFieldError.checkNotNull(
              sousTotalUnites, r'LigneRecu', 'sousTotalUnites'),
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'LigneRecu', 'statut'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
