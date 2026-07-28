// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_disponibilite.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatDisponibilite extends EtatDisponibilite {
  @override
  final BuiltList<CapaciteCoursier> capacites;
  @override
  final bool dansLePool;
  @override
  final String devise;
  @override
  final bool enLigne;
  @override
  final String jour;
  @override
  final int? noteCentiemes;
  @override
  final String palierNoteCle;
  @override
  final int periodePositionS;
  @override
  final int? plafondDeclareUnites;
  @override
  final int plafondRetenuUnites;
  @override
  final String plafondSource;

  factory _$EtatDisponibilite(
          [void Function(EtatDisponibiliteBuilder)? updates]) =>
      (EtatDisponibiliteBuilder()..update(updates))._build();

  _$EtatDisponibilite._(
      {required this.capacites,
      required this.dansLePool,
      required this.devise,
      required this.enLigne,
      required this.jour,
      this.noteCentiemes,
      required this.palierNoteCle,
      required this.periodePositionS,
      this.plafondDeclareUnites,
      required this.plafondRetenuUnites,
      required this.plafondSource})
      : super._();
  @override
  EtatDisponibilite rebuild(void Function(EtatDisponibiliteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatDisponibiliteBuilder toBuilder() =>
      EtatDisponibiliteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatDisponibilite &&
        capacites == other.capacites &&
        dansLePool == other.dansLePool &&
        devise == other.devise &&
        enLigne == other.enLigne &&
        jour == other.jour &&
        noteCentiemes == other.noteCentiemes &&
        palierNoteCle == other.palierNoteCle &&
        periodePositionS == other.periodePositionS &&
        plafondDeclareUnites == other.plafondDeclareUnites &&
        plafondRetenuUnites == other.plafondRetenuUnites &&
        plafondSource == other.plafondSource;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, capacites.hashCode);
    _$hash = $jc(_$hash, dansLePool.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, enLigne.hashCode);
    _$hash = $jc(_$hash, jour.hashCode);
    _$hash = $jc(_$hash, noteCentiemes.hashCode);
    _$hash = $jc(_$hash, palierNoteCle.hashCode);
    _$hash = $jc(_$hash, periodePositionS.hashCode);
    _$hash = $jc(_$hash, plafondDeclareUnites.hashCode);
    _$hash = $jc(_$hash, plafondRetenuUnites.hashCode);
    _$hash = $jc(_$hash, plafondSource.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatDisponibilite')
          ..add('capacites', capacites)
          ..add('dansLePool', dansLePool)
          ..add('devise', devise)
          ..add('enLigne', enLigne)
          ..add('jour', jour)
          ..add('noteCentiemes', noteCentiemes)
          ..add('palierNoteCle', palierNoteCle)
          ..add('periodePositionS', periodePositionS)
          ..add('plafondDeclareUnites', plafondDeclareUnites)
          ..add('plafondRetenuUnites', plafondRetenuUnites)
          ..add('plafondSource', plafondSource))
        .toString();
  }
}

class EtatDisponibiliteBuilder
    implements Builder<EtatDisponibilite, EtatDisponibiliteBuilder> {
  _$EtatDisponibilite? _$v;

  ListBuilder<CapaciteCoursier>? _capacites;
  ListBuilder<CapaciteCoursier> get capacites =>
      _$this._capacites ??= ListBuilder<CapaciteCoursier>();
  set capacites(ListBuilder<CapaciteCoursier>? capacites) =>
      _$this._capacites = capacites;

  bool? _dansLePool;
  bool? get dansLePool => _$this._dansLePool;
  set dansLePool(bool? dansLePool) => _$this._dansLePool = dansLePool;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  bool? _enLigne;
  bool? get enLigne => _$this._enLigne;
  set enLigne(bool? enLigne) => _$this._enLigne = enLigne;

  String? _jour;
  String? get jour => _$this._jour;
  set jour(String? jour) => _$this._jour = jour;

  int? _noteCentiemes;
  int? get noteCentiemes => _$this._noteCentiemes;
  set noteCentiemes(int? noteCentiemes) =>
      _$this._noteCentiemes = noteCentiemes;

  String? _palierNoteCle;
  String? get palierNoteCle => _$this._palierNoteCle;
  set palierNoteCle(String? palierNoteCle) =>
      _$this._palierNoteCle = palierNoteCle;

  int? _periodePositionS;
  int? get periodePositionS => _$this._periodePositionS;
  set periodePositionS(int? periodePositionS) =>
      _$this._periodePositionS = periodePositionS;

  int? _plafondDeclareUnites;
  int? get plafondDeclareUnites => _$this._plafondDeclareUnites;
  set plafondDeclareUnites(int? plafondDeclareUnites) =>
      _$this._plafondDeclareUnites = plafondDeclareUnites;

  int? _plafondRetenuUnites;
  int? get plafondRetenuUnites => _$this._plafondRetenuUnites;
  set plafondRetenuUnites(int? plafondRetenuUnites) =>
      _$this._plafondRetenuUnites = plafondRetenuUnites;

  String? _plafondSource;
  String? get plafondSource => _$this._plafondSource;
  set plafondSource(String? plafondSource) =>
      _$this._plafondSource = plafondSource;

  EtatDisponibiliteBuilder() {
    EtatDisponibilite._defaults(this);
  }

  EtatDisponibiliteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _capacites = $v.capacites.toBuilder();
      _dansLePool = $v.dansLePool;
      _devise = $v.devise;
      _enLigne = $v.enLigne;
      _jour = $v.jour;
      _noteCentiemes = $v.noteCentiemes;
      _palierNoteCle = $v.palierNoteCle;
      _periodePositionS = $v.periodePositionS;
      _plafondDeclareUnites = $v.plafondDeclareUnites;
      _plafondRetenuUnites = $v.plafondRetenuUnites;
      _plafondSource = $v.plafondSource;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatDisponibilite other) {
    _$v = other as _$EtatDisponibilite;
  }

  @override
  void update(void Function(EtatDisponibiliteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatDisponibilite build() => _build();

  _$EtatDisponibilite _build() {
    _$EtatDisponibilite _$result;
    try {
      _$result = _$v ??
          _$EtatDisponibilite._(
            capacites: capacites.build(),
            dansLePool: BuiltValueNullFieldError.checkNotNull(
                dansLePool, r'EtatDisponibilite', 'dansLePool'),
            devise: BuiltValueNullFieldError.checkNotNull(
                devise, r'EtatDisponibilite', 'devise'),
            enLigne: BuiltValueNullFieldError.checkNotNull(
                enLigne, r'EtatDisponibilite', 'enLigne'),
            jour: BuiltValueNullFieldError.checkNotNull(
                jour, r'EtatDisponibilite', 'jour'),
            noteCentiemes: noteCentiemes,
            palierNoteCle: BuiltValueNullFieldError.checkNotNull(
                palierNoteCle, r'EtatDisponibilite', 'palierNoteCle'),
            periodePositionS: BuiltValueNullFieldError.checkNotNull(
                periodePositionS, r'EtatDisponibilite', 'periodePositionS'),
            plafondDeclareUnites: plafondDeclareUnites,
            plafondRetenuUnites: BuiltValueNullFieldError.checkNotNull(
                plafondRetenuUnites,
                r'EtatDisponibilite',
                'plafondRetenuUnites'),
            plafondSource: BuiltValueNullFieldError.checkNotNull(
                plafondSource, r'EtatDisponibilite', 'plafondSource'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'capacites';
        capacites.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EtatDisponibilite', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
