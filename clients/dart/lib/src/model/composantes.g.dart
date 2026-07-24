// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'composantes.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Composantes extends Composantes {
  @override
  final int arrondi;
  @override
  final int base_;
  @override
  final int effortArrets;
  @override
  final int effortAttente;
  @override
  final int effortPaliers;
  @override
  final int km;
  @override
  final int retenueVendeur;
  @override
  final int supplements;

  factory _$Composantes([void Function(ComposantesBuilder)? updates]) =>
      (ComposantesBuilder()..update(updates))._build();

  _$Composantes._(
      {required this.arrondi,
      required this.base_,
      required this.effortArrets,
      required this.effortAttente,
      required this.effortPaliers,
      required this.km,
      required this.retenueVendeur,
      required this.supplements})
      : super._();
  @override
  Composantes rebuild(void Function(ComposantesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ComposantesBuilder toBuilder() => ComposantesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Composantes &&
        arrondi == other.arrondi &&
        base_ == other.base_ &&
        effortArrets == other.effortArrets &&
        effortAttente == other.effortAttente &&
        effortPaliers == other.effortPaliers &&
        km == other.km &&
        retenueVendeur == other.retenueVendeur &&
        supplements == other.supplements;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arrondi.hashCode);
    _$hash = $jc(_$hash, base_.hashCode);
    _$hash = $jc(_$hash, effortArrets.hashCode);
    _$hash = $jc(_$hash, effortAttente.hashCode);
    _$hash = $jc(_$hash, effortPaliers.hashCode);
    _$hash = $jc(_$hash, km.hashCode);
    _$hash = $jc(_$hash, retenueVendeur.hashCode);
    _$hash = $jc(_$hash, supplements.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Composantes')
          ..add('arrondi', arrondi)
          ..add('base_', base_)
          ..add('effortArrets', effortArrets)
          ..add('effortAttente', effortAttente)
          ..add('effortPaliers', effortPaliers)
          ..add('km', km)
          ..add('retenueVendeur', retenueVendeur)
          ..add('supplements', supplements))
        .toString();
  }
}

class ComposantesBuilder implements Builder<Composantes, ComposantesBuilder> {
  _$Composantes? _$v;

  int? _arrondi;
  int? get arrondi => _$this._arrondi;
  set arrondi(int? arrondi) => _$this._arrondi = arrondi;

  int? _base_;
  int? get base_ => _$this._base_;
  set base_(int? base_) => _$this._base_ = base_;

  int? _effortArrets;
  int? get effortArrets => _$this._effortArrets;
  set effortArrets(int? effortArrets) => _$this._effortArrets = effortArrets;

  int? _effortAttente;
  int? get effortAttente => _$this._effortAttente;
  set effortAttente(int? effortAttente) =>
      _$this._effortAttente = effortAttente;

  int? _effortPaliers;
  int? get effortPaliers => _$this._effortPaliers;
  set effortPaliers(int? effortPaliers) =>
      _$this._effortPaliers = effortPaliers;

  int? _km;
  int? get km => _$this._km;
  set km(int? km) => _$this._km = km;

  int? _retenueVendeur;
  int? get retenueVendeur => _$this._retenueVendeur;
  set retenueVendeur(int? retenueVendeur) =>
      _$this._retenueVendeur = retenueVendeur;

  int? _supplements;
  int? get supplements => _$this._supplements;
  set supplements(int? supplements) => _$this._supplements = supplements;

  ComposantesBuilder() {
    Composantes._defaults(this);
  }

  ComposantesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arrondi = $v.arrondi;
      _base_ = $v.base_;
      _effortArrets = $v.effortArrets;
      _effortAttente = $v.effortAttente;
      _effortPaliers = $v.effortPaliers;
      _km = $v.km;
      _retenueVendeur = $v.retenueVendeur;
      _supplements = $v.supplements;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Composantes other) {
    _$v = other as _$Composantes;
  }

  @override
  void update(void Function(ComposantesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Composantes build() => _build();

  _$Composantes _build() {
    final _$result = _$v ??
        _$Composantes._(
          arrondi: BuiltValueNullFieldError.checkNotNull(
              arrondi, r'Composantes', 'arrondi'),
          base_: BuiltValueNullFieldError.checkNotNull(
              base_, r'Composantes', 'base_'),
          effortArrets: BuiltValueNullFieldError.checkNotNull(
              effortArrets, r'Composantes', 'effortArrets'),
          effortAttente: BuiltValueNullFieldError.checkNotNull(
              effortAttente, r'Composantes', 'effortAttente'),
          effortPaliers: BuiltValueNullFieldError.checkNotNull(
              effortPaliers, r'Composantes', 'effortPaliers'),
          km: BuiltValueNullFieldError.checkNotNull(km, r'Composantes', 'km'),
          retenueVendeur: BuiltValueNullFieldError.checkNotNull(
              retenueVendeur, r'Composantes', 'retenueVendeur'),
          supplements: BuiltValueNullFieldError.checkNotNull(
              supplements, r'Composantes', 'supplements'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
