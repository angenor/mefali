// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_devis_panier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeDevisPanier extends DemandeDevisPanier {
  @override
  final String categorieSlug;
  @override
  final Lieu lieu;
  @override
  final BuiltList<LignePanier> lignes;
  @override
  final String transportSlug;
  @override
  final String zoneId;

  factory _$DemandeDevisPanier(
          [void Function(DemandeDevisPanierBuilder)? updates]) =>
      (DemandeDevisPanierBuilder()..update(updates))._build();

  _$DemandeDevisPanier._(
      {required this.categorieSlug,
      required this.lieu,
      required this.lignes,
      required this.transportSlug,
      required this.zoneId})
      : super._();
  @override
  DemandeDevisPanier rebuild(
          void Function(DemandeDevisPanierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeDevisPanierBuilder toBuilder() =>
      DemandeDevisPanierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeDevisPanier &&
        categorieSlug == other.categorieSlug &&
        lieu == other.lieu &&
        lignes == other.lignes &&
        transportSlug == other.transportSlug &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, lieu.hashCode);
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, transportSlug.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeDevisPanier')
          ..add('categorieSlug', categorieSlug)
          ..add('lieu', lieu)
          ..add('lignes', lignes)
          ..add('transportSlug', transportSlug)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class DemandeDevisPanierBuilder
    implements Builder<DemandeDevisPanier, DemandeDevisPanierBuilder> {
  _$DemandeDevisPanier? _$v;

  String? _categorieSlug;
  String? get categorieSlug => _$this._categorieSlug;
  set categorieSlug(String? categorieSlug) =>
      _$this._categorieSlug = categorieSlug;

  LieuBuilder? _lieu;
  LieuBuilder get lieu => _$this._lieu ??= LieuBuilder();
  set lieu(LieuBuilder? lieu) => _$this._lieu = lieu;

  ListBuilder<LignePanier>? _lignes;
  ListBuilder<LignePanier> get lignes =>
      _$this._lignes ??= ListBuilder<LignePanier>();
  set lignes(ListBuilder<LignePanier>? lignes) => _$this._lignes = lignes;

  String? _transportSlug;
  String? get transportSlug => _$this._transportSlug;
  set transportSlug(String? transportSlug) =>
      _$this._transportSlug = transportSlug;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  DemandeDevisPanierBuilder() {
    DemandeDevisPanier._defaults(this);
  }

  DemandeDevisPanierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _categorieSlug = $v.categorieSlug;
      _lieu = $v.lieu.toBuilder();
      _lignes = $v.lignes.toBuilder();
      _transportSlug = $v.transportSlug;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeDevisPanier other) {
    _$v = other as _$DemandeDevisPanier;
  }

  @override
  void update(void Function(DemandeDevisPanierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeDevisPanier build() => _build();

  _$DemandeDevisPanier _build() {
    _$DemandeDevisPanier _$result;
    try {
      _$result = _$v ??
          _$DemandeDevisPanier._(
            categorieSlug: BuiltValueNullFieldError.checkNotNull(
                categorieSlug, r'DemandeDevisPanier', 'categorieSlug'),
            lieu: lieu.build(),
            lignes: lignes.build(),
            transportSlug: BuiltValueNullFieldError.checkNotNull(
                transportSlug, r'DemandeDevisPanier', 'transportSlug'),
            zoneId: BuiltValueNullFieldError.checkNotNull(
                zoneId, r'DemandeDevisPanier', 'zoneId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lieu';
        lieu.build();
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DemandeDevisPanier', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
