// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course_bloquee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CourseBloquee extends CourseBloquee {
  @override
  final String commandeId;
  @override
  final String? coursierId;
  @override
  final String livraisonId;
  @override
  final String motif;
  @override
  final int nbArretsCollectes;
  @override
  final bool repriseAutomatiquePossible;
  @override
  final int stagnationS;

  factory _$CourseBloquee([void Function(CourseBloqueeBuilder)? updates]) =>
      (CourseBloqueeBuilder()..update(updates))._build();

  _$CourseBloquee._(
      {required this.commandeId,
      this.coursierId,
      required this.livraisonId,
      required this.motif,
      required this.nbArretsCollectes,
      required this.repriseAutomatiquePossible,
      required this.stagnationS})
      : super._();
  @override
  CourseBloquee rebuild(void Function(CourseBloqueeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CourseBloqueeBuilder toBuilder() => CourseBloqueeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CourseBloquee &&
        commandeId == other.commandeId &&
        coursierId == other.coursierId &&
        livraisonId == other.livraisonId &&
        motif == other.motif &&
        nbArretsCollectes == other.nbArretsCollectes &&
        repriseAutomatiquePossible == other.repriseAutomatiquePossible &&
        stagnationS == other.stagnationS;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, coursierId.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, nbArretsCollectes.hashCode);
    _$hash = $jc(_$hash, repriseAutomatiquePossible.hashCode);
    _$hash = $jc(_$hash, stagnationS.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CourseBloquee')
          ..add('commandeId', commandeId)
          ..add('coursierId', coursierId)
          ..add('livraisonId', livraisonId)
          ..add('motif', motif)
          ..add('nbArretsCollectes', nbArretsCollectes)
          ..add('repriseAutomatiquePossible', repriseAutomatiquePossible)
          ..add('stagnationS', stagnationS))
        .toString();
  }
}

class CourseBloqueeBuilder
    implements Builder<CourseBloquee, CourseBloqueeBuilder> {
  _$CourseBloquee? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _coursierId;
  String? get coursierId => _$this._coursierId;
  set coursierId(String? coursierId) => _$this._coursierId = coursierId;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  int? _nbArretsCollectes;
  int? get nbArretsCollectes => _$this._nbArretsCollectes;
  set nbArretsCollectes(int? nbArretsCollectes) =>
      _$this._nbArretsCollectes = nbArretsCollectes;

  bool? _repriseAutomatiquePossible;
  bool? get repriseAutomatiquePossible => _$this._repriseAutomatiquePossible;
  set repriseAutomatiquePossible(bool? repriseAutomatiquePossible) =>
      _$this._repriseAutomatiquePossible = repriseAutomatiquePossible;

  int? _stagnationS;
  int? get stagnationS => _$this._stagnationS;
  set stagnationS(int? stagnationS) => _$this._stagnationS = stagnationS;

  CourseBloqueeBuilder() {
    CourseBloquee._defaults(this);
  }

  CourseBloqueeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _coursierId = $v.coursierId;
      _livraisonId = $v.livraisonId;
      _motif = $v.motif;
      _nbArretsCollectes = $v.nbArretsCollectes;
      _repriseAutomatiquePossible = $v.repriseAutomatiquePossible;
      _stagnationS = $v.stagnationS;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CourseBloquee other) {
    _$v = other as _$CourseBloquee;
  }

  @override
  void update(void Function(CourseBloqueeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CourseBloquee build() => _build();

  _$CourseBloquee _build() {
    final _$result = _$v ??
        _$CourseBloquee._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'CourseBloquee', 'commandeId'),
          coursierId: coursierId,
          livraisonId: BuiltValueNullFieldError.checkNotNull(
              livraisonId, r'CourseBloquee', 'livraisonId'),
          motif: BuiltValueNullFieldError.checkNotNull(
              motif, r'CourseBloquee', 'motif'),
          nbArretsCollectes: BuiltValueNullFieldError.checkNotNull(
              nbArretsCollectes, r'CourseBloquee', 'nbArretsCollectes'),
          repriseAutomatiquePossible: BuiltValueNullFieldError.checkNotNull(
              repriseAutomatiquePossible,
              r'CourseBloquee',
              'repriseAutomatiquePossible'),
          stagnationS: BuiltValueNullFieldError.checkNotNull(
              stagnationS, r'CourseBloquee', 'stagnationS'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
