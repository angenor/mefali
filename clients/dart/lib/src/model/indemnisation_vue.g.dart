// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indemnisation_vue.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IndemnisationVue extends IndemnisationVue {
  @override
  final String commandeId;
  @override
  final String commandeReference;
  @override
  final DateTime creeLe;
  @override
  final DateTime? decideLe;
  @override
  final String? decisionMotifCle;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String id;
  @override
  final String? litigeId;
  @override
  final int montantUnites;
  @override
  final String motifCle;

  factory _$IndemnisationVue(
          [void Function(IndemnisationVueBuilder)? updates]) =>
      (IndemnisationVueBuilder()..update(updates))._build();

  _$IndemnisationVue._(
      {required this.commandeId,
      required this.commandeReference,
      required this.creeLe,
      this.decideLe,
      this.decisionMotifCle,
      required this.devise,
      required this.etat,
      required this.id,
      this.litigeId,
      required this.montantUnites,
      required this.motifCle})
      : super._();
  @override
  IndemnisationVue rebuild(void Function(IndemnisationVueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IndemnisationVueBuilder toBuilder() =>
      IndemnisationVueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IndemnisationVue &&
        commandeId == other.commandeId &&
        commandeReference == other.commandeReference &&
        creeLe == other.creeLe &&
        decideLe == other.decideLe &&
        decisionMotifCle == other.decisionMotifCle &&
        devise == other.devise &&
        etat == other.etat &&
        id == other.id &&
        litigeId == other.litigeId &&
        montantUnites == other.montantUnites &&
        motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, commandeReference.hashCode);
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, decideLe.hashCode);
    _$hash = $jc(_$hash, decisionMotifCle.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, litigeId.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IndemnisationVue')
          ..add('commandeId', commandeId)
          ..add('commandeReference', commandeReference)
          ..add('creeLe', creeLe)
          ..add('decideLe', decideLe)
          ..add('decisionMotifCle', decisionMotifCle)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('id', id)
          ..add('litigeId', litigeId)
          ..add('montantUnites', montantUnites)
          ..add('motifCle', motifCle))
        .toString();
  }
}

class IndemnisationVueBuilder
    implements Builder<IndemnisationVue, IndemnisationVueBuilder> {
  _$IndemnisationVue? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _commandeReference;
  String? get commandeReference => _$this._commandeReference;
  set commandeReference(String? commandeReference) =>
      _$this._commandeReference = commandeReference;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  DateTime? _decideLe;
  DateTime? get decideLe => _$this._decideLe;
  set decideLe(DateTime? decideLe) => _$this._decideLe = decideLe;

  String? _decisionMotifCle;
  String? get decisionMotifCle => _$this._decisionMotifCle;
  set decisionMotifCle(String? decisionMotifCle) =>
      _$this._decisionMotifCle = decisionMotifCle;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _litigeId;
  String? get litigeId => _$this._litigeId;
  set litigeId(String? litigeId) => _$this._litigeId = litigeId;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  IndemnisationVueBuilder() {
    IndemnisationVue._defaults(this);
  }

  IndemnisationVueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _commandeReference = $v.commandeReference;
      _creeLe = $v.creeLe;
      _decideLe = $v.decideLe;
      _decisionMotifCle = $v.decisionMotifCle;
      _devise = $v.devise;
      _etat = $v.etat;
      _id = $v.id;
      _litigeId = $v.litigeId;
      _montantUnites = $v.montantUnites;
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IndemnisationVue other) {
    _$v = other as _$IndemnisationVue;
  }

  @override
  void update(void Function(IndemnisationVueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IndemnisationVue build() => _build();

  _$IndemnisationVue _build() {
    final _$result = _$v ??
        _$IndemnisationVue._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'IndemnisationVue', 'commandeId'),
          commandeReference: BuiltValueNullFieldError.checkNotNull(
              commandeReference, r'IndemnisationVue', 'commandeReference'),
          creeLe: BuiltValueNullFieldError.checkNotNull(
              creeLe, r'IndemnisationVue', 'creeLe'),
          decideLe: decideLe,
          decisionMotifCle: decisionMotifCle,
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'IndemnisationVue', 'devise'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'IndemnisationVue', 'etat'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'IndemnisationVue', 'id'),
          litigeId: litigeId,
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'IndemnisationVue', 'montantUnites'),
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'IndemnisationVue', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
