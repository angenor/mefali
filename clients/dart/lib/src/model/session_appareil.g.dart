// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_appareil.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionAppareil extends SessionAppareil {
  @override
  final String appareilNom;
  @override
  final PlateformeDto appareilPlateforme;
  @override
  final bool courante;
  @override
  final DateTime creeLe;
  @override
  final DateTime derniereActiviteLe;
  @override
  final String id;

  factory _$SessionAppareil([void Function(SessionAppareilBuilder)? updates]) =>
      (SessionAppareilBuilder()..update(updates))._build();

  _$SessionAppareil._(
      {required this.appareilNom,
      required this.appareilPlateforme,
      required this.courante,
      required this.creeLe,
      required this.derniereActiviteLe,
      required this.id})
      : super._();
  @override
  SessionAppareil rebuild(void Function(SessionAppareilBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionAppareilBuilder toBuilder() => SessionAppareilBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionAppareil &&
        appareilNom == other.appareilNom &&
        appareilPlateforme == other.appareilPlateforme &&
        courante == other.courante &&
        creeLe == other.creeLe &&
        derniereActiviteLe == other.derniereActiviteLe &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appareilNom.hashCode);
    _$hash = $jc(_$hash, appareilPlateforme.hashCode);
    _$hash = $jc(_$hash, courante.hashCode);
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, derniereActiviteLe.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionAppareil')
          ..add('appareilNom', appareilNom)
          ..add('appareilPlateforme', appareilPlateforme)
          ..add('courante', courante)
          ..add('creeLe', creeLe)
          ..add('derniereActiviteLe', derniereActiviteLe)
          ..add('id', id))
        .toString();
  }
}

class SessionAppareilBuilder
    implements Builder<SessionAppareil, SessionAppareilBuilder> {
  _$SessionAppareil? _$v;

  String? _appareilNom;
  String? get appareilNom => _$this._appareilNom;
  set appareilNom(String? appareilNom) => _$this._appareilNom = appareilNom;

  PlateformeDto? _appareilPlateforme;
  PlateformeDto? get appareilPlateforme => _$this._appareilPlateforme;
  set appareilPlateforme(PlateformeDto? appareilPlateforme) =>
      _$this._appareilPlateforme = appareilPlateforme;

  bool? _courante;
  bool? get courante => _$this._courante;
  set courante(bool? courante) => _$this._courante = courante;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  DateTime? _derniereActiviteLe;
  DateTime? get derniereActiviteLe => _$this._derniereActiviteLe;
  set derniereActiviteLe(DateTime? derniereActiviteLe) =>
      _$this._derniereActiviteLe = derniereActiviteLe;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  SessionAppareilBuilder() {
    SessionAppareil._defaults(this);
  }

  SessionAppareilBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appareilNom = $v.appareilNom;
      _appareilPlateforme = $v.appareilPlateforme;
      _courante = $v.courante;
      _creeLe = $v.creeLe;
      _derniereActiviteLe = $v.derniereActiviteLe;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionAppareil other) {
    _$v = other as _$SessionAppareil;
  }

  @override
  void update(void Function(SessionAppareilBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionAppareil build() => _build();

  _$SessionAppareil _build() {
    final _$result = _$v ??
        _$SessionAppareil._(
          appareilNom: BuiltValueNullFieldError.checkNotNull(
              appareilNom, r'SessionAppareil', 'appareilNom'),
          appareilPlateforme: BuiltValueNullFieldError.checkNotNull(
              appareilPlateforme, r'SessionAppareil', 'appareilPlateforme'),
          courante: BuiltValueNullFieldError.checkNotNull(
              courante, r'SessionAppareil', 'courante'),
          creeLe: BuiltValueNullFieldError.checkNotNull(
              creeLe, r'SessionAppareil', 'creeLe'),
          derniereActiviteLe: BuiltValueNullFieldError.checkNotNull(
              derniereActiviteLe, r'SessionAppareil', 'derniereActiviteLe'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'SessionAppareil', 'id'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
