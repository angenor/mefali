// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paiement_commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PaiementCommande extends PaiementCommande {
  @override
  final int appointExactUnites;
  @override
  final String etat;
  @override
  final String mode;

  factory _$PaiementCommande(
          [void Function(PaiementCommandeBuilder)? updates]) =>
      (PaiementCommandeBuilder()..update(updates))._build();

  _$PaiementCommande._(
      {required this.appointExactUnites,
      required this.etat,
      required this.mode})
      : super._();
  @override
  PaiementCommande rebuild(void Function(PaiementCommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PaiementCommandeBuilder toBuilder() =>
      PaiementCommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PaiementCommande &&
        appointExactUnites == other.appointExactUnites &&
        etat == other.etat &&
        mode == other.mode;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appointExactUnites.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PaiementCommande')
          ..add('appointExactUnites', appointExactUnites)
          ..add('etat', etat)
          ..add('mode', mode))
        .toString();
  }
}

class PaiementCommandeBuilder
    implements Builder<PaiementCommande, PaiementCommandeBuilder> {
  _$PaiementCommande? _$v;

  int? _appointExactUnites;
  int? get appointExactUnites => _$this._appointExactUnites;
  set appointExactUnites(int? appointExactUnites) =>
      _$this._appointExactUnites = appointExactUnites;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _mode;
  String? get mode => _$this._mode;
  set mode(String? mode) => _$this._mode = mode;

  PaiementCommandeBuilder() {
    PaiementCommande._defaults(this);
  }

  PaiementCommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appointExactUnites = $v.appointExactUnites;
      _etat = $v.etat;
      _mode = $v.mode;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PaiementCommande other) {
    _$v = other as _$PaiementCommande;
  }

  @override
  void update(void Function(PaiementCommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PaiementCommande build() => _build();

  _$PaiementCommande _build() {
    final _$result = _$v ??
        _$PaiementCommande._(
          appointExactUnites: BuiltValueNullFieldError.checkNotNull(
              appointExactUnites, r'PaiementCommande', 'appointExactUnites'),
          etat: BuiltValueNullFieldError.checkNotNull(
              etat, r'PaiementCommande', 'etat'),
          mode: BuiltValueNullFieldError.checkNotNull(
              mode, r'PaiementCommande', 'mode'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
