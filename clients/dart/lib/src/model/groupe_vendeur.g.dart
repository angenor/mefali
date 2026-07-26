// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'groupe_vendeur.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GroupeVendeur extends GroupeVendeur {
  @override
  final BuiltList<LigneDevis> lignes;
  @override
  final int nbArticles;
  @override
  final String nom;
  @override
  final String prestataireId;
  @override
  final int sousTotalUnites;

  factory _$GroupeVendeur([void Function(GroupeVendeurBuilder)? updates]) =>
      (GroupeVendeurBuilder()..update(updates))._build();

  _$GroupeVendeur._(
      {required this.lignes,
      required this.nbArticles,
      required this.nom,
      required this.prestataireId,
      required this.sousTotalUnites})
      : super._();
  @override
  GroupeVendeur rebuild(void Function(GroupeVendeurBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GroupeVendeurBuilder toBuilder() => GroupeVendeurBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GroupeVendeur &&
        lignes == other.lignes &&
        nbArticles == other.nbArticles &&
        nom == other.nom &&
        prestataireId == other.prestataireId &&
        sousTotalUnites == other.sousTotalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, nbArticles.hashCode);
    _$hash = $jc(_$hash, nom.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, sousTotalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GroupeVendeur')
          ..add('lignes', lignes)
          ..add('nbArticles', nbArticles)
          ..add('nom', nom)
          ..add('prestataireId', prestataireId)
          ..add('sousTotalUnites', sousTotalUnites))
        .toString();
  }
}

class GroupeVendeurBuilder
    implements Builder<GroupeVendeur, GroupeVendeurBuilder> {
  _$GroupeVendeur? _$v;

  ListBuilder<LigneDevis>? _lignes;
  ListBuilder<LigneDevis> get lignes =>
      _$this._lignes ??= ListBuilder<LigneDevis>();
  set lignes(ListBuilder<LigneDevis>? lignes) => _$this._lignes = lignes;

  int? _nbArticles;
  int? get nbArticles => _$this._nbArticles;
  set nbArticles(int? nbArticles) => _$this._nbArticles = nbArticles;

  String? _nom;
  String? get nom => _$this._nom;
  set nom(String? nom) => _$this._nom = nom;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  int? _sousTotalUnites;
  int? get sousTotalUnites => _$this._sousTotalUnites;
  set sousTotalUnites(int? sousTotalUnites) =>
      _$this._sousTotalUnites = sousTotalUnites;

  GroupeVendeurBuilder() {
    GroupeVendeur._defaults(this);
  }

  GroupeVendeurBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _lignes = $v.lignes.toBuilder();
      _nbArticles = $v.nbArticles;
      _nom = $v.nom;
      _prestataireId = $v.prestataireId;
      _sousTotalUnites = $v.sousTotalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GroupeVendeur other) {
    _$v = other as _$GroupeVendeur;
  }

  @override
  void update(void Function(GroupeVendeurBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GroupeVendeur build() => _build();

  _$GroupeVendeur _build() {
    _$GroupeVendeur _$result;
    try {
      _$result = _$v ??
          _$GroupeVendeur._(
            lignes: lignes.build(),
            nbArticles: BuiltValueNullFieldError.checkNotNull(
                nbArticles, r'GroupeVendeur', 'nbArticles'),
            nom: BuiltValueNullFieldError.checkNotNull(
                nom, r'GroupeVendeur', 'nom'),
            prestataireId: BuiltValueNullFieldError.checkNotNull(
                prestataireId, r'GroupeVendeur', 'prestataireId'),
            sousTotalUnites: BuiltValueNullFieldError.checkNotNull(
                sousTotalUnites, r'GroupeVendeur', 'sousTotalUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'GroupeVendeur', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
