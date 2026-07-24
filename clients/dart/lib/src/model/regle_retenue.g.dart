// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regle_retenue.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RegleRetenue extends RegleRetenue {
  @override
  final int priorite;
  @override
  final String regleId;
  @override
  final String transportSlug;

  factory _$RegleRetenue([void Function(RegleRetenueBuilder)? updates]) =>
      (RegleRetenueBuilder()..update(updates))._build();

  _$RegleRetenue._(
      {required this.priorite,
      required this.regleId,
      required this.transportSlug})
      : super._();
  @override
  RegleRetenue rebuild(void Function(RegleRetenueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RegleRetenueBuilder toBuilder() => RegleRetenueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RegleRetenue &&
        priorite == other.priorite &&
        regleId == other.regleId &&
        transportSlug == other.transportSlug;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, priorite.hashCode);
    _$hash = $jc(_$hash, regleId.hashCode);
    _$hash = $jc(_$hash, transportSlug.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RegleRetenue')
          ..add('priorite', priorite)
          ..add('regleId', regleId)
          ..add('transportSlug', transportSlug))
        .toString();
  }
}

class RegleRetenueBuilder
    implements Builder<RegleRetenue, RegleRetenueBuilder> {
  _$RegleRetenue? _$v;

  int? _priorite;
  int? get priorite => _$this._priorite;
  set priorite(int? priorite) => _$this._priorite = priorite;

  String? _regleId;
  String? get regleId => _$this._regleId;
  set regleId(String? regleId) => _$this._regleId = regleId;

  String? _transportSlug;
  String? get transportSlug => _$this._transportSlug;
  set transportSlug(String? transportSlug) =>
      _$this._transportSlug = transportSlug;

  RegleRetenueBuilder() {
    RegleRetenue._defaults(this);
  }

  RegleRetenueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _priorite = $v.priorite;
      _regleId = $v.regleId;
      _transportSlug = $v.transportSlug;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RegleRetenue other) {
    _$v = other as _$RegleRetenue;
  }

  @override
  void update(void Function(RegleRetenueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RegleRetenue build() => _build();

  _$RegleRetenue _build() {
    final _$result = _$v ??
        _$RegleRetenue._(
          priorite: BuiltValueNullFieldError.checkNotNull(
              priorite, r'RegleRetenue', 'priorite'),
          regleId: BuiltValueNullFieldError.checkNotNull(
              regleId, r'RegleRetenue', 'regleId'),
          transportSlug: BuiltValueNullFieldError.checkNotNull(
              transportSlug, r'RegleRetenue', 'transportSlug'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
