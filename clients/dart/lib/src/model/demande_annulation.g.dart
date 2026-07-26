// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_annulation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeAnnulation extends DemandeAnnulation {
  @override
  final String? motifCle;

  factory _$DemandeAnnulation(
          [void Function(DemandeAnnulationBuilder)? updates]) =>
      (DemandeAnnulationBuilder()..update(updates))._build();

  _$DemandeAnnulation._({this.motifCle}) : super._();
  @override
  DemandeAnnulation rebuild(void Function(DemandeAnnulationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeAnnulationBuilder toBuilder() =>
      DemandeAnnulationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeAnnulation && motifCle == other.motifCle;
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
    return (newBuiltValueToStringHelper(r'DemandeAnnulation')
          ..add('motifCle', motifCle))
        .toString();
  }
}

class DemandeAnnulationBuilder
    implements Builder<DemandeAnnulation, DemandeAnnulationBuilder> {
  _$DemandeAnnulation? _$v;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DemandeAnnulationBuilder() {
    DemandeAnnulation._defaults(this);
  }

  DemandeAnnulationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeAnnulation other) {
    _$v = other as _$DemandeAnnulation;
  }

  @override
  void update(void Function(DemandeAnnulationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeAnnulation build() => _build();

  _$DemandeAnnulation _build() {
    final _$result = _$v ??
        _$DemandeAnnulation._(
          motifCle: motifCle,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
