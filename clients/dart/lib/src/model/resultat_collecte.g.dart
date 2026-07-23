// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_collecte.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatCollecte extends ResultatCollecte {
  @override
  final String arretStatut;
  @override
  final bool enLivraison;
  @override
  final String livraisonEtat;
  @override
  final int nbArrets;
  @override
  final int nbCollectes;

  factory _$ResultatCollecte(
          [void Function(ResultatCollecteBuilder)? updates]) =>
      (ResultatCollecteBuilder()..update(updates))._build();

  _$ResultatCollecte._(
      {required this.arretStatut,
      required this.enLivraison,
      required this.livraisonEtat,
      required this.nbArrets,
      required this.nbCollectes})
      : super._();
  @override
  ResultatCollecte rebuild(void Function(ResultatCollecteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatCollecteBuilder toBuilder() =>
      ResultatCollecteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatCollecte &&
        arretStatut == other.arretStatut &&
        enLivraison == other.enLivraison &&
        livraisonEtat == other.livraisonEtat &&
        nbArrets == other.nbArrets &&
        nbCollectes == other.nbCollectes;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretStatut.hashCode);
    _$hash = $jc(_$hash, enLivraison.hashCode);
    _$hash = $jc(_$hash, livraisonEtat.hashCode);
    _$hash = $jc(_$hash, nbArrets.hashCode);
    _$hash = $jc(_$hash, nbCollectes.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatCollecte')
          ..add('arretStatut', arretStatut)
          ..add('enLivraison', enLivraison)
          ..add('livraisonEtat', livraisonEtat)
          ..add('nbArrets', nbArrets)
          ..add('nbCollectes', nbCollectes))
        .toString();
  }
}

class ResultatCollecteBuilder
    implements Builder<ResultatCollecte, ResultatCollecteBuilder> {
  _$ResultatCollecte? _$v;

  String? _arretStatut;
  String? get arretStatut => _$this._arretStatut;
  set arretStatut(String? arretStatut) => _$this._arretStatut = arretStatut;

  bool? _enLivraison;
  bool? get enLivraison => _$this._enLivraison;
  set enLivraison(bool? enLivraison) => _$this._enLivraison = enLivraison;

  String? _livraisonEtat;
  String? get livraisonEtat => _$this._livraisonEtat;
  set livraisonEtat(String? livraisonEtat) =>
      _$this._livraisonEtat = livraisonEtat;

  int? _nbArrets;
  int? get nbArrets => _$this._nbArrets;
  set nbArrets(int? nbArrets) => _$this._nbArrets = nbArrets;

  int? _nbCollectes;
  int? get nbCollectes => _$this._nbCollectes;
  set nbCollectes(int? nbCollectes) => _$this._nbCollectes = nbCollectes;

  ResultatCollecteBuilder() {
    ResultatCollecte._defaults(this);
  }

  ResultatCollecteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretStatut = $v.arretStatut;
      _enLivraison = $v.enLivraison;
      _livraisonEtat = $v.livraisonEtat;
      _nbArrets = $v.nbArrets;
      _nbCollectes = $v.nbCollectes;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatCollecte other) {
    _$v = other as _$ResultatCollecte;
  }

  @override
  void update(void Function(ResultatCollecteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatCollecte build() => _build();

  _$ResultatCollecte _build() {
    final _$result = _$v ??
        _$ResultatCollecte._(
          arretStatut: BuiltValueNullFieldError.checkNotNull(
              arretStatut, r'ResultatCollecte', 'arretStatut'),
          enLivraison: BuiltValueNullFieldError.checkNotNull(
              enLivraison, r'ResultatCollecte', 'enLivraison'),
          livraisonEtat: BuiltValueNullFieldError.checkNotNull(
              livraisonEtat, r'ResultatCollecte', 'livraisonEtat'),
          nbArrets: BuiltValueNullFieldError.checkNotNull(
              nbArrets, r'ResultatCollecte', 'nbArrets'),
          nbCollectes: BuiltValueNullFieldError.checkNotNull(
              nbCollectes, r'ResultatCollecte', 'nbCollectes'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
