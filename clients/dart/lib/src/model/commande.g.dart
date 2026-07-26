// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Commande extends Commande {
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String id;
  @override
  final LivraisonCommande? livraison;
  @override
  final int montantArticlesUnites;
  @override
  final PaiementCommande paiement;
  @override
  final SecretsRemise remise;
  @override
  final int totalUnites;

  factory _$Commande([void Function(CommandeBuilder)? updates]) =>
      (CommandeBuilder()..update(updates))._build();

  _$Commande._(
      {required this.devise,
      required this.etat,
      required this.id,
      this.livraison,
      required this.montantArticlesUnites,
      required this.paiement,
      required this.remise,
      required this.totalUnites})
      : super._();
  @override
  Commande rebuild(void Function(CommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandeBuilder toBuilder() => CommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Commande &&
        devise == other.devise &&
        etat == other.etat &&
        id == other.id &&
        livraison == other.livraison &&
        montantArticlesUnites == other.montantArticlesUnites &&
        paiement == other.paiement &&
        remise == other.remise &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, livraison.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, paiement.hashCode);
    _$hash = $jc(_$hash, remise.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Commande')
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('id', id)
          ..add('livraison', livraison)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('paiement', paiement)
          ..add('remise', remise)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class CommandeBuilder implements Builder<Commande, CommandeBuilder> {
  _$Commande? _$v;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  LivraisonCommandeBuilder? _livraison;
  LivraisonCommandeBuilder get livraison =>
      _$this._livraison ??= LivraisonCommandeBuilder();
  set livraison(LivraisonCommandeBuilder? livraison) =>
      _$this._livraison = livraison;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  PaiementCommandeBuilder? _paiement;
  PaiementCommandeBuilder get paiement =>
      _$this._paiement ??= PaiementCommandeBuilder();
  set paiement(PaiementCommandeBuilder? paiement) =>
      _$this._paiement = paiement;

  SecretsRemiseBuilder? _remise;
  SecretsRemiseBuilder get remise => _$this._remise ??= SecretsRemiseBuilder();
  set remise(SecretsRemiseBuilder? remise) => _$this._remise = remise;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  CommandeBuilder() {
    Commande._defaults(this);
  }

  CommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _devise = $v.devise;
      _etat = $v.etat;
      _id = $v.id;
      _livraison = $v.livraison?.toBuilder();
      _montantArticlesUnites = $v.montantArticlesUnites;
      _paiement = $v.paiement.toBuilder();
      _remise = $v.remise.toBuilder();
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Commande other) {
    _$v = other as _$Commande;
  }

  @override
  void update(void Function(CommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Commande build() => _build();

  _$Commande _build() {
    _$Commande _$result;
    try {
      _$result = _$v ??
          _$Commande._(
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'Commande', 'devise'),
            etat: BuiltValueNullFieldError.checkNotNull(
                etat, r'Commande', 'etat'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'Commande', 'id'),
            livraison: _livraison?.build(),
            montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                montantArticlesUnites, r'Commande', 'montantArticlesUnites'),
            paiement: paiement.build(),
            remise: remise.build(),
            totalUnites: BuiltValueNullFieldError.checkNotNull(
                totalUnites, r'Commande', 'totalUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'livraison';
        _livraison?.build();

        _$failedField = 'paiement';
        paiement.build();
        _$failedField = 'remise';
        remise.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Commande', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
