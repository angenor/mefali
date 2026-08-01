// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offre_livraison_declaration.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OffreLivraisonDeclaration extends OffreLivraisonDeclaration {
  @override
  final String offre;
  @override
  final int? seuilUnites;

  factory _$OffreLivraisonDeclaration(
          [void Function(OffreLivraisonDeclarationBuilder)? updates]) =>
      (OffreLivraisonDeclarationBuilder()..update(updates))._build();

  _$OffreLivraisonDeclaration._({required this.offre, this.seuilUnites})
      : super._();
  @override
  OffreLivraisonDeclaration rebuild(
          void Function(OffreLivraisonDeclarationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffreLivraisonDeclarationBuilder toBuilder() =>
      OffreLivraisonDeclarationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffreLivraisonDeclaration &&
        offre == other.offre &&
        seuilUnites == other.seuilUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, offre.hashCode);
    _$hash = $jc(_$hash, seuilUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffreLivraisonDeclaration')
          ..add('offre', offre)
          ..add('seuilUnites', seuilUnites))
        .toString();
  }
}

class OffreLivraisonDeclarationBuilder
    implements
        Builder<OffreLivraisonDeclaration, OffreLivraisonDeclarationBuilder> {
  _$OffreLivraisonDeclaration? _$v;

  String? _offre;
  String? get offre => _$this._offre;
  set offre(String? offre) => _$this._offre = offre;

  int? _seuilUnites;
  int? get seuilUnites => _$this._seuilUnites;
  set seuilUnites(int? seuilUnites) => _$this._seuilUnites = seuilUnites;

  OffreLivraisonDeclarationBuilder() {
    OffreLivraisonDeclaration._defaults(this);
  }

  OffreLivraisonDeclarationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _offre = $v.offre;
      _seuilUnites = $v.seuilUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffreLivraisonDeclaration other) {
    _$v = other as _$OffreLivraisonDeclaration;
  }

  @override
  void update(void Function(OffreLivraisonDeclarationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OffreLivraisonDeclaration build() => _build();

  _$OffreLivraisonDeclaration _build() {
    final _$result = _$v ??
        _$OffreLivraisonDeclaration._(
          offre: BuiltValueNullFieldError.checkNotNull(
              offre, r'OffreLivraisonDeclaration', 'offre'),
          seuilUnites: seuilUnites,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
