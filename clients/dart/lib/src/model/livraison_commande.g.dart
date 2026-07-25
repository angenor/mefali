// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'livraison_commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LivraisonCommande extends LivraisonCommande {
  @override
  final DevisLivraison devis;
  @override
  final String etat;
  @override
  final String id;
  @override
  final int nbArrets;

  factory _$LivraisonCommande(
          [void Function(LivraisonCommandeBuilder)? updates]) =>
      (LivraisonCommandeBuilder()..update(updates))._build();

  _$LivraisonCommande._(
      {required this.devis,
      required this.etat,
      required this.id,
      required this.nbArrets})
      : super._();
  @override
  LivraisonCommande rebuild(void Function(LivraisonCommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LivraisonCommandeBuilder toBuilder() =>
      LivraisonCommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LivraisonCommande &&
        devis == other.devis &&
        etat == other.etat &&
        id == other.id &&
        nbArrets == other.nbArrets;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, devis.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nbArrets.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LivraisonCommande')
          ..add('devis', devis)
          ..add('etat', etat)
          ..add('id', id)
          ..add('nbArrets', nbArrets))
        .toString();
  }
}

class LivraisonCommandeBuilder
    implements Builder<LivraisonCommande, LivraisonCommandeBuilder> {
  _$LivraisonCommande? _$v;

  DevisLivraisonBuilder? _devis;
  DevisLivraisonBuilder get devis => _$this._devis ??= DevisLivraisonBuilder();
  set devis(DevisLivraisonBuilder? devis) => _$this._devis = devis;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _nbArrets;
  int? get nbArrets => _$this._nbArrets;
  set nbArrets(int? nbArrets) => _$this._nbArrets = nbArrets;

  LivraisonCommandeBuilder() {
    LivraisonCommande._defaults(this);
  }

  LivraisonCommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _devis = $v.devis.toBuilder();
      _etat = $v.etat;
      _id = $v.id;
      _nbArrets = $v.nbArrets;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LivraisonCommande other) {
    _$v = other as _$LivraisonCommande;
  }

  @override
  void update(void Function(LivraisonCommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LivraisonCommande build() => _build();

  _$LivraisonCommande _build() {
    _$LivraisonCommande _$result;
    try {
      _$result = _$v ??
          _$LivraisonCommande._(
            devis: devis.build(),
            etat: BuiltValueNullFieldError.checkNotNull(
                etat, r'LivraisonCommande', 'etat'),
            id: BuiltValueNullFieldError.checkNotNull(
                id, r'LivraisonCommande', 'id'),
            nbArrets: BuiltValueNullFieldError.checkNotNull(
                nbArrets, r'LivraisonCommande', 'nbArrets'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'devis';
        devis.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'LivraisonCommande', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
