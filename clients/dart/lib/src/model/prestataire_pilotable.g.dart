// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prestataire_pilotable.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PrestatairePilotable extends PrestatairePilotable {
  @override
  final EtatEffectifBoutique boutique;
  @override
  final String id;
  @override
  final String nom;
  @override
  final String offreLivraison;
  @override
  final int? offreLivraisonSeuilUnites;
  @override
  final StatutPrestataire statut;

  factory _$PrestatairePilotable(
          [void Function(PrestatairePilotableBuilder)? updates]) =>
      (PrestatairePilotableBuilder()..update(updates))._build();

  _$PrestatairePilotable._(
      {required this.boutique,
      required this.id,
      required this.nom,
      required this.offreLivraison,
      this.offreLivraisonSeuilUnites,
      required this.statut})
      : super._();
  @override
  PrestatairePilotable rebuild(
          void Function(PrestatairePilotableBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PrestatairePilotableBuilder toBuilder() =>
      PrestatairePilotableBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PrestatairePilotable &&
        boutique == other.boutique &&
        id == other.id &&
        nom == other.nom &&
        offreLivraison == other.offreLivraison &&
        offreLivraisonSeuilUnites == other.offreLivraisonSeuilUnites &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, boutique.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, offreLivraison.hashCode);
    _$hash = $jc(_$hash, offreLivraisonSeuilUnites.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PrestatairePilotable')
          ..add('boutique', boutique)
          ..add('id', id)
          ..add('nom', nom)
          ..add('offreLivraison', offreLivraison)
          ..add('offreLivraisonSeuilUnites', offreLivraisonSeuilUnites)
          ..add('statut', statut))
        .toString();
  }
}

class PrestatairePilotableBuilder
    implements Builder<PrestatairePilotable, PrestatairePilotableBuilder> {
  _$PrestatairePilotable? _$v;

  EtatEffectifBoutiqueBuilder? _boutique;
  EtatEffectifBoutiqueBuilder get boutique =>
      _$this._boutique ??= EtatEffectifBoutiqueBuilder();
  set boutique(EtatEffectifBoutiqueBuilder? boutique) =>
      _$this._boutique = boutique;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  String? _offreLivraison;
  String? get offreLivraison => _$this._offreLivraison;
  set offreLivraison(String? offreLivraison) =>
      _$this._offreLivraison = offreLivraison;

  int? _offreLivraisonSeuilUnites;
  int? get offreLivraisonSeuilUnites => _$this._offreLivraisonSeuilUnites;
  set offreLivraisonSeuilUnites(int? offreLivraisonSeuilUnites) =>
      _$this._offreLivraisonSeuilUnites = offreLivraisonSeuilUnites;

  StatutPrestataire? _statut;
  StatutPrestataire? get statut => _$this._statut;
  set statut(StatutPrestataire? statut) => _$this._statut = statut;

  PrestatairePilotableBuilder() {
    PrestatairePilotable._defaults(this);
  }

  PrestatairePilotableBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _boutique = $v.boutique.toBuilder();
      _id = $v.id;
      _nom = $v.nom;
      _offreLivraison = $v.offreLivraison;
      _offreLivraisonSeuilUnites = $v.offreLivraisonSeuilUnites;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PrestatairePilotable other) {
    _$v = other as _$PrestatairePilotable;
  }

  @override
  void update(void Function(PrestatairePilotableBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PrestatairePilotable build() => _build();

  _$PrestatairePilotable _build() {
    _$PrestatairePilotable _$result;
    try {
      _$result = _$v ??
          _$PrestatairePilotable._(
            boutique: boutique.build(),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'PrestatairePilotable', 'id'),
            nom: BuiltValueNullFieldError.checkNotNull(
                nom, r'PrestatairePilotable', 'nom'),
            offreLivraison: BuiltValueNullFieldError.checkNotNull(
                offreLivraison, r'PrestatairePilotable', 'offreLivraison'),
            offreLivraisonSeuilUnites: offreLivraisonSeuilUnites,
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'PrestatairePilotable', 'statut'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'boutique';
        boutique.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PrestatairePilotable', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
