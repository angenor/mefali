// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_reprise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeReprise extends DemandeReprise {
  @override
  final String motif;

  factory _$DemandeReprise([void Function(DemandeRepriseBuilder)? updates]) =>
      (DemandeRepriseBuilder()..update(updates))._build();

  _$DemandeReprise._({required this.motif}) : super._();
  @override
  DemandeReprise rebuild(void Function(DemandeRepriseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeRepriseBuilder toBuilder() => DemandeRepriseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeReprise && motif == other.motif;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeReprise')..add('motif', motif))
        .toString();
  }
}

class DemandeRepriseBuilder
    implements Builder<DemandeReprise, DemandeRepriseBuilder> {
  _$DemandeReprise? _$v;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  DemandeRepriseBuilder() {
    DemandeReprise._defaults(this);
  }

  DemandeRepriseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motif = $v.motif;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeReprise other) {
    _$v = other as _$DemandeReprise;
  }

  @override
  void update(void Function(DemandeRepriseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeReprise build() => _build();

  _$DemandeReprise _build() {
    final _$result = _$v ??
        _$DemandeReprise._(
          motif: BuiltValueNullFieldError.checkNotNull(
              motif, r'DemandeReprise', 'motif'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
