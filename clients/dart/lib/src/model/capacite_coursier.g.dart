// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capacite_coursier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CapaciteCoursier extends CapaciteCoursier {
  @override
  final String famille;
  @override
  final String valeur;

  factory _$CapaciteCoursier(
          [void Function(CapaciteCoursierBuilder)? updates]) =>
      (CapaciteCoursierBuilder()..update(updates))._build();

  _$CapaciteCoursier._({required this.famille, required this.valeur})
      : super._();
  @override
  CapaciteCoursier rebuild(void Function(CapaciteCoursierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CapaciteCoursierBuilder toBuilder() =>
      CapaciteCoursierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CapaciteCoursier &&
        famille == other.famille &&
        valeur == other.valeur;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, famille.hashCode);
    _$hash = $jc(_$hash, valeur.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CapaciteCoursier')
          ..add('famille', famille)
          ..add('valeur', valeur))
        .toString();
  }
}

class CapaciteCoursierBuilder
    implements Builder<CapaciteCoursier, CapaciteCoursierBuilder> {
  _$CapaciteCoursier? _$v;

  String? _famille;
  String? get famille => _$this._famille;
  set famille(String? famille) => _$this._famille = famille;

  String? _valeur;
  String? get valeur => _$this._valeur;
  set valeur(String? valeur) => _$this._valeur = valeur;

  CapaciteCoursierBuilder() {
    CapaciteCoursier._defaults(this);
  }

  CapaciteCoursierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _famille = $v.famille;
      _valeur = $v.valeur;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CapaciteCoursier other) {
    _$v = other as _$CapaciteCoursier;
  }

  @override
  void update(void Function(CapaciteCoursierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CapaciteCoursier build() => _build();

  _$CapaciteCoursier _build() {
    final _$result = _$v ??
        _$CapaciteCoursier._(
          famille: BuiltValueNullFieldError.checkNotNull(
              famille, r'CapaciteCoursier', 'famille'),
          valeur: BuiltValueNullFieldError.checkNotNull(
              valeur, r'CapaciteCoursier', 'valeur'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
