// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drapeaux_zone.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DrapeauxZone extends DrapeauxZone {
  @override
  final bool gratuiteCommissions;
  @override
  final bool livraisonOfferteMefali;
  @override
  final bool pluie;

  factory _$DrapeauxZone([void Function(DrapeauxZoneBuilder)? updates]) =>
      (DrapeauxZoneBuilder()..update(updates))._build();

  _$DrapeauxZone._(
      {required this.gratuiteCommissions,
      required this.livraisonOfferteMefali,
      required this.pluie})
      : super._();
  @override
  DrapeauxZone rebuild(void Function(DrapeauxZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DrapeauxZoneBuilder toBuilder() => DrapeauxZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DrapeauxZone &&
        gratuiteCommissions == other.gratuiteCommissions &&
        livraisonOfferteMefali == other.livraisonOfferteMefali &&
        pluie == other.pluie;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, gratuiteCommissions.hashCode);
    _$hash = $jc(_$hash, livraisonOfferteMefali.hashCode);
    _$hash = $jc(_$hash, pluie.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DrapeauxZone')
          ..add('gratuiteCommissions', gratuiteCommissions)
          ..add('livraisonOfferteMefali', livraisonOfferteMefali)
          ..add('pluie', pluie))
        .toString();
  }
}

class DrapeauxZoneBuilder
    implements Builder<DrapeauxZone, DrapeauxZoneBuilder> {
  _$DrapeauxZone? _$v;

  bool? _gratuiteCommissions;
  bool? get gratuiteCommissions => _$this._gratuiteCommissions;
  set gratuiteCommissions(bool? gratuiteCommissions) =>
      _$this._gratuiteCommissions = gratuiteCommissions;

  bool? _livraisonOfferteMefali;
  bool? get livraisonOfferteMefali => _$this._livraisonOfferteMefali;
  set livraisonOfferteMefali(bool? livraisonOfferteMefali) =>
      _$this._livraisonOfferteMefali = livraisonOfferteMefali;

  bool? _pluie;
  bool? get pluie => _$this._pluie;
  set pluie(bool? pluie) => _$this._pluie = pluie;

  DrapeauxZoneBuilder() {
    DrapeauxZone._defaults(this);
  }

  DrapeauxZoneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _gratuiteCommissions = $v.gratuiteCommissions;
      _livraisonOfferteMefali = $v.livraisonOfferteMefali;
      _pluie = $v.pluie;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DrapeauxZone other) {
    _$v = other as _$DrapeauxZone;
  }

  @override
  void update(void Function(DrapeauxZoneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DrapeauxZone build() => _build();

  _$DrapeauxZone _build() {
    final _$result = _$v ??
        _$DrapeauxZone._(
          gratuiteCommissions: BuiltValueNullFieldError.checkNotNull(
              gratuiteCommissions, r'DrapeauxZone', 'gratuiteCommissions'),
          livraisonOfferteMefali: BuiltValueNullFieldError.checkNotNull(
              livraisonOfferteMefali,
              r'DrapeauxZone',
              'livraisonOfferteMefali'),
          pluie: BuiltValueNullFieldError.checkNotNull(
              pluie, r'DrapeauxZone', 'pluie'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
