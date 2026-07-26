// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_echec.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IssueEchec extends IssueEchec {
  @override
  final String commandeId;
  @override
  final String detenteurArgent;
  @override
  final String detenteurMarchandise;
  @override
  final String devise;
  @override
  final bool indemnisationDue;
  @override
  final String issueId;
  @override
  final bool litigeOuvert;
  @override
  final int montantEnJeuUnites;
  @override
  final String? relivraisonId;
  @override
  final String sanction;

  factory _$IssueEchec([void Function(IssueEchecBuilder)? updates]) =>
      (IssueEchecBuilder()..update(updates))._build();

  _$IssueEchec._(
      {required this.commandeId,
      required this.detenteurArgent,
      required this.detenteurMarchandise,
      required this.devise,
      required this.indemnisationDue,
      required this.issueId,
      required this.litigeOuvert,
      required this.montantEnJeuUnites,
      this.relivraisonId,
      required this.sanction})
      : super._();
  @override
  IssueEchec rebuild(void Function(IssueEchecBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IssueEchecBuilder toBuilder() => IssueEchecBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IssueEchec &&
        commandeId == other.commandeId &&
        detenteurArgent == other.detenteurArgent &&
        detenteurMarchandise == other.detenteurMarchandise &&
        devise == other.devise &&
        indemnisationDue == other.indemnisationDue &&
        issueId == other.issueId &&
        litigeOuvert == other.litigeOuvert &&
        montantEnJeuUnites == other.montantEnJeuUnites &&
        relivraisonId == other.relivraisonId &&
        sanction == other.sanction;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, detenteurArgent.hashCode);
    _$hash = $jc(_$hash, detenteurMarchandise.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, indemnisationDue.hashCode);
    _$hash = $jc(_$hash, issueId.hashCode);
    _$hash = $jc(_$hash, litigeOuvert.hashCode);
    _$hash = $jc(_$hash, montantEnJeuUnites.hashCode);
    _$hash = $jc(_$hash, relivraisonId.hashCode);
    _$hash = $jc(_$hash, sanction.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IssueEchec')
          ..add('commandeId', commandeId)
          ..add('detenteurArgent', detenteurArgent)
          ..add('detenteurMarchandise', detenteurMarchandise)
          ..add('devise', devise)
          ..add('indemnisationDue', indemnisationDue)
          ..add('issueId', issueId)
          ..add('litigeOuvert', litigeOuvert)
          ..add('montantEnJeuUnites', montantEnJeuUnites)
          ..add('relivraisonId', relivraisonId)
          ..add('sanction', sanction))
        .toString();
  }
}

class IssueEchecBuilder implements Builder<IssueEchec, IssueEchecBuilder> {
  _$IssueEchec? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _detenteurArgent;
  String? get detenteurArgent => _$this._detenteurArgent;
  set detenteurArgent(String? detenteurArgent) =>
      _$this._detenteurArgent = detenteurArgent;

  String? _detenteurMarchandise;
  String? get detenteurMarchandise => _$this._detenteurMarchandise;
  set detenteurMarchandise(String? detenteurMarchandise) =>
      _$this._detenteurMarchandise = detenteurMarchandise;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  bool? _indemnisationDue;
  bool? get indemnisationDue => _$this._indemnisationDue;
  set indemnisationDue(bool? indemnisationDue) =>
      _$this._indemnisationDue = indemnisationDue;

  String? _issueId;
  String? get issueId => _$this._issueId;
  set issueId(String? issueId) => _$this._issueId = issueId;

  bool? _litigeOuvert;
  bool? get litigeOuvert => _$this._litigeOuvert;
  set litigeOuvert(bool? litigeOuvert) => _$this._litigeOuvert = litigeOuvert;

  int? _montantEnJeuUnites;
  int? get montantEnJeuUnites => _$this._montantEnJeuUnites;
  set montantEnJeuUnites(int? montantEnJeuUnites) =>
      _$this._montantEnJeuUnites = montantEnJeuUnites;

  String? _relivraisonId;
  String? get relivraisonId => _$this._relivraisonId;
  set relivraisonId(String? relivraisonId) =>
      _$this._relivraisonId = relivraisonId;

  String? _sanction;
  String? get sanction => _$this._sanction;
  set sanction(String? sanction) => _$this._sanction = sanction;

  IssueEchecBuilder() {
    IssueEchec._defaults(this);
  }

  IssueEchecBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _detenteurArgent = $v.detenteurArgent;
      _detenteurMarchandise = $v.detenteurMarchandise;
      _devise = $v.devise;
      _indemnisationDue = $v.indemnisationDue;
      _issueId = $v.issueId;
      _litigeOuvert = $v.litigeOuvert;
      _montantEnJeuUnites = $v.montantEnJeuUnites;
      _relivraisonId = $v.relivraisonId;
      _sanction = $v.sanction;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IssueEchec other) {
    _$v = other as _$IssueEchec;
  }

  @override
  void update(void Function(IssueEchecBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IssueEchec build() => _build();

  _$IssueEchec _build() {
    final _$result = _$v ??
        _$IssueEchec._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'IssueEchec', 'commandeId'),
          detenteurArgent: BuiltValueNullFieldError.checkNotNull(
              detenteurArgent, r'IssueEchec', 'detenteurArgent'),
          detenteurMarchandise: BuiltValueNullFieldError.checkNotNull(
              detenteurMarchandise, r'IssueEchec', 'detenteurMarchandise'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'IssueEchec', 'devise'),
          indemnisationDue: BuiltValueNullFieldError.checkNotNull(
              indemnisationDue, r'IssueEchec', 'indemnisationDue'),
          issueId: BuiltValueNullFieldError.checkNotNull(
              issueId, r'IssueEchec', 'issueId'),
          litigeOuvert: BuiltValueNullFieldError.checkNotNull(
              litigeOuvert, r'IssueEchec', 'litigeOuvert'),
          montantEnJeuUnites: BuiltValueNullFieldError.checkNotNull(
              montantEnJeuUnites, r'IssueEchec', 'montantEnJeuUnites'),
          relivraisonId: relivraisonId,
          sanction: BuiltValueNullFieldError.checkNotNull(
              sanction, r'IssueEchec', 'sanction'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
