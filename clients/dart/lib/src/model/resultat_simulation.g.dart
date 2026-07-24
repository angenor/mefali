// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_simulation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatSimulation extends ResultatSimulation {
  @override
  final Composantes composantes;
  @override
  final Devis devis;
  @override
  final DrapeauxZone drapeaux;
  @override
  final bool effortNonFacture;
  @override
  final ItineraireSimule itineraire;
  @override
  final RegleRetenue regleRetenue;

  factory _$ResultatSimulation(
          [void Function(ResultatSimulationBuilder)? updates]) =>
      (ResultatSimulationBuilder()..update(updates))._build();

  _$ResultatSimulation._(
      {required this.composantes,
      required this.devis,
      required this.drapeaux,
      required this.effortNonFacture,
      required this.itineraire,
      required this.regleRetenue})
      : super._();
  @override
  ResultatSimulation rebuild(
          void Function(ResultatSimulationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatSimulationBuilder toBuilder() =>
      ResultatSimulationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatSimulation &&
        composantes == other.composantes &&
        devis == other.devis &&
        drapeaux == other.drapeaux &&
        effortNonFacture == other.effortNonFacture &&
        itineraire == other.itineraire &&
        regleRetenue == other.regleRetenue;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, composantes.hashCode);
    _$hash = $jc(_$hash, devis.hashCode);
    _$hash = $jc(_$hash, drapeaux.hashCode);
    _$hash = $jc(_$hash, effortNonFacture.hashCode);
    _$hash = $jc(_$hash, itineraire.hashCode);
    _$hash = $jc(_$hash, regleRetenue.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatSimulation')
          ..add('composantes', composantes)
          ..add('devis', devis)
          ..add('drapeaux', drapeaux)
          ..add('effortNonFacture', effortNonFacture)
          ..add('itineraire', itineraire)
          ..add('regleRetenue', regleRetenue))
        .toString();
  }
}

class ResultatSimulationBuilder
    implements Builder<ResultatSimulation, ResultatSimulationBuilder> {
  _$ResultatSimulation? _$v;

  ComposantesBuilder? _composantes;
  ComposantesBuilder get composantes =>
      _$this._composantes ??= ComposantesBuilder();
  set composantes(ComposantesBuilder? composantes) =>
      _$this._composantes = composantes;

  DevisBuilder? _devis;
  DevisBuilder get devis => _$this._devis ??= DevisBuilder();
  set devis(DevisBuilder? devis) => _$this._devis = devis;

  DrapeauxZoneBuilder? _drapeaux;
  DrapeauxZoneBuilder get drapeaux =>
      _$this._drapeaux ??= DrapeauxZoneBuilder();
  set drapeaux(DrapeauxZoneBuilder? drapeaux) => _$this._drapeaux = drapeaux;

  bool? _effortNonFacture;
  bool? get effortNonFacture => _$this._effortNonFacture;
  set effortNonFacture(bool? effortNonFacture) =>
      _$this._effortNonFacture = effortNonFacture;

  ItineraireSimuleBuilder? _itineraire;
  ItineraireSimuleBuilder get itineraire =>
      _$this._itineraire ??= ItineraireSimuleBuilder();
  set itineraire(ItineraireSimuleBuilder? itineraire) =>
      _$this._itineraire = itineraire;

  RegleRetenueBuilder? _regleRetenue;
  RegleRetenueBuilder get regleRetenue =>
      _$this._regleRetenue ??= RegleRetenueBuilder();
  set regleRetenue(RegleRetenueBuilder? regleRetenue) =>
      _$this._regleRetenue = regleRetenue;

  ResultatSimulationBuilder() {
    ResultatSimulation._defaults(this);
  }

  ResultatSimulationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _composantes = $v.composantes.toBuilder();
      _devis = $v.devis.toBuilder();
      _drapeaux = $v.drapeaux.toBuilder();
      _effortNonFacture = $v.effortNonFacture;
      _itineraire = $v.itineraire.toBuilder();
      _regleRetenue = $v.regleRetenue.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatSimulation other) {
    _$v = other as _$ResultatSimulation;
  }

  @override
  void update(void Function(ResultatSimulationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatSimulation build() => _build();

  _$ResultatSimulation _build() {
    _$ResultatSimulation _$result;
    try {
      _$result = _$v ??
          _$ResultatSimulation._(
            composantes: composantes.build(),
            devis: devis.build(),
            drapeaux: drapeaux.build(),
            effortNonFacture: BuiltValueNullFieldError.checkNotNull(
                effortNonFacture, r'ResultatSimulation', 'effortNonFacture'),
            itineraire: itineraire.build(),
            regleRetenue: regleRetenue.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'composantes';
        composantes.build();
        _$failedField = 'devis';
        devis.build();
        _$failedField = 'drapeaux';
        drapeaux.build();

        _$failedField = 'itineraire';
        itineraire.build();
        _$failedField = 'regleRetenue';
        regleRetenue.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ResultatSimulation', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
