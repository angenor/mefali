// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devis_livraison.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DevisLivraison extends DevisLivraison {
  @override
  final ComposantesDevis composantes;
  @override
  final bool degraded;
  @override
  final String devise;
  @override
  final int distanceM;
  @override
  final int etaS;
  @override
  final int margeUnites;
  @override
  final BuiltList<int> ordreArrets;
  @override
  final int partCoursierUnites;
  @override
  final int prixClientUnites;

  factory _$DevisLivraison([void Function(DevisLivraisonBuilder)? updates]) =>
      (DevisLivraisonBuilder()..update(updates))._build();

  _$DevisLivraison._(
      {required this.composantes,
      required this.degraded,
      required this.devise,
      required this.distanceM,
      required this.etaS,
      required this.margeUnites,
      required this.ordreArrets,
      required this.partCoursierUnites,
      required this.prixClientUnites})
      : super._();
  @override
  DevisLivraison rebuild(void Function(DevisLivraisonBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DevisLivraisonBuilder toBuilder() => DevisLivraisonBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DevisLivraison &&
        composantes == other.composantes &&
        degraded == other.degraded &&
        devise == other.devise &&
        distanceM == other.distanceM &&
        etaS == other.etaS &&
        margeUnites == other.margeUnites &&
        ordreArrets == other.ordreArrets &&
        partCoursierUnites == other.partCoursierUnites &&
        prixClientUnites == other.prixClientUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, composantes.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, etaS.hashCode);
    _$hash = $jc(_$hash, margeUnites.hashCode);
    _$hash = $jc(_$hash, ordreArrets.hashCode);
    _$hash = $jc(_$hash, partCoursierUnites.hashCode);
    _$hash = $jc(_$hash, prixClientUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DevisLivraison')
          ..add('composantes', composantes)
          ..add('degraded', degraded)
          ..add('devise', devise)
          ..add('distanceM', distanceM)
          ..add('etaS', etaS)
          ..add('margeUnites', margeUnites)
          ..add('ordreArrets', ordreArrets)
          ..add('partCoursierUnites', partCoursierUnites)
          ..add('prixClientUnites', prixClientUnites))
        .toString();
  }
}

class DevisLivraisonBuilder
    implements Builder<DevisLivraison, DevisLivraisonBuilder> {
  _$DevisLivraison? _$v;

  ComposantesDevisBuilder? _composantes;
  ComposantesDevisBuilder get composantes =>
      _$this._composantes ??= ComposantesDevisBuilder();
  set composantes(ComposantesDevisBuilder? composantes) =>
      _$this._composantes = composantes;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  int? _etaS;
  int? get etaS => _$this._etaS;
  set etaS(int? etaS) => _$this._etaS = etaS;

  int? _margeUnites;
  int? get margeUnites => _$this._margeUnites;
  set margeUnites(int? margeUnites) => _$this._margeUnites = margeUnites;

  ListBuilder<int>? _ordreArrets;
  ListBuilder<int> get ordreArrets =>
      _$this._ordreArrets ??= ListBuilder<int>();
  set ordreArrets(ListBuilder<int>? ordreArrets) =>
      _$this._ordreArrets = ordreArrets;

  int? _partCoursierUnites;
  int? get partCoursierUnites => _$this._partCoursierUnites;
  set partCoursierUnites(int? partCoursierUnites) =>
      _$this._partCoursierUnites = partCoursierUnites;

  int? _prixClientUnites;
  int? get prixClientUnites => _$this._prixClientUnites;
  set prixClientUnites(int? prixClientUnites) =>
      _$this._prixClientUnites = prixClientUnites;

  DevisLivraisonBuilder() {
    DevisLivraison._defaults(this);
  }

  DevisLivraisonBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _composantes = $v.composantes.toBuilder();
      _degraded = $v.degraded;
      _devise = $v.devise;
      _distanceM = $v.distanceM;
      _etaS = $v.etaS;
      _margeUnites = $v.margeUnites;
      _ordreArrets = $v.ordreArrets.toBuilder();
      _partCoursierUnites = $v.partCoursierUnites;
      _prixClientUnites = $v.prixClientUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DevisLivraison other) {
    _$v = other as _$DevisLivraison;
  }

  @override
  void update(void Function(DevisLivraisonBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DevisLivraison build() => _build();

  _$DevisLivraison _build() {
    _$DevisLivraison _$result;
    try {
      _$result = _$v ??
          _$DevisLivraison._(
            composantes: composantes.build(),
            degraded: BuiltValueNullFieldError.checkNotNull(
                degraded, r'DevisLivraison', 'degraded'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'DevisLivraison', 'devise'),
            distanceM: BuiltValueNullFieldError.checkNotNull(
                distanceM, r'DevisLivraison', 'distanceM'),
            etaS: BuiltValueNullFieldError.checkNotNull(
                etaS, r'DevisLivraison', 'etaS'),
            margeUnites: BuiltValueNullFieldError.checkNotNull(
                margeUnites, r'DevisLivraison', 'margeUnites'),
            ordreArrets: ordreArrets.build(),
            partCoursierUnites: BuiltValueNullFieldError.checkNotNull(
                partCoursierUnites, r'DevisLivraison', 'partCoursierUnites'),
            prixClientUnites: BuiltValueNullFieldError.checkNotNull(
                prixClientUnites, r'DevisLivraison', 'prixClientUnites'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'composantes';
        composantes.build();

        _$failedField = 'ordreArrets';
        ordreArrets.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DevisLivraison', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
