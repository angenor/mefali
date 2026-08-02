// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_paiement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SessionPaiement extends SessionPaiement {
  @override
  final String? accesPaiement;
  @override
  final String devise;
  @override
  final String etat;
  @override
  final DateTime expireLe;
  @override
  final int montantUnites;
  @override
  final String moyen;
  @override
  final int restantS;
  @override
  final String transactionId;

  factory _$SessionPaiement([void Function(SessionPaiementBuilder)? updates]) =>
      (SessionPaiementBuilder()..update(updates))._build();

  _$SessionPaiement._(
      {this.accesPaiement,
      required this.devise,
      required this.etat,
      required this.expireLe,
      required this.montantUnites,
      required this.moyen,
      required this.restantS,
      required this.transactionId})
      : super._();
  @override
  SessionPaiement rebuild(void Function(SessionPaiementBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SessionPaiementBuilder toBuilder() => SessionPaiementBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SessionPaiement &&
        accesPaiement == other.accesPaiement &&
        devise == other.devise &&
        etat == other.etat &&
        expireLe == other.expireLe &&
        montantUnites == other.montantUnites &&
        moyen == other.moyen &&
        restantS == other.restantS &&
        transactionId == other.transactionId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, accesPaiement.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, expireLe.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, moyen.hashCode);
    _$hash = $jc(_$hash, restantS.hashCode);
    _$hash = $jc(_$hash, transactionId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SessionPaiement')
          ..add('accesPaiement', accesPaiement)
          ..add('devise', devise)
          ..add('etat', etat)
          ..add('expireLe', expireLe)
          ..add('montantUnites', montantUnites)
          ..add('moyen', moyen)
          ..add('restantS', restantS)
          ..add('transactionId', transactionId))
        .toString();
  }
}

class SessionPaiementBuilder
    implements Builder<SessionPaiement, SessionPaiementBuilder> {
  _$SessionPaiement? _$v;

  String? _accesPaiement;
  String? get accesPaiement => _$this._accesPaiement;
  set accesPaiement(String? accesPaiement) =>
      _$this._accesPaiement = accesPaiement;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  DateTime? _expireLe;
  DateTime? get expireLe => _$this._expireLe;
  set expireLe(DateTime? expireLe) => _$this._expireLe = expireLe;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  String? _moyen;
  String? get moyen => _$this._moyen;
  set moyen(String? moyen) => _$this._moyen = moyen;

  int? _restantS;
  int? get restantS => _$this._restantS;
  set restantS(int? restantS) => _$this._restantS = restantS;

  String? _transactionId;
  String? get transactionId => _$this._transactionId;
  set transactionId(String? transactionId) =>
      _$this._transactionId = transactionId;

  SessionPaiementBuilder() {
    SessionPaiement._defaults(this);
  }

  SessionPaiementBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _accesPaiement = $v.accesPaiement;
      _devise = $v.devise;
      _etat = $v.etat;
      _expireLe = $v.expireLe;
      _montantUnites = $v.montantUnites;
      _moyen = $v.moyen;
      _restantS = $v.restantS;
      _transactionId = $v.transactionId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SessionPaiement other) {
    _$v = other as _$SessionPaiement;
  }

  @override
  void update(void Function(SessionPaiementBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SessionPaiement build() => _build();

  _$SessionPaiement _build() {
    final _$result = _$v ??
        _$SessionPaiement._(
          accesPaiement: accesPaiement,
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'SessionPaiement', 'devise'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'SessionPaiement', 'etat'),
          expireLe: BuiltValueNullFieldError.checkNotNull(
              expireLe, r'SessionPaiement', 'expireLe'),
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'SessionPaiement', 'montantUnites'),
          moyen: BuiltValueNullFieldError.checkNotNull(
              moyen, r'SessionPaiement', 'moyen'),
          restantS: BuiltValueNullFieldError.checkNotNull(
              restantS, r'SessionPaiement', 'restantS'),
          transactionId: BuiltValueNullFieldError.checkNotNull(
              transactionId, r'SessionPaiement', 'transactionId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
