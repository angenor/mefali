// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'creance.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Creance extends Creance {
  @override
  final String commandeId;
  @override
  final DateTime creeLe;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String id;
  @override
  final int montantUnites;
  @override
  final String nature;
  @override
  final DateTime? regleLe;

  factory _$Creance([void Function(CreanceBuilder)? updates]) =>
      (CreanceBuilder()..update(updates))._build();

  _$Creance._(
      {required this.commandeId,
      required this.creeLe,
      required this.devise,
      required this.etat,
      required this.id,
      required this.montantUnites,
      required this.nature,
      this.regleLe})
      : super._();
  @override
  Creance rebuild(void Function(CreanceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CreanceBuilder toBuilder() => CreanceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Creance &&
        commandeId == other.commandeId &&
        creeLe == other.creeLe &&
        devise == other.devise &&
        etat == other.etat &&
        id == other.id &&
        montantUnites == other.montantUnites &&
        nature == other.nature &&
        regleLe == other.regleLe;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, nature.hashCode);
    _$hash = $jc(_$hash, regleLe.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Creance')
          ..add('commandeId', commandeId)
          ..add('creeLe', creeLe)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('id', id)
          ..add('montantUnites', montantUnites)
          ..add('nature', nature)
          ..add('regleLe', regleLe))
        .toString();
  }
}

class CreanceBuilder implements Builder<Creance, CreanceBuilder> {
  _$Creance? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  String? _nature;
  String? get nature => _$this._nature;
  set nature(String? nature) => _$this._nature = nature;

  DateTime? _regleLe;
  DateTime? get regleLe => _$this._regleLe;
  set regleLe(DateTime? regleLe) => _$this._regleLe = regleLe;

  CreanceBuilder() {
    Creance._defaults(this);
  }

  CreanceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _creeLe = $v.creeLe;
      _devise = $v.devise;
      _etat = $v.etat;
      _id = $v.id;
      _montantUnites = $v.montantUnites;
      _nature = $v.nature;
      _regleLe = $v.regleLe;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Creance other) {
    _$v = other as _$Creance;
  }

  @override
  void update(void Function(CreanceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Creance build() => _build();

  _$Creance _build() {
    final _$result = _$v ??
        _$Creance._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'Creance', 'commandeId'),
          creeLe: BuiltValueNullFieldError.checkNotNull(
              creeLe, r'Creance', 'creeLe'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'Creance', 'devise'),
          etat: BuiltValueNullFieldError.checkNotNull(etat, r'Creance', 'etat'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'Creance', 'id'),
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'Creance', 'montantUnites'),
          nature: BuiltValueNullFieldError.checkNotNull(
              nature, r'Creance', 'nature'),
          regleLe: regleLe,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
