// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'substitution_suivi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SubstitutionSuivi extends SubstitutionSuivi {
  @override
  final int ancienPrixUnites;
  @override
  final String articleNom;
  @override
  final String id;
  @override
  final String ligneId;
  @override
  final String photoCle;
  @override
  final int prixUnites;
  @override
  final int resteS;

  factory _$SubstitutionSuivi(
          [void Function(SubstitutionSuiviBuilder)? updates]) =>
      (SubstitutionSuiviBuilder()..update(updates))._build();

  _$SubstitutionSuivi._(
      {required this.ancienPrixUnites,
      required this.articleNom,
      required this.id,
      required this.ligneId,
      required this.photoCle,
      required this.prixUnites,
      required this.resteS})
      : super._();
  @override
  SubstitutionSuivi rebuild(void Function(SubstitutionSuiviBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SubstitutionSuiviBuilder toBuilder() =>
      SubstitutionSuiviBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SubstitutionSuivi &&
        ancienPrixUnites == other.ancienPrixUnites &&
        articleNom == other.articleNom &&
        id == other.id &&
        ligneId == other.ligneId &&
        photoCle == other.photoCle &&
        prixUnites == other.prixUnites &&
        resteS == other.resteS;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ancienPrixUnites.hashCode);
    _$hash = $jc(_$hash, articleNom.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, ligneId.hashCode);
    _$hash = $jc(_$hash, photoCle.hashCode);
    _$hash = $jc(_$hash, prixUnites.hashCode);
    _$hash = $jc(_$hash, resteS.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SubstitutionSuivi')
          ..add('ancienPrixUnites', ancienPrixUnites)
          ..add('articleNom', articleNom)
          ..add('id', id)
          ..add('ligneId', ligneId)
          ..add('photoCle', photoCle)
          ..add('prixUnites', prixUnites)
          ..add('resteS', resteS))
        .toString();
  }
}

class SubstitutionSuiviBuilder
    implements Builder<SubstitutionSuivi, SubstitutionSuiviBuilder> {
  _$SubstitutionSuivi? _$v;

  int? _ancienPrixUnites;
  int? get ancienPrixUnites => _$this._ancienPrixUnites;
  set ancienPrixUnites(int? ancienPrixUnites) =>
      _$this._ancienPrixUnites = ancienPrixUnites;

  String? _articleNom;
  String? get articleNom => _$this._articleNom;
  set articleNom(String? articleNom) => _$this._articleNom = articleNom;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _ligneId;
  String? get ligneId => _$this._ligneId;
  set ligneId(String? ligneId) => _$this._ligneId = ligneId;

  String? _photoCle;
  String? get photoCle => _$this._photoCle;
  set photoCle(String? photoCle) => _$this._photoCle = photoCle;

  int? _prixUnites;
  int? get prixUnites => _$this._prixUnites;
  set prixUnites(int? prixUnites) => _$this._prixUnites = prixUnites;

  int? _resteS;
  int? get resteS => _$this._resteS;
  set resteS(int? resteS) => _$this._resteS = resteS;

  SubstitutionSuiviBuilder() {
    SubstitutionSuivi._defaults(this);
  }

  SubstitutionSuiviBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ancienPrixUnites = $v.ancienPrixUnites;
      _articleNom = $v.articleNom;
      _id = $v.id;
      _ligneId = $v.ligneId;
      _photoCle = $v.photoCle;
      _prixUnites = $v.prixUnites;
      _resteS = $v.resteS;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SubstitutionSuivi other) {
    _$v = other as _$SubstitutionSuivi;
  }

  @override
  void update(void Function(SubstitutionSuiviBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SubstitutionSuivi build() => _build();

  _$SubstitutionSuivi _build() {
    final _$result = _$v ??
        _$SubstitutionSuivi._(
          ancienPrixUnites: BuiltValueNullFieldError.checkNotNull(
              ancienPrixUnites, r'SubstitutionSuivi', 'ancienPrixUnites'),
          articleNom: BuiltValueNullFieldError.checkNotNull(
              articleNom, r'SubstitutionSuivi', 'articleNom'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SubstitutionSuivi', 'id'),
          ligneId: BuiltValueNullFieldError.checkNotNull(
              ligneId, r'SubstitutionSuivi', 'ligneId'),
          photoCle: BuiltValueNullFieldError.checkNotNull(
              photoCle, r'SubstitutionSuivi', 'photoCle'),
          prixUnites: BuiltValueNullFieldError.checkNotNull(
              prixUnites, r'SubstitutionSuivi', 'prixUnites'),
          resteS: BuiltValueNullFieldError.checkNotNull(
              resteS, r'SubstitutionSuivi', 'resteS'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
