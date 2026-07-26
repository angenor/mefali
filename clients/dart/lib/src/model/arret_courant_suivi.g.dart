// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arret_courant_suivi.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ArretCourantSuivi extends ArretCourantSuivi {
  @override
  final String arretId;
  @override
  final int ordre;
  @override
  final String? prestataireNom;
  @override
  final String statut;

  factory _$ArretCourantSuivi(
          [void Function(ArretCourantSuiviBuilder)? updates]) =>
      (ArretCourantSuiviBuilder()..update(updates))._build();

  _$ArretCourantSuivi._(
      {required this.arretId,
      required this.ordre,
      this.prestataireNom,
      required this.statut})
      : super._();
  @override
  ArretCourantSuivi rebuild(void Function(ArretCourantSuiviBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ArretCourantSuiviBuilder toBuilder() =>
      ArretCourantSuiviBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ArretCourantSuivi &&
        arretId == other.arretId &&
        ordre == other.ordre &&
        prestataireNom == other.prestataireNom &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, ordre.hashCode);
    _$hash = $jc(_$hash, prestataireNom.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ArretCourantSuivi')
          ..add('arretId', arretId)
          ..add('ordre', ordre)
          ..add('prestataireNom', prestataireNom)
          ..add('statut', statut))
        .toString();
  }
}

class ArretCourantSuiviBuilder
    implements Builder<ArretCourantSuivi, ArretCourantSuiviBuilder> {
  _$ArretCourantSuivi? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  int? _ordre;
  int? get ordre => _$this._ordre;
  set ordre(int? ordre) => _$this._ordre = ordre;

  String? _prestataireNom;
  String? get prestataireNom => _$this._prestataireNom;
  set prestataireNom(String? prestataireNom) =>
      _$this._prestataireNom = prestataireNom;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  ArretCourantSuiviBuilder() {
    ArretCourantSuivi._defaults(this);
  }

  ArretCourantSuiviBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _ordre = $v.ordre;
      _prestataireNom = $v.prestataireNom;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ArretCourantSuivi other) {
    _$v = other as _$ArretCourantSuivi;
  }

  @override
  void update(void Function(ArretCourantSuiviBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ArretCourantSuivi build() => _build();

  _$ArretCourantSuivi _build() {
    final _$result = _$v ??
        _$ArretCourantSuivi._(
          arretId: BuiltValueNullFieldError.checkNotNull(
              arretId, r'ArretCourantSuivi', 'arretId'),
          ordre: BuiltValueNullFieldError.checkNotNull(
              ordre, r'ArretCourantSuivi', 'ordre'),
          prestataireNom: prestataireNom,
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'ArretCourantSuivi', 'statut'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
