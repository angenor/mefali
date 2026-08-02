// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offre_livraison_reglee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OffreLivraisonReglee extends OffreLivraisonReglee {
  @override
  final String messageCle;
  @override
  final String offre;
  @override
  final int? seuilUnites;

  factory _$OffreLivraisonReglee(
          [void Function(OffreLivraisonRegleeBuilder)? updates]) =>
      (OffreLivraisonRegleeBuilder()..update(updates))._build();

  _$OffreLivraisonReglee._(
      {required this.messageCle, required this.offre, this.seuilUnites})
      : super._();
  @override
  OffreLivraisonReglee rebuild(
          void Function(OffreLivraisonRegleeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffreLivraisonRegleeBuilder toBuilder() =>
      OffreLivraisonRegleeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffreLivraisonReglee &&
        messageCle == other.messageCle &&
        offre == other.offre &&
        seuilUnites == other.seuilUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, messageCle.hashCode);
    _$hash = $jc(_$hash, offre.hashCode);
    _$hash = $jc(_$hash, seuilUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffreLivraisonReglee')
          ..add('messageCle', messageCle)
          ..add('offre', offre)
          ..add('seuilUnites', seuilUnites))
        .toString();
  }
}

class OffreLivraisonRegleeBuilder
    implements Builder<OffreLivraisonReglee, OffreLivraisonRegleeBuilder> {
  _$OffreLivraisonReglee? _$v;

  String? _messageCle;
  String? get messageCle => _$this._messageCle;
  set messageCle(String? messageCle) => _$this._messageCle = messageCle;

  String? _offre;
  String? get offre => _$this._offre;
  set offre(String? offre) => _$this._offre = offre;

  int? _seuilUnites;
  int? get seuilUnites => _$this._seuilUnites;
  set seuilUnites(int? seuilUnites) => _$this._seuilUnites = seuilUnites;

  OffreLivraisonRegleeBuilder() {
    OffreLivraisonReglee._defaults(this);
  }

  OffreLivraisonRegleeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _messageCle = $v.messageCle;
      _offre = $v.offre;
      _seuilUnites = $v.seuilUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffreLivraisonReglee other) {
    _$v = other as _$OffreLivraisonReglee;
  }

  @override
  void update(void Function(OffreLivraisonRegleeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OffreLivraisonReglee build() => _build();

  _$OffreLivraisonReglee _build() {
    final _$result = _$v ??
        _$OffreLivraisonReglee._(
          messageCle: BuiltValueNullFieldError.checkNotNull(
              messageCle, r'OffreLivraisonReglee', 'messageCle'),
          offre: BuiltValueNullFieldError.checkNotNull(
              offre, r'OffreLivraisonReglee', 'offre'),
          seuilUnites: seuilUnites,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
