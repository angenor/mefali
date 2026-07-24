// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offre_livraison_vendeur.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OffreLivraisonVendeur extends OffreLivraisonVendeur {
  @override
  final int? auDela;
  @override
  final bool toujours;

  factory _$OffreLivraisonVendeur(
          [void Function(OffreLivraisonVendeurBuilder)? updates]) =>
      (OffreLivraisonVendeurBuilder()..update(updates))._build();

  _$OffreLivraisonVendeur._({this.auDela, required this.toujours}) : super._();
  @override
  OffreLivraisonVendeur rebuild(
          void Function(OffreLivraisonVendeurBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffreLivraisonVendeurBuilder toBuilder() =>
      OffreLivraisonVendeurBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffreLivraisonVendeur &&
        auDela == other.auDela &&
        toujours == other.toujours;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, auDela.hashCode);
    _$hash = $jc(_$hash, toujours.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffreLivraisonVendeur')
          ..add('auDela', auDela)
          ..add('toujours', toujours))
        .toString();
  }
}

class OffreLivraisonVendeurBuilder
    implements Builder<OffreLivraisonVendeur, OffreLivraisonVendeurBuilder> {
  _$OffreLivraisonVendeur? _$v;

  int? _auDela;
  int? get auDela => _$this._auDela;
  set auDela(int? auDela) => _$this._auDela = auDela;

  bool? _toujours;
  bool? get toujours => _$this._toujours;
  set toujours(bool? toujours) => _$this._toujours = toujours;

  OffreLivraisonVendeurBuilder() {
    OffreLivraisonVendeur._defaults(this);
  }

  OffreLivraisonVendeurBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _auDela = $v.auDela;
      _toujours = $v.toujours;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffreLivraisonVendeur other) {
    _$v = other as _$OffreLivraisonVendeur;
  }

  @override
  void update(void Function(OffreLivraisonVendeurBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OffreLivraisonVendeur build() => _build();

  _$OffreLivraisonVendeur _build() {
    final _$result = _$v ??
        _$OffreLivraisonVendeur._(
          auDela: auDela,
          toujours: BuiltValueNullFieldError.checkNotNull(
              toujours, r'OffreLivraisonVendeur', 'toujours'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
