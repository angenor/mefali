// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_appel_declaree.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IssueAppelDeclaree extends IssueAppelDeclaree {
  @override
  final String issue;
  @override
  final String uuidClient;

  factory _$IssueAppelDeclaree(
          [void Function(IssueAppelDeclareeBuilder)? updates]) =>
      (IssueAppelDeclareeBuilder()..update(updates))._build();

  _$IssueAppelDeclaree._({required this.issue, required this.uuidClient})
      : super._();
  @override
  IssueAppelDeclaree rebuild(
          void Function(IssueAppelDeclareeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IssueAppelDeclareeBuilder toBuilder() =>
      IssueAppelDeclareeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IssueAppelDeclaree &&
        issue == other.issue &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IssueAppelDeclaree')
          ..add('issue', issue)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class IssueAppelDeclareeBuilder
    implements Builder<IssueAppelDeclaree, IssueAppelDeclareeBuilder> {
  _$IssueAppelDeclaree? _$v;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  IssueAppelDeclareeBuilder() {
    IssueAppelDeclaree._defaults(this);
  }

  IssueAppelDeclareeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _issue = $v.issue;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IssueAppelDeclaree other) {
    _$v = other as _$IssueAppelDeclaree;
  }

  @override
  void update(void Function(IssueAppelDeclareeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IssueAppelDeclaree build() => _build();

  _$IssueAppelDeclaree _build() {
    final _$result = _$v ??
        _$IssueAppelDeclaree._(
          issue: BuiltValueNullFieldError.checkNotNull(
              issue, r'IssueAppelDeclaree', 'issue'),
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'IssueAppelDeclaree', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
