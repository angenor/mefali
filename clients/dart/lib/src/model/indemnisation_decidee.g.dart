// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'indemnisation_decidee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$IndemnisationDecidee extends IndemnisationDecidee {
  @override
  final String? ecritureId;
  @override
  final String etat;
  @override
  final String id;

  factory _$IndemnisationDecidee(
          [void Function(IndemnisationDecideeBuilder)? updates]) =>
      (IndemnisationDecideeBuilder()..update(updates))._build();

  _$IndemnisationDecidee._(
      {this.ecritureId, required this.etat, required this.id})
      : super._();
  @override
  IndemnisationDecidee rebuild(
          void Function(IndemnisationDecideeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  IndemnisationDecideeBuilder toBuilder() =>
      IndemnisationDecideeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is IndemnisationDecidee &&
        ecritureId == other.ecritureId &&
        etat == other.etat &&
        id == other.id;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ecritureId.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'IndemnisationDecidee')
          ..add('ecritureId', ecritureId)
          ..add('etat', etat)
          ..add('id', id))
        .toString();
  }
}

class IndemnisationDecideeBuilder
    implements Builder<IndemnisationDecidee, IndemnisationDecideeBuilder> {
  _$IndemnisationDecidee? _$v;

  String? _ecritureId;
  String? get ecritureId => _$this._ecritureId;
  set ecritureId(String? ecritureId) => _$this._ecritureId = ecritureId;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  IndemnisationDecideeBuilder() {
    IndemnisationDecidee._defaults(this);
  }

  IndemnisationDecideeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ecritureId = $v.ecritureId;
      _etat = $v.etat;
      _id = $v.id;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(IndemnisationDecidee other) {
    _$v = other as _$IndemnisationDecidee;
  }

  @override
  void update(void Function(IndemnisationDecideeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  IndemnisationDecidee build() => _build();

  _$IndemnisationDecidee _build() {
    final _$result = _$v ??
        _$IndemnisationDecidee._(
          ecritureId: ecritureId,
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'IndemnisationDecidee', 'etat'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'IndemnisationDecidee', 'id'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
