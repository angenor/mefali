// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_rupture.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IssueRupture extends IssueRupture {
  @override
  final int? ecartPourcent;
  @override
  final String issue;
  @override
  final int? montantArticlesUnites;
  @override
  final int? montantRetire;
  @override
  final int? resteS;
  @override
  final String? substitutionId;
  @override
  final int? totalUnites;

  factory _$IssueRupture([void Function(IssueRuptureBuilder)? updates]) =>
      (IssueRuptureBuilder()..update(updates))._build();

  _$IssueRupture._(
      {this.ecartPourcent,
      required this.issue,
      this.montantArticlesUnites,
      this.montantRetire,
      this.resteS,
      this.substitutionId,
      this.totalUnites})
      : super._();
  @override
  IssueRupture rebuild(void Function(IssueRuptureBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IssueRuptureBuilder toBuilder() => IssueRuptureBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IssueRupture &&
        ecartPourcent == other.ecartPourcent &&
        issue == other.issue &&
        montantArticlesUnites == other.montantArticlesUnites &&
        montantRetire == other.montantRetire &&
        resteS == other.resteS &&
        substitutionId == other.substitutionId &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ecartPourcent.hashCode);
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, montantRetire.hashCode);
    _$hash = $jc(_$hash, resteS.hashCode);
    _$hash = $jc(_$hash, substitutionId.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IssueRupture')
          ..add('ecartPourcent', ecartPourcent)
          ..add('issue', issue)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('montantRetire', montantRetire)
          ..add('resteS', resteS)
          ..add('substitutionId', substitutionId)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class IssueRuptureBuilder
    implements Builder<IssueRupture, IssueRuptureBuilder> {
  _$IssueRupture? _$v;

  int? _ecartPourcent;
  int? get ecartPourcent => _$this._ecartPourcent;
  set ecartPourcent(int? ecartPourcent) =>
      _$this._ecartPourcent = ecartPourcent;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  int? _montantRetire;
  int? get montantRetire => _$this._montantRetire;
  set montantRetire(int? montantRetire) =>
      _$this._montantRetire = montantRetire;

  int? _resteS;
  int? get resteS => _$this._resteS;
  set resteS(int? resteS) => _$this._resteS = resteS;

  String? _substitutionId;
  String? get substitutionId => _$this._substitutionId;
  set substitutionId(String? substitutionId) =>
      _$this._substitutionId = substitutionId;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  IssueRuptureBuilder() {
    IssueRupture._defaults(this);
  }

  IssueRuptureBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ecartPourcent = $v.ecartPourcent;
      _issue = $v.issue;
      _montantArticlesUnites = $v.montantArticlesUnites;
      _montantRetire = $v.montantRetire;
      _resteS = $v.resteS;
      _substitutionId = $v.substitutionId;
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IssueRupture other) {
    _$v = other as _$IssueRupture;
  }

  @override
  void update(void Function(IssueRuptureBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IssueRupture build() => _build();

  _$IssueRupture _build() {
    final _$result = _$v ??
        _$IssueRupture._(
          ecartPourcent: ecartPourcent,
          issue: BuiltValueNullFieldError.checkNotNull(
              issue, r'IssueRupture', 'issue'),
          montantArticlesUnites: montantArticlesUnites,
          montantRetire: montantRetire,
          resteS: resteS,
          substitutionId: substitutionId,
          totalUnites: totalUnites,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
