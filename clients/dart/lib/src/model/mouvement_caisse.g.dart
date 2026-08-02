// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mouvement_caisse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$MouvementCaisse extends MouvementCaisse {
  @override
  final String? commandeId;
  @override
  final bool entree;
  @override
  final DateTime heure;
  @override
  final String id;
  @override
  final int montantUnites;
  @override
  final String? reference;
  @override
  final String typeEcriture;

  factory _$MouvementCaisse([void Function(MouvementCaisseBuilder)? updates]) =>
      (MouvementCaisseBuilder()..update(updates))._build();

  _$MouvementCaisse._(
      {this.commandeId,
      required this.entree,
      required this.heure,
      required this.id,
      required this.montantUnites,
      this.reference,
      required this.typeEcriture})
      : super._();
  @override
  MouvementCaisse rebuild(void Function(MouvementCaisseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  MouvementCaisseBuilder toBuilder() => MouvementCaisseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is MouvementCaisse &&
        commandeId == other.commandeId &&
        entree == other.entree &&
        heure == other.heure &&
        id == other.id &&
        montantUnites == other.montantUnites &&
        reference == other.reference &&
        typeEcriture == other.typeEcriture;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, entree.hashCode);
    _$hash = $jc(_$hash, heure.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, reference.hashCode);
    _$hash = $jc(_$hash, typeEcriture.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'MouvementCaisse')
          ..add('commandeId', commandeId)
          ..add('entree', entree)
          ..add('heure', heure)
          ..add('id', id)
          ..add('montantUnites', montantUnites)
          ..add('reference', reference)
          ..add('typeEcriture', typeEcriture))
        .toString();
  }
}

class MouvementCaisseBuilder
    implements Builder<MouvementCaisse, MouvementCaisseBuilder> {
  _$MouvementCaisse? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _entree;
  bool? get entree => _$this._entree;
  set entree(bool? entree) => _$this._entree = entree;

  DateTime? _heure;
  DateTime? get heure => _$this._heure;
  set heure(DateTime? heure) => _$this._heure = heure;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  String? _reference;
  String? get reference => _$this._reference;
  set reference(String? reference) => _$this._reference = reference;

  String? _typeEcriture;
  String? get typeEcriture => _$this._typeEcriture;
  set typeEcriture(String? typeEcriture) => _$this._typeEcriture = typeEcriture;

  MouvementCaisseBuilder() {
    MouvementCaisse._defaults(this);
  }

  MouvementCaisseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _entree = $v.entree;
      _heure = $v.heure;
      _id = $v.id;
      _montantUnites = $v.montantUnites;
      _reference = $v.reference;
      _typeEcriture = $v.typeEcriture;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(MouvementCaisse other) {
    _$v = other as _$MouvementCaisse;
  }

  @override
  void update(void Function(MouvementCaisseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  MouvementCaisse build() => _build();

  _$MouvementCaisse _build() {
    final _$result = _$v ??
        _$MouvementCaisse._(
          commandeId: commandeId,
          entree: BuiltValueNullFieldError.checkNotNull(
              entree, r'MouvementCaisse', 'entree'),
          heure: BuiltValueNullFieldError.checkNotNull(
              heure, r'MouvementCaisse', 'heure'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'MouvementCaisse', 'id'),
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'MouvementCaisse', 'montantUnites'),
          reference: reference,
          typeEcriture: BuiltValueNullFieldError.checkNotNull(
              typeEcriture, r'MouvementCaisse', 'typeEcriture'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
