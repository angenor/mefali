// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_depot.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeDepot extends DemandeDepot {
  @override
  final bool autorise;
  @override
  final String motifCle;

  factory _$DemandeDepot([void Function(DemandeDepotBuilder)? updates]) =>
      (DemandeDepotBuilder()..update(updates))._build();

  _$DemandeDepot._({required this.autorise, required this.motifCle})
      : super._();
  @override
  DemandeDepot rebuild(void Function(DemandeDepotBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeDepotBuilder toBuilder() => DemandeDepotBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeDepot &&
        autorise == other.autorise &&
        motifCle == other.motifCle;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, autorise.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeDepot')
          ..add('autorise', autorise)
          ..add('motifCle', motifCle))
        .toString();
  }
}

class DemandeDepotBuilder
    implements Builder<DemandeDepot, DemandeDepotBuilder> {
  _$DemandeDepot? _$v;

  bool? _autorise;
  bool? get autorise => _$this._autorise;
  set autorise(bool? autorise) => _$this._autorise = autorise;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  DemandeDepotBuilder() {
    DemandeDepot._defaults(this);
  }

  DemandeDepotBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _autorise = $v.autorise;
      _motifCle = $v.motifCle;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeDepot other) {
    _$v = other as _$DemandeDepot;
  }

  @override
  void update(void Function(DemandeDepotBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeDepot build() => _build();

  _$DemandeDepot _build() {
    final _$result = _$v ??
        _$DemandeDepot._(
          autorise: BuiltValueNullFieldError.checkNotNull(
              autorise, r'DemandeDepot', 'autorise'),
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DemandeDepot', 'motifCle'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
