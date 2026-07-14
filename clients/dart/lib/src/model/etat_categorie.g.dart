// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_categorie.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatCategorie extends EtatCategorie {
  @override
  final bool actif;
  @override
  final String categorie;
  @override
  final ForcageDto forcage;
  @override
  final String zone;

  factory _$EtatCategorie([void Function(EtatCategorieBuilder)? updates]) =>
      (EtatCategorieBuilder()..update(updates))._build();

  _$EtatCategorie._(
      {required this.actif,
      required this.categorie,
      required this.forcage,
      required this.zone})
      : super._();
  @override
  EtatCategorie rebuild(void Function(EtatCategorieBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatCategorieBuilder toBuilder() => EtatCategorieBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatCategorie &&
        actif == other.actif &&
        categorie == other.categorie &&
        forcage == other.forcage &&
        zone == other.zone;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, actif.hashCode);
    _$hash = $jc(_$hash, categorie.hashCode);
    _$hash = $jc(_$hash, forcage.hashCode);
    _$hash = $jc(_$hash, zone.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatCategorie')
          ..add('actif', actif)
          ..add('categorie', categorie)
          ..add('forcage', forcage)
          ..add('zone', zone))
        .toString();
  }
}

class EtatCategorieBuilder
    implements Builder<EtatCategorie, EtatCategorieBuilder> {
  _$EtatCategorie? _$v;

  bool? _actif;
  bool? get actif => _$this._actif;
  set actif(bool? actif) => _$this._actif = actif;

  String? _categorie;
  String? get categorie => _$this._categorie;
  set categorie(String? categorie) => _$this._categorie = categorie;

  ForcageDto? _forcage;
  ForcageDto? get forcage => _$this._forcage;
  set forcage(ForcageDto? forcage) => _$this._forcage = forcage;

  String? _zone;
  String? get zone => _$this._zone;
  set zone(String? zone) => _$this._zone = zone;

  EtatCategorieBuilder() {
    EtatCategorie._defaults(this);
  }

  EtatCategorieBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _actif = $v.actif;
      _categorie = $v.categorie;
      _forcage = $v.forcage;
      _zone = $v.zone;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatCategorie other) {
    _$v = other as _$EtatCategorie;
  }

  @override
  void update(void Function(EtatCategorieBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatCategorie build() => _build();

  _$EtatCategorie _build() {
    final _$result = _$v ??
        _$EtatCategorie._(
          actif: BuiltValueNullFieldError.checkNotNull(
              actif, r'EtatCategorie', 'actif'),
          categorie: BuiltValueNullFieldError.checkNotNull(
              categorie, r'EtatCategorie', 'categorie'),
          forcage: BuiltValueNullFieldError.checkNotNull(
              forcage, r'EtatCategorie', 'forcage'),
          zone: BuiltValueNullFieldError.checkNotNull(
              zone, r'EtatCategorie', 'zone'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
