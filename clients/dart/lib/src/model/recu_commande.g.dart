// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recu_commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RecuCommande extends RecuCommande {
  @override
  final String commandeId;
  @override
  final bool dejaRegle;
  @override
  final String devise;
  @override
  final int fraisLivraisonUnites;
  @override
  final BuiltList<LigneRecu> lignes;
  @override
  final String modePaiement;
  @override
  final int montantARemettreAuCoursierUnites;
  @override
  final int montantArticlesUnites;
  @override
  final String? moyen;
  @override
  final int retenueVendeurUnites;
  @override
  final int totalDuUnites;

  factory _$RecuCommande([void Function(RecuCommandeBuilder)? updates]) =>
      (RecuCommandeBuilder()..update(updates))._build();

  _$RecuCommande._(
      {required this.commandeId,
      required this.dejaRegle,
      required this.devise,
      required this.fraisLivraisonUnites,
      required this.lignes,
      required this.modePaiement,
      required this.montantARemettreAuCoursierUnites,
      required this.montantArticlesUnites,
      this.moyen,
      required this.retenueVendeurUnites,
      required this.totalDuUnites})
      : super._();
  @override
  RecuCommande rebuild(void Function(RecuCommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RecuCommandeBuilder toBuilder() => RecuCommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RecuCommande &&
        commandeId == other.commandeId &&
        dejaRegle == other.dejaRegle &&
        devise == other.devise &&
        fraisLivraisonUnites == other.fraisLivraisonUnites &&
        lignes == other.lignes &&
        modePaiement == other.modePaiement &&
        montantARemettreAuCoursierUnites ==
            other.montantARemettreAuCoursierUnites &&
        montantArticlesUnites == other.montantArticlesUnites &&
        moyen == other.moyen &&
        retenueVendeurUnites == other.retenueVendeurUnites &&
        totalDuUnites == other.totalDuUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, dejaRegle.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, fraisLivraisonUnites.hashCode);
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, modePaiement.hashCode);
    _$hash = $jc(_$hash, montantARemettreAuCoursierUnites.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, moyen.hashCode);
    _$hash = $jc(_$hash, retenueVendeurUnites.hashCode);
    _$hash = $jc(_$hash, totalDuUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RecuCommande')
          ..add('commandeId', commandeId)
          ..add('dejaRegle', dejaRegle)
          ..add('devise', devise)
          ..add('fraisLivraisonUnites', fraisLivraisonUnites)
          ..add('lignes', lignes)
          ..add('modePaiement', modePaiement)
          ..add('montantARemettreAuCoursierUnites',
              montantARemettreAuCoursierUnites)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('moyen', moyen)
          ..add('retenueVendeurUnites', retenueVendeurUnites)
          ..add('totalDuUnites', totalDuUnites))
        .toString();
  }
}

class RecuCommandeBuilder
    implements Builder<RecuCommande, RecuCommandeBuilder> {
  _$RecuCommande? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _dejaRegle;
  bool? get dejaRegle => _$this._dejaRegle;
  set dejaRegle(bool? dejaRegle) => _$this._dejaRegle = dejaRegle;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _fraisLivraisonUnites;
  int? get fraisLivraisonUnites => _$this._fraisLivraisonUnites;
  set fraisLivraisonUnites(int? fraisLivraisonUnites) =>
      _$this._fraisLivraisonUnites = fraisLivraisonUnites;

  ListBuilder<LigneRecu>? _lignes;
  ListBuilder<LigneRecu> get lignes =>
      _$this._lignes ??= ListBuilder<LigneRecu>();
  set lignes(ListBuilder<LigneRecu>? lignes) => _$this._lignes = lignes;

  String? _modePaiement;
  String? get modePaiement => _$this._modePaiement;
  set modePaiement(String? modePaiement) => _$this._modePaiement = modePaiement;

  int? _montantARemettreAuCoursierUnites;
  int? get montantARemettreAuCoursierUnites =>
      _$this._montantARemettreAuCoursierUnites;
  set montantARemettreAuCoursierUnites(int? montantARemettreAuCoursierUnites) =>
      _$this._montantARemettreAuCoursierUnites =
          montantARemettreAuCoursierUnites;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  String? _moyen;
  String? get moyen => _$this._moyen;
  set moyen(String? moyen) => _$this._moyen = moyen;

  int? _retenueVendeurUnites;
  int? get retenueVendeurUnites => _$this._retenueVendeurUnites;
  set retenueVendeurUnites(int? retenueVendeurUnites) =>
      _$this._retenueVendeurUnites = retenueVendeurUnites;

  int? _totalDuUnites;
  int? get totalDuUnites => _$this._totalDuUnites;
  set totalDuUnites(int? totalDuUnites) =>
      _$this._totalDuUnites = totalDuUnites;

  RecuCommandeBuilder() {
    RecuCommande._defaults(this);
  }

  RecuCommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _dejaRegle = $v.dejaRegle;
      _devise = $v.devise;
      _fraisLivraisonUnites = $v.fraisLivraisonUnites;
      _lignes = $v.lignes.toBuilder();
      _modePaiement = $v.modePaiement;
      _montantARemettreAuCoursierUnites = $v.montantARemettreAuCoursierUnites;
      _montantArticlesUnites = $v.montantArticlesUnites;
      _moyen = $v.moyen;
      _retenueVendeurUnites = $v.retenueVendeurUnites;
      _totalDuUnites = $v.totalDuUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RecuCommande other) {
    _$v = other as _$RecuCommande;
  }

  @override
  void update(void Function(RecuCommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RecuCommande build() => _build();

  _$RecuCommande _build() {
    _$RecuCommande _$result;
    try {
      _$result = _$v ??
          _$RecuCommande._(
            commandeId: BuiltValueNullFieldError.checkNotNull(
                commandeId, r'RecuCommande', 'commandeId'),
            dejaRegle: BuiltValueNullFieldError.checkNotNull(
                dejaRegle, r'RecuCommande', 'dejaRegle'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'RecuCommande', 'devise'),
            fraisLivraisonUnites: BuiltValueNullFieldError.checkNotNull(
                fraisLivraisonUnites, r'RecuCommande', 'fraisLivraisonUnites'),
            lignes: lignes.build(),
            modePaiement: BuiltValueNullFieldError.checkNotNull(
                modePaiement, r'RecuCommande', 'modePaiement'),
            montantARemettreAuCoursierUnites:
                BuiltValueNullFieldError.checkNotNull(
                    montantARemettreAuCoursierUnites,
                    r'RecuCommande',
                    'montantARemettreAuCoursierUnites'),
            montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
                montantArticlesUnites,
                r'RecuCommande',
                'montantArticlesUnites'),
            moyen: moyen,
            retenueVendeurUnites: BuiltValueNullFieldError.checkNotNull(
                retenueVendeurUnites, r'RecuCommande', 'retenueVendeurUnites'),
            totalDuUnites: BuiltValueNullFieldError.checkNotNull(
                totalDuUnites, r'RecuCommande', 'totalDuUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RecuCommande', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
