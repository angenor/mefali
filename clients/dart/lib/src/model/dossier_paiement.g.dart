// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dossier_paiement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DossierPaiement extends DossierPaiement {
  @override
  final String? arretId;
  @override
  final DateTime? closLe;
  @override
  final String? closMotifCle;
  @override
  final String? commandeId;
  @override
  final String? devise;
  @override
  final String etat;
  @override
  final String id;
  @override
  final int? montantAttendu;
  @override
  final int? montantConstate;
  @override
  final String motifCle;
  @override
  final DateTime ouvertLe;
  @override
  final String? transactionId;
  @override
  final String type;

  factory _$DossierPaiement([void Function(DossierPaiementBuilder)? updates]) =>
      (DossierPaiementBuilder()..update(updates))._build();

  _$DossierPaiement._(
      {this.arretId,
      this.closLe,
      this.closMotifCle,
      this.commandeId,
      this.devise,
      required this.etat,
      required this.id,
      this.montantAttendu,
      this.montantConstate,
      required this.motifCle,
      required this.ouvertLe,
      this.transactionId,
      required this.type})
      : super._();
  @override
  DossierPaiement rebuild(void Function(DossierPaiementBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DossierPaiementBuilder toBuilder() => DossierPaiementBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DossierPaiement &&
        arretId == other.arretId &&
        closLe == other.closLe &&
        closMotifCle == other.closMotifCle &&
        commandeId == other.commandeId &&
        devise == other.devise &&
        etat == other.etat &&
        id == other.id &&
        montantAttendu == other.montantAttendu &&
        montantConstate == other.montantConstate &&
        motifCle == other.motifCle &&
        ouvertLe == other.ouvertLe &&
        transactionId == other.transactionId &&
        type == other.type;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, closLe.hashCode);
    _$hash = $jc(_$hash, closMotifCle.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, montantAttendu.hashCode);
    _$hash = $jc(_$hash, montantConstate.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, ouvertLe.hashCode);
    _$hash = $jc(_$hash, transactionId.hashCode);
    _$hash = $jc(_$hash, type.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DossierPaiement')
          ..add('arretId', arretId)
          ..add('closLe', closLe)
          ..add('closMotifCle', closMotifCle)
          ..add('commandeId', commandeId)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('id', id)
          ..add('montantAttendu', montantAttendu)
          ..add('montantConstate', montantConstate)
          ..add('motifCle', motifCle)
          ..add('ouvertLe', ouvertLe)
          ..add('transactionId', transactionId)
          ..add('type', type))
        .toString();
  }
}

class DossierPaiementBuilder
    implements Builder<DossierPaiement, DossierPaiementBuilder> {
  _$DossierPaiement? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  DateTime? _closLe;
  DateTime? get closLe => _$this._closLe;
  set closLe(DateTime? closLe) => _$this._closLe = closLe;

  String? _closMotifCle;
  String? get closMotifCle => _$this._closMotifCle;
  set closMotifCle(String? closMotifCle) => _$this._closMotifCle = closMotifCle;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _montantAttendu;
  int? get montantAttendu => _$this._montantAttendu;
  set montantAttendu(int? montantAttendu) =>
      _$this._montantAttendu = montantAttendu;

  int? _montantConstate;
  int? get montantConstate => _$this._montantConstate;
  set montantConstate(int? montantConstate) =>
      _$this._montantConstate = montantConstate;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DateTime? _ouvertLe;
  DateTime? get ouvertLe => _$this._ouvertLe;
  set ouvertLe(DateTime? ouvertLe) => _$this._ouvertLe = ouvertLe;

  String? _transactionId;
  String? get transactionId => _$this._transactionId;
  set transactionId(String? transactionId) =>
      _$this._transactionId = transactionId;

  String? _type;
  String? get type => _$this._type;
  set type(String? type) => _$this._type = type;

  DossierPaiementBuilder() {
    DossierPaiement._defaults(this);
  }

  DossierPaiementBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _closLe = $v.closLe;
      _closMotifCle = $v.closMotifCle;
      _commandeId = $v.commandeId;
      _devise = $v.devise;
      _etat = $v.etat;
      _id = $v.id;
      _montantAttendu = $v.montantAttendu;
      _montantConstate = $v.montantConstate;
      _motifCle = $v.motifCle;
      _ouvertLe = $v.ouvertLe;
      _transactionId = $v.transactionId;
      _type = $v.type;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DossierPaiement other) {
    _$v = other as _$DossierPaiement;
  }

  @override
  void update(void Function(DossierPaiementBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DossierPaiement build() => _build();

  _$DossierPaiement _build() {
    final _$result = _$v ??
        _$DossierPaiement._(
          arretId: arretId,
          closLe: closLe,
          closMotifCle: closMotifCle,
          commandeId: commandeId,
          devise: devise,
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'DossierPaiement', 'etat'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'DossierPaiement', 'id'),
          montantAttendu: montantAttendu,
          montantConstate: montantConstate,
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DossierPaiement', 'motifCle'),
          ouvertLe: BuiltValueNullFieldError.checkNotNull(
              ouvertLe, r'DossierPaiement', 'ouvertLe'),
          transactionId: transactionId,
          type: BuiltValueNullFieldError.checkNotNull(
              type, r'DossierPaiement', 'type'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
