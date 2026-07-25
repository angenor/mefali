// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_creation_commande.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeCreationCommande extends DemandeCreationCommande {
  @override
  final String? adresseId;
  @override
  final String categorieSlug;
  @override
  final Lieu? lieu;
  @override
  final BuiltList<LignePanier> lignes;
  @override
  final String modePaiement;
  @override
  final String? repereTexte;
  @override
  final String? repereVocalCle;
  @override
  final String transportSlug;
  @override
  final String zoneId;

  factory _$DemandeCreationCommande(
          [void Function(DemandeCreationCommandeBuilder)? updates]) =>
      (DemandeCreationCommandeBuilder()..update(updates))._build();

  _$DemandeCreationCommande._(
      {this.adresseId,
      required this.categorieSlug,
      this.lieu,
      required this.lignes,
      required this.modePaiement,
      this.repereTexte,
      this.repereVocalCle,
      required this.transportSlug,
      required this.zoneId})
      : super._();
  @override
  DemandeCreationCommande rebuild(
          void Function(DemandeCreationCommandeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeCreationCommandeBuilder toBuilder() =>
      DemandeCreationCommandeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeCreationCommande &&
        adresseId == other.adresseId &&
        categorieSlug == other.categorieSlug &&
        lieu == other.lieu &&
        lignes == other.lignes &&
        modePaiement == other.modePaiement &&
        repereTexte == other.repereTexte &&
        repereVocalCle == other.repereVocalCle &&
        transportSlug == other.transportSlug &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, adresseId.hashCode);
    _$hash = $jc(_$hash, categorieSlug.hashCode);
    _$hash = $jc(_$hash, lieu.hashCode);
    _$hash = $jc(_$hash, lignes.hashCode);
    _$hash = $jc(_$hash, modePaiement.hashCode);
    _$hash = $jc(_$hash, repereTexte.hashCode);
    _$hash = $jc(_$hash, repereVocalCle.hashCode);
    _$hash = $jc(_$hash, transportSlug.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeCreationCommande')
          ..add('adresseId', adresseId)
          ..add('categorieSlug', categorieSlug)
          ..add('lieu', lieu)
          ..add('lignes', lignes)
          ..add('modePaiement', modePaiement)
          ..add('repereTexte', repereTexte)
          ..add('repereVocalCle', repereVocalCle)
          ..add('transportSlug', transportSlug)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class DemandeCreationCommandeBuilder
    implements
        Builder<DemandeCreationCommande, DemandeCreationCommandeBuilder> {
  _$DemandeCreationCommande? _$v;

  String? _adresseId;
  String? get adresseId => _$this._adresseId;
  set adresseId(String? adresseId) => _$this._adresseId = adresseId;

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

  String? _modePaiement;
  String? get modePaiement => _$this._modePaiement;
  set modePaiement(String? modePaiement) => _$this._modePaiement = modePaiement;

  String? _repereTexte;
  String? get repereTexte => _$this._repereTexte;
  set repereTexte(String? repereTexte) => _$this._repereTexte = repereTexte;

  String? _repereVocalCle;
  String? get repereVocalCle => _$this._repereVocalCle;
  set repereVocalCle(String? repereVocalCle) =>
      _$this._repereVocalCle = repereVocalCle;

  String? _transportSlug;
  String? get transportSlug => _$this._transportSlug;
  set transportSlug(String? transportSlug) =>
      _$this._transportSlug = transportSlug;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  DemandeCreationCommandeBuilder() {
    DemandeCreationCommande._defaults(this);
  }

  DemandeCreationCommandeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _adresseId = $v.adresseId;
      _categorieSlug = $v.categorieSlug;
      _lieu = $v.lieu?.toBuilder();
      _lignes = $v.lignes.toBuilder();
      _modePaiement = $v.modePaiement;
      _repereTexte = $v.repereTexte;
      _repereVocalCle = $v.repereVocalCle;
      _transportSlug = $v.transportSlug;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeCreationCommande other) {
    _$v = other as _$DemandeCreationCommande;
  }

  @override
  void update(void Function(DemandeCreationCommandeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeCreationCommande build() => _build();

  _$DemandeCreationCommande _build() {
    _$DemandeCreationCommande _$result;
    try {
      _$result = _$v ??
          _$DemandeCreationCommande._(
            adresseId: adresseId,
            categorieSlug: BuiltValueNullFieldError.checkNotNull(
                categorieSlug, r'DemandeCreationCommande', 'categorieSlug'),
            lieu: _lieu?.build(),
            lignes: lignes.build(),
            modePaiement: BuiltValueNullFieldError.checkNotNull(
                modePaiement, r'DemandeCreationCommande', 'modePaiement'),
            repereTexte: repereTexte,
            repereVocalCle: repereVocalCle,
            transportSlug: BuiltValueNullFieldError.checkNotNull(
                transportSlug, r'DemandeCreationCommande', 'transportSlug'),
            zoneId: BuiltValueNullFieldError.checkNotNull(
                zoneId, r'DemandeCreationCommande', 'zoneId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'lieu';
        _lieu?.build();
        _$failedField = 'lignes';
        lignes.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'DemandeCreationCommande', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
