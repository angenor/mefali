// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_rupture.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeRupture extends DemandeRupture {
  @override
  final String? articleProposeId;
  @override
  final String ligneId;
  @override
  final int? prixProposeUnites;
  @override
  final String? resolution;
  @override
  final String uuidClient;

  factory _$DemandeRupture([void Function(DemandeRuptureBuilder)? updates]) =>
      (DemandeRuptureBuilder()..update(updates))._build();

  _$DemandeRupture._(
      {this.articleProposeId,
      required this.ligneId,
      this.prixProposeUnites,
      this.resolution,
      required this.uuidClient})
      : super._();
  @override
  DemandeRupture rebuild(void Function(DemandeRuptureBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeRuptureBuilder toBuilder() => DemandeRuptureBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeRupture &&
        articleProposeId == other.articleProposeId &&
        ligneId == other.ligneId &&
        prixProposeUnites == other.prixProposeUnites &&
        resolution == other.resolution &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, articleProposeId.hashCode);
    _$hash = $jc(_$hash, ligneId.hashCode);
    _$hash = $jc(_$hash, prixProposeUnites.hashCode);
    _$hash = $jc(_$hash, resolution.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeRupture')
          ..add('articleProposeId', articleProposeId)
          ..add('ligneId', ligneId)
          ..add('prixProposeUnites', prixProposeUnites)
          ..add('resolution', resolution)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DemandeRuptureBuilder
    implements Builder<DemandeRupture, DemandeRuptureBuilder> {
  _$DemandeRupture? _$v;

  String? _articleProposeId;
  String? get articleProposeId => _$this._articleProposeId;
  set articleProposeId(String? articleProposeId) =>
      _$this._articleProposeId = articleProposeId;

  String? _ligneId;
  String? get ligneId => _$this._ligneId;
  set ligneId(String? ligneId) => _$this._ligneId = ligneId;

  int? _prixProposeUnites;
  int? get prixProposeUnites => _$this._prixProposeUnites;
  set prixProposeUnites(int? prixProposeUnites) =>
      _$this._prixProposeUnites = prixProposeUnites;

  String? _resolution;
  String? get resolution => _$this._resolution;
  set resolution(String? resolution) => _$this._resolution = resolution;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DemandeRuptureBuilder() {
    DemandeRupture._defaults(this);
  }

  DemandeRuptureBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _articleProposeId = $v.articleProposeId;
      _ligneId = $v.ligneId;
      _prixProposeUnites = $v.prixProposeUnites;
      _resolution = $v.resolution;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeRupture other) {
    _$v = other as _$DemandeRupture;
  }

  @override
  void update(void Function(DemandeRuptureBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeRupture build() => _build();

  _$DemandeRupture _build() {
    final _$result = _$v ??
        _$DemandeRupture._(
          articleProposeId: articleProposeId,
          ligneId: BuiltValueNullFieldError.checkNotNull(
              ligneId, r'DemandeRupture', 'ligneId'),
          prixProposeUnites: prixProposeUnites,
          resolution: resolution,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandeRupture', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
