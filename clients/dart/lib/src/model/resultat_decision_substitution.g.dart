// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_decision_substitution.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatDecisionSubstitution extends ResultatDecisionSubstitution {
  @override
  final int devisPrixClientUnites;
  @override
  final String issue;
  @override
  final int montantArticlesUnites;
  @override
  final int totalUnites;

  factory _$ResultatDecisionSubstitution(
          [void Function(ResultatDecisionSubstitutionBuilder)? updates]) =>
      (ResultatDecisionSubstitutionBuilder()..update(updates))._build();

  _$ResultatDecisionSubstitution._(
      {required this.devisPrixClientUnites,
      required this.issue,
      required this.montantArticlesUnites,
      required this.totalUnites})
      : super._();
  @override
  ResultatDecisionSubstitution rebuild(
          void Function(ResultatDecisionSubstitutionBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatDecisionSubstitutionBuilder toBuilder() =>
      ResultatDecisionSubstitutionBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatDecisionSubstitution &&
        devisPrixClientUnites == other.devisPrixClientUnites &&
        issue == other.issue &&
        montantArticlesUnites == other.montantArticlesUnites &&
        totalUnites == other.totalUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, devisPrixClientUnites.hashCode);
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, montantArticlesUnites.hashCode);
    _$hash = $jc(_$hash, totalUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatDecisionSubstitution')
          ..add('devisPrixClientUnites', devisPrixClientUnites)
          ..add('issue', issue)
          ..add('montantArticlesUnites', montantArticlesUnites)
          ..add('totalUnites', totalUnites))
        .toString();
  }
}

class ResultatDecisionSubstitutionBuilder
    implements
        Builder<ResultatDecisionSubstitution,
            ResultatDecisionSubstitutionBuilder> {
  _$ResultatDecisionSubstitution? _$v;

  int? _devisPrixClientUnites;
  int? get devisPrixClientUnites => _$this._devisPrixClientUnites;
  set devisPrixClientUnites(int? devisPrixClientUnites) =>
      _$this._devisPrixClientUnites = devisPrixClientUnites;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  int? _montantArticlesUnites;
  int? get montantArticlesUnites => _$this._montantArticlesUnites;
  set montantArticlesUnites(int? montantArticlesUnites) =>
      _$this._montantArticlesUnites = montantArticlesUnites;

  int? _totalUnites;
  int? get totalUnites => _$this._totalUnites;
  set totalUnites(int? totalUnites) => _$this._totalUnites = totalUnites;

  ResultatDecisionSubstitutionBuilder() {
    ResultatDecisionSubstitution._defaults(this);
  }

  ResultatDecisionSubstitutionBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _devisPrixClientUnites = $v.devisPrixClientUnites;
      _issue = $v.issue;
      _montantArticlesUnites = $v.montantArticlesUnites;
      _totalUnites = $v.totalUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatDecisionSubstitution other) {
    _$v = other as _$ResultatDecisionSubstitution;
  }

  @override
  void update(void Function(ResultatDecisionSubstitutionBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatDecisionSubstitution build() => _build();

  _$ResultatDecisionSubstitution _build() {
    final _$result = _$v ??
        _$ResultatDecisionSubstitution._(
          devisPrixClientUnites: BuiltValueNullFieldError.checkNotNull(
              devisPrixClientUnites,
              r'ResultatDecisionSubstitution',
              'devisPrixClientUnites'),
          issue: BuiltValueNullFieldError.checkNotNull(
              issue, r'ResultatDecisionSubstitution', 'issue'),
          montantArticlesUnites: BuiltValueNullFieldError.checkNotNull(
              montantArticlesUnites,
              r'ResultatDecisionSubstitution',
              'montantArticlesUnites'),
          totalUnites: BuiltValueNullFieldError.checkNotNull(
              totalUnites, r'ResultatDecisionSubstitution', 'totalUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
