// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remise_preprovisionnee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RemisePreprovisionnee extends RemisePreprovisionnee {
  @override
  final bool codeBloque;
  @override
  final String empreinteCode;
  @override
  final String empreinteJeton;
  @override
  final int essaisConsommes;
  @override
  final int essaisMax;
  @override
  final String modePaiement;
  @override
  final int montantAEncaisserUnites;
  @override
  final SeuilsPreuves preuves;

  factory _$RemisePreprovisionnee(
          [void Function(RemisePreprovisionneeBuilder)? updates]) =>
      (RemisePreprovisionneeBuilder()..update(updates))._build();

  _$RemisePreprovisionnee._(
      {required this.codeBloque,
      required this.empreinteCode,
      required this.empreinteJeton,
      required this.essaisConsommes,
      required this.essaisMax,
      required this.modePaiement,
      required this.montantAEncaisserUnites,
      required this.preuves})
      : super._();
  @override
  RemisePreprovisionnee rebuild(
          void Function(RemisePreprovisionneeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RemisePreprovisionneeBuilder toBuilder() =>
      RemisePreprovisionneeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RemisePreprovisionnee &&
        codeBloque == other.codeBloque &&
        empreinteCode == other.empreinteCode &&
        empreinteJeton == other.empreinteJeton &&
        essaisConsommes == other.essaisConsommes &&
        essaisMax == other.essaisMax &&
        modePaiement == other.modePaiement &&
        montantAEncaisserUnites == other.montantAEncaisserUnites &&
        preuves == other.preuves;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, codeBloque.hashCode);
    _$hash = $jc(_$hash, empreinteCode.hashCode);
    _$hash = $jc(_$hash, empreinteJeton.hashCode);
    _$hash = $jc(_$hash, essaisConsommes.hashCode);
    _$hash = $jc(_$hash, essaisMax.hashCode);
    _$hash = $jc(_$hash, modePaiement.hashCode);
    _$hash = $jc(_$hash, montantAEncaisserUnites.hashCode);
    _$hash = $jc(_$hash, preuves.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RemisePreprovisionnee')
          ..add('codeBloque', codeBloque)
          ..add('empreinteCode', empreinteCode)
          ..add('empreinteJeton', empreinteJeton)
          ..add('essaisConsommes', essaisConsommes)
          ..add('essaisMax', essaisMax)
          ..add('modePaiement', modePaiement)
          ..add('montantAEncaisserUnites', montantAEncaisserUnites)
          ..add('preuves', preuves))
        .toString();
  }
}

class RemisePreprovisionneeBuilder
    implements Builder<RemisePreprovisionnee, RemisePreprovisionneeBuilder> {
  _$RemisePreprovisionnee? _$v;

  bool? _codeBloque;
  bool? get codeBloque => _$this._codeBloque;
  set codeBloque(bool? codeBloque) => _$this._codeBloque = codeBloque;

  String? _empreinteCode;
  String? get empreinteCode => _$this._empreinteCode;
  set empreinteCode(String? empreinteCode) =>
      _$this._empreinteCode = empreinteCode;

  String? _empreinteJeton;
  String? get empreinteJeton => _$this._empreinteJeton;
  set empreinteJeton(String? empreinteJeton) =>
      _$this._empreinteJeton = empreinteJeton;

  int? _essaisConsommes;
  int? get essaisConsommes => _$this._essaisConsommes;
  set essaisConsommes(int? essaisConsommes) =>
      _$this._essaisConsommes = essaisConsommes;

  int? _essaisMax;
  int? get essaisMax => _$this._essaisMax;
  set essaisMax(int? essaisMax) => _$this._essaisMax = essaisMax;

  String? _modePaiement;
  String? get modePaiement => _$this._modePaiement;
  set modePaiement(String? modePaiement) => _$this._modePaiement = modePaiement;

  int? _montantAEncaisserUnites;
  int? get montantAEncaisserUnites => _$this._montantAEncaisserUnites;
  set montantAEncaisserUnites(int? montantAEncaisserUnites) =>
      _$this._montantAEncaisserUnites = montantAEncaisserUnites;

  SeuilsPreuvesBuilder? _preuves;
  SeuilsPreuvesBuilder get preuves =>
      _$this._preuves ??= SeuilsPreuvesBuilder();
  set preuves(SeuilsPreuvesBuilder? preuves) => _$this._preuves = preuves;

  RemisePreprovisionneeBuilder() {
    RemisePreprovisionnee._defaults(this);
  }

  RemisePreprovisionneeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _codeBloque = $v.codeBloque;
      _empreinteCode = $v.empreinteCode;
      _empreinteJeton = $v.empreinteJeton;
      _essaisConsommes = $v.essaisConsommes;
      _essaisMax = $v.essaisMax;
      _modePaiement = $v.modePaiement;
      _montantAEncaisserUnites = $v.montantAEncaisserUnites;
      _preuves = $v.preuves.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RemisePreprovisionnee other) {
    _$v = other as _$RemisePreprovisionnee;
  }

  @override
  void update(void Function(RemisePreprovisionneeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RemisePreprovisionnee build() => _build();

  _$RemisePreprovisionnee _build() {
    _$RemisePreprovisionnee _$result;
    try {
      _$result = _$v ??
          _$RemisePreprovisionnee._(
            codeBloque: BuiltValueNullFieldError.checkNotNull(
                codeBloque, r'RemisePreprovisionnee', 'codeBloque'),
            empreinteCode: BuiltValueNullFieldError.checkNotNull(
                empreinteCode, r'RemisePreprovisionnee', 'empreinteCode'),
            empreinteJeton: BuiltValueNullFieldError.checkNotNull(
                empreinteJeton, r'RemisePreprovisionnee', 'empreinteJeton'),
            essaisConsommes: BuiltValueNullFieldError.checkNotNull(
                essaisConsommes, r'RemisePreprovisionnee', 'essaisConsommes'),
            essaisMax: BuiltValueNullFieldError.checkNotNull(
                essaisMax, r'RemisePreprovisionnee', 'essaisMax'),
            modePaiement: BuiltValueNullFieldError.checkNotNull(
                modePaiement, r'RemisePreprovisionnee', 'modePaiement'),
            montantAEncaisserUnites: BuiltValueNullFieldError.checkNotNull(
                montantAEncaisserUnites,
                r'RemisePreprovisionnee',
                'montantAEncaisserUnites'),
            preuves: preuves.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'preuves';
        preuves.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'RemisePreprovisionnee', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
