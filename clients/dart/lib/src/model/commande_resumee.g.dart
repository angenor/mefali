// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'commande_resumee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CommandeResumee extends CommandeResumee {
  @override
  final DateTime creeLe;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final String etatCle;
  @override
  final String id;
  @override
  final int nbVendeurs;
  @override
  final int totalUnites;

  factory _$CommandeResumee([void Function(CommandeResumeeBuilder)? updates]) =>
      (CommandeResumeeBuilder()..update(updates))._build();

  _$CommandeResumee._(
      {required this.creeLe,
      required this.devise,
      required this.etat,
      required this.etatCle,
      required this.id,
      required this.nbVendeurs,
      required this.totalUnites})
      : super._();
  @override
  CommandeResumee rebuild(void Function(CommandeResumeeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CommandeResumeeBuilder toBuilder() => CommandeResumeeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CommandeResumee &&
        creeLe == other.creeLe &&
        devise == other.devise &&
        etat == other.etat &&
        etatCle == other.etatCle &&
        id == other.id &&
        nbVendeurs == other.nbVendeurs &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, creeLe.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, etatCle.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, nbVendeurs.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CommandeResumee')
          ..add('creeLe', creeLe)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('etatCle', etatCle)
          ..add('id', id)
          ..add('nbVendeurs', nbVendeurs)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class CommandeResumeeBuilder
    implements Builder<CommandeResumee, CommandeResumeeBuilder> {
  _$CommandeResumee? _$v;

  DateTime? _creeLe;
  DateTime? get creeLe => _$this._creeLe;
  set creeLe(DateTime? creeLe) => _$this._creeLe = creeLe;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _etatCle;
  String? get etatCle => _$this._etatCle;
  set etatCle(String? etatCle) => _$this._etatCle = etatCle;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _nbVendeurs;
  int? get nbVendeurs => _$this._nbVendeurs;
  set nbVendeurs(int? nbVendeurs) => _$this._nbVendeurs = nbVendeurs;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  CommandeResumeeBuilder() {
    CommandeResumee._defaults(this);
  }

  CommandeResumeeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _creeLe = $v.creeLe;
      _devise = $v.devise;
      _etat = $v.etat;
      _etatCle = $v.etatCle;
      _id = $v.id;
      _nbVendeurs = $v.nbVendeurs;
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CommandeResumee other) {
    _$v = other as _$CommandeResumee;
  }

  @override
  void update(void Function(CommandeResumeeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CommandeResumee build() => _build();

  _$CommandeResumee _build() {
    final _$result = _$v ??
        _$CommandeResumee._(
          creeLe: BuiltValueNullFieldError.checkNotNull(
              creeLe, r'CommandeResumee', 'creeLe'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'CommandeResumee', 'devise'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'CommandeResumee', 'etat'),
          etatCle: BuiltValueNullFieldError.checkNotNull(
              etatCle, r'CommandeResumee', 'etatCle'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'CommandeResumee', 'id'),
          nbVendeurs: BuiltValueNullFieldError.checkNotNull(
              nbVendeurs, r'CommandeResumee', 'nbVendeurs'),
          totalUnites: BuiltValueNullFieldError.checkNotNull(
              totalUnites, r'CommandeResumee', 'totalUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
