// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_effectif_boutique.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatEffectifBoutique extends EtatEffectifBoutique {
  @override
  final bool ouvert;
  @override
  final DateTime? reouvertureEstimee;

  factory _$EtatEffectifBoutique(
          [void Function(EtatEffectifBoutiqueBuilder)? updates]) =>
      (EtatEffectifBoutiqueBuilder()..update(updates))._build();

  _$EtatEffectifBoutique._({required this.ouvert, this.reouvertureEstimee})
      : super._();
  @override
  EtatEffectifBoutique rebuild(
          void Function(EtatEffectifBoutiqueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatEffectifBoutiqueBuilder toBuilder() =>
      EtatEffectifBoutiqueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatEffectifBoutique &&
        ouvert == other.ouvert &&
        reouvertureEstimee == other.reouvertureEstimee;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, ouvert.hashCode);
    _$hash = $jc(_$hash, reouvertureEstimee.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatEffectifBoutique')
          ..add('ouvert', ouvert)
          ..add('reouvertureEstimee', reouvertureEstimee))
        .toString();
  }
}

class EtatEffectifBoutiqueBuilder
    implements Builder<EtatEffectifBoutique, EtatEffectifBoutiqueBuilder> {
  _$EtatEffectifBoutique? _$v;

  bool? _ouvert;
  bool? get ouvert => _$this._ouvert;
  set ouvert(bool? ouvert) => _$this._ouvert = ouvert;

  DateTime? _reouvertureEstimee;
  DateTime? get reouvertureEstimee => _$this._reouvertureEstimee;
  set reouvertureEstimee(DateTime? reouvertureEstimee) =>
      _$this._reouvertureEstimee = reouvertureEstimee;

  EtatEffectifBoutiqueBuilder() {
    EtatEffectifBoutique._defaults(this);
  }

  EtatEffectifBoutiqueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _ouvert = $v.ouvert;
      _reouvertureEstimee = $v.reouvertureEstimee;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatEffectifBoutique other) {
    _$v = other as _$EtatEffectifBoutique;
  }

  @override
  void update(void Function(EtatEffectifBoutiqueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatEffectifBoutique build() => _build();

  _$EtatEffectifBoutique _build() {
    final _$result = _$v ??
        _$EtatEffectifBoutique._(
          ouvert: BuiltValueNullFieldError.checkNotNull(
              ouvert, r'EtatEffectifBoutique', 'ouvert'),
          reouvertureEstimee: reouvertureEstimee,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
