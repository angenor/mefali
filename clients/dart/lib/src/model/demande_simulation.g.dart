// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_simulation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeSimulation extends DemandeSimulation {
  @override
  final BuiltList<Attente>? attentes;
  @override
  final String? categorieSlug;
  @override
  final Point destination;
  @override
  final DateTime instant;
  @override
  final bool monoVendeur;
  @override
  final int? montantPanier;
  @override
  final int nbArticles;
  @override
  final OffreLivraisonVendeur? offreLivraisonVendeur;
  @override
  final String transportSlug;
  @override
  final BuiltList<Point> vendeurs;

  factory _$DemandeSimulation(
          [void Function(DemandeSimulationBuilder)? updates]) =>
      (DemandeSimulationBuilder()..update(updates))._build();

  _$DemandeSimulation._(
      {this.attentes,
      this.categorieSlug,
      required this.destination,
      required this.instant,
      required this.monoVendeur,
      this.montantPanier,
      required this.nbArticles,
      this.offreLivraisonVendeur,
      required this.transportSlug,
      required this.vendeurs})
      : super._();
  @override
  DemandeSimulation rebuild(void Function(DemandeSimulationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeSimulationBuilder toBuilder() =>
      DemandeSimulationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeSimulation &&
        attentes == other.attentes &&
        categorieSlug == other.categorieSlug &&
        destination == other.destination &&
        instant == other.instant &&
        monoVendeur == other.monoVendeur &&
        montantPanier == other.montantPanier &&
        nbArticles == other.nbArticles &&
        offreLivraisonVendeur == other.offreLivraisonVendeur &&
        transportSlug == other.transportSlug &&
        vendeurs == other.vendeurs;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, attentes.hashCode);
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, destination.hashCode);
    _$hash = $jc(_$hash, instant.hashCode);
    _$hash = $jc(_$hash, monoVendeur.hashCode);
    _$hash = $jc(_$hash, montantPanier.hashCode);
    _$hash = $jc(_$hash, nbArticles.hashCode);
    _$hash = $jc(_$hash, offreLivraisonVendeur.hashCode);
    _$hash = $jc(_$hash, transportSlug.hashCode);
    _$hash = $jc(_$hash, vendeurs.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeSimulation')
          ..add('attentes', attentes)
          ..add('categorieSlug', categorieSlug)
          ..add('destination', destination)
          ..add('instant', instant)
          ..add('monoVendeur', monoVendeur)
          ..add('montantPanier', montantPanier)
          ..add('nbArticles', nbArticles)
          ..add('offreLivraisonVendeur', offreLivraisonVendeur)
          ..add('transportSlug', transportSlug)
          ..add('vendeurs', vendeurs))
        .toString();
  }
}

class DemandeSimulationBuilder
    implements Builder<DemandeSimulation, DemandeSimulationBuilder> {
  _$DemandeSimulation? _$v;

  ListBuilder<Attente>? _attentes;
  ListBuilder<Attente> get attentes =>
      _$this._attentes ??= ListBuilder<Attente>();
  set attentes(ListBuilder<Attente>? attentes) => _$this._attentes = attentes;

  String? _categorieSlug;
  String? get categorieSlug => _$this._categorieSlug;
  set categorieSlug(String? categorieSlug) =>
      _$this._categorieSlug = categorieSlug;

  PointBuilder? _destination;
  PointBuilder get destination => _$this._destination ??= PointBuilder();
  set destination(PointBuilder? destination) =>
      _$this._destination = destination;

  DateTime? _instant;
  DateTime? get instant => _$this._instant;
  set instant(DateTime? instant) => _$this._instant = instant;

  bool? _monoVendeur;
  bool? get monoVendeur => _$this._monoVendeur;
  set monoVendeur(bool? monoVendeur) => _$this._monoVendeur = monoVendeur;

  int? _montantPanier;
  int? get montantPanier => _$this._montantPanier;
  set montantPanier(int? montantPanier) =>
      _$this._montantPanier = montantPanier;

  int? _nbArticles;
  int? get nbArticles => _$this._nbArticles;
  set nbArticles(int? nbArticles) => _$this._nbArticles = nbArticles;

  OffreLivraisonVendeurBuilder? _offreLivraisonVendeur;
  OffreLivraisonVendeurBuilder get offreLivraisonVendeur =>
      _$this._offreLivraisonVendeur ??= OffreLivraisonVendeurBuilder();
  set offreLivraisonVendeur(
          OffreLivraisonVendeurBuilder? offreLivraisonVendeur) =>
      _$this._offreLivraisonVendeur = offreLivraisonVendeur;

  String? _transportSlug;
  String? get transportSlug => _$this._transportSlug;
  set transportSlug(String? transportSlug) =>
      _$this._transportSlug = transportSlug;

  ListBuilder<Point>? _vendeurs;
  ListBuilder<Point> get vendeurs => _$this._vendeurs ??= ListBuilder<Point>();
  set vendeurs(ListBuilder<Point>? vendeurs) => _$this._vendeurs = vendeurs;

  DemandeSimulationBuilder() {
    DemandeSimulation._defaults(this);
  }

  DemandeSimulationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _attentes = $v.attentes?.toBuilder();
      _categorieSlug = $v.categorieSlug;
      _destination = $v.destination.toBuilder();
      _instant = $v.instant;
      _monoVendeur = $v.monoVendeur;
      _montantPanier = $v.montantPanier;
      _nbArticles = $v.nbArticles;
      _offreLivraisonVendeur = $v.offreLivraisonVendeur?.toBuilder();
      _transportSlug = $v.transportSlug;
      _vendeurs = $v.vendeurs.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeSimulation other) {
    _$v = other as _$DemandeSimulation;
  }

  @override
  void update(void Function(DemandeSimulationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeSimulation build() => _build();

  _$DemandeSimulation _build() {
    _$DemandeSimulation _$result;
    try {
      _$result = _$v ??
          _$DemandeSimulation._(
            attentes: _attentes?.build(),
            categorieSlug: categorieSlug,
            destination: destination.build(),
            instant: BuiltValueNullFieldError.checkNotNull(
                instant, r'DemandeSimulation', 'instant'),
            monoVendeur: BuiltValueNullFieldError.checkNotNull(
                monoVendeur, r'DemandeSimulation', 'monoVendeur'),
            montantPanier: montantPanier,
            nbArticles: BuiltValueNullFieldError.checkNotNull(
                nbArticles, r'DemandeSimulation', 'nbArticles'),
            offreLivraisonVendeur: _offreLivraisonVendeur?.build(),
            transportSlug: BuiltValueNullFieldError.checkNotNull(
                transportSlug, r'DemandeSimulation', 'transportSlug'),
            vendeurs: vendeurs.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'attentes';
        _attentes?.build();

        _$failedField = 'destination';
        destination.build();

        _$failedField = 'offreLivraisonVendeur';
        _offreLivraisonVendeur?.build();

        _$failedField = 'vendeurs';
        vendeurs.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DemandeSimulation', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
