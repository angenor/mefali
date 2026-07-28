// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refus_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RefusOffre extends RefusOffre {
  @override
  final String issue;

  factory _$RefusOffre([void Function(RefusOffreBuilder)? updates]) =>
      (RefusOffreBuilder()..update(updates))._build();

  _$RefusOffre._({required this.issue}) : super._();
  @override
  RefusOffre rebuild(void Function(RefusOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RefusOffreBuilder toBuilder() => RefusOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RefusOffre && issue == other.issue;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RefusOffre')..add('issue', issue))
        .toString();
  }
}

class RefusOffreBuilder implements Builder<RefusOffre, RefusOffreBuilder> {
  _$RefusOffre? _$v;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  RefusOffreBuilder() {
    RefusOffre._defaults(this);
  }

  RefusOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _issue = $v.issue;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RefusOffre other) {
    _$v = other as _$RefusOffre;
  }

  @override
  void update(void Function(RefusOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RefusOffre build() => _build();

  _$RefusOffre _build() {
    final _$result = _$v ??
        _$RefusOffre._(
          issue: BuiltValueNullFieldError.checkNotNull(
              issue, r'RefusOffre', 'issue'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
