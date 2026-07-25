// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ligne_panier.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LignePanier extends LignePanier {
  @override
  final String articleId;
  @override
  final String? preference;
  @override
  final String prestataireId;
  @override
  final int quantite;

  factory _$LignePanier([void Function(LignePanierBuilder)? updates]) =>
      (LignePanierBuilder()..update(updates))._build();

  _$LignePanier._(
      {required this.articleId,
      this.preference,
      required this.prestataireId,
      required this.quantite})
      : super._();
  @override
  LignePanier rebuild(void Function(LignePanierBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LignePanierBuilder toBuilder() => LignePanierBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LignePanier &&
        articleId == other.articleId &&
        preference == other.preference &&
        prestataireId == other.prestataireId &&
        quantite == other.quantite;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, articleId.hashCode);
    _$hash = $jc(_$hash, preference.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, quantite.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LignePanier')
          ..add('articleId', articleId)
          ..add('preference', preference)
          ..add('prestataireId', prestataireId)
          ..add('quantite', quantite))
        .toString();
  }
}

class LignePanierBuilder implements Builder<LignePanier, LignePanierBuilder> {
  _$LignePanier? _$v;

  String? _articleId;
  String? get articleId => _$this._articleId;
  set articleId(String? articleId) => _$this._articleId = articleId;

  String? _preference;
  String? get preference => _$this._preference;
  set preference(String? preference) => _$this._preference = preference;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  int? _quantite;
  int? get quantite => _$this._quantite;
  set quantite(int? quantite) => _$this._quantite = quantite;

  LignePanierBuilder() {
    LignePanier._defaults(this);
  }

  LignePanierBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _articleId = $v.articleId;
      _preference = $v.preference;
      _prestataireId = $v.prestataireId;
      _quantite = $v.quantite;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LignePanier other) {
    _$v = other as _$LignePanier;
  }

  @override
  void update(void Function(LignePanierBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LignePanier build() => _build();

  _$LignePanier _build() {
    final _$result = _$v ??
        _$LignePanier._(
          articleId: BuiltValueNullFieldError.checkNotNull(
              articleId, r'LignePanier', 'articleId'),
          preference: preference,
          prestataireId: BuiltValueNullFieldError.checkNotNull(
              prestataireId, r'LignePanier', 'prestataireId'),
          quantite: BuiltValueNullFieldError.checkNotNull(
              quantite, r'LignePanier', 'quantite'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
