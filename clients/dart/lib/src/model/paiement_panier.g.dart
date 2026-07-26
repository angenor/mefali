// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paiement_panier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaiementPanier extends PaiementPanier {
  @override
  final bool cashAutorise;
  @override
  final String? motifCle;
  @override
  final int plafondUnites;

  factory _$PaiementPanier([void Function(PaiementPanierBuilder)? updates]) =>
      (PaiementPanierBuilder()..update(updates))._build();

  _$PaiementPanier._(
      {required this.cashAutorise, this.motifCle, required this.plafondUnites})
      : super._();
  @override
  PaiementPanier rebuild(void Function(PaiementPanierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaiementPanierBuilder toBuilder() => PaiementPanierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaiementPanier &&
        cashAutorise == other.cashAutorise &&
        motifCle == other.motifCle &&
        plafondUnites == other.plafondUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, cashAutorise.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, plafondUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaiementPanier')
          ..add('cashAutorise', cashAutorise)
          ..add('motifCle', motifCle)
          ..add('plafondUnites', plafondUnites))
        .toString();
  }
}

class PaiementPanierBuilder
    implements Builder<PaiementPanier, PaiementPanierBuilder> {
  _$PaiementPanier? _$v;

  bool? _cashAutorise;
  bool? get cashAutorise => _$this._cashAutorise;
  set cashAutorise(bool? cashAutorise) => _$this._cashAutorise = cashAutorise;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  int? _plafondUnites;
  int? get plafondUnites => _$this._plafondUnites;
  set plafondUnites(int? plafondUnites) =>
      _$this._plafondUnites = plafondUnites;

  PaiementPanierBuilder() {
    PaiementPanier._defaults(this);
  }

  PaiementPanierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _cashAutorise = $v.cashAutorise;
      _motifCle = $v.motifCle;
      _plafondUnites = $v.plafondUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaiementPanier other) {
    _$v = other as _$PaiementPanier;
  }

  @override
  void update(void Function(PaiementPanierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaiementPanier build() => _build();

  _$PaiementPanier _build() {
    final _$result = _$v ??
        _$PaiementPanier._(
          cashAutorise: BuiltValueNullFieldError.checkNotNull(
              cashAutorise, r'PaiementPanier', 'cashAutorise'),
          motifCle: motifCle,
          plafondUnites: BuiltValueNullFieldError.checkNotNull(
              plafondUnites, r'PaiementPanier', 'plafondUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
