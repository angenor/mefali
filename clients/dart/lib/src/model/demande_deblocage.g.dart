// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_deblocage.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeDeblocage extends DemandeDeblocage {
  @override
  final String motifCle;

  factory _$DemandeDeblocage(
          [void Function(DemandeDeblocageBuilder)? updates]) =>
      (DemandeDeblocageBuilder()..update(updates))._build();

  _$DemandeDeblocage._({required this.motifCle}) : super._();
  @override
  DemandeDeblocage rebuild(void Function(DemandeDeblocageBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeDeblocageBuilder toBuilder() =>
      DemandeDeblocageBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeDeblocage && motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeDeblocage')
          ..add('motifCle', motifCle))
        .toString();
  }
}

class DemandeDeblocageBuilder
    implements Builder<DemandeDeblocage, DemandeDeblocageBuilder> {
  _$DemandeDeblocage? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DemandeDeblocageBuilder() {
    DemandeDeblocage._defaults(this);
  }

  DemandeDeblocageBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeDeblocage other) {
    _$v = other as _$DemandeDeblocage;
  }

  @override
  void update(void Function(DemandeDeblocageBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeDeblocage build() => _build();

  _$DemandeDeblocage _build() {
    final _$result = _$v ??
        _$DemandeDeblocage._(
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DemandeDeblocage', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
