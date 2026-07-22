// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resolution_plaque.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResolutionPlaque extends ResolutionPlaque {
  @override
  final String prestataireId;
  @override
  final bool valide;

  factory _$ResolutionPlaque(
          [void Function(ResolutionPlaqueBuilder)? updates]) =>
      (ResolutionPlaqueBuilder()..update(updates))._build();

  _$ResolutionPlaque._({required this.prestataireId, required this.valide})
      : super._();
  @override
  ResolutionPlaque rebuild(void Function(ResolutionPlaqueBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResolutionPlaqueBuilder toBuilder() =>
      ResolutionPlaqueBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResolutionPlaque &&
        prestataireId == other.prestataireId &&
        valide == other.valide;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, valide.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResolutionPlaque')
          ..add('prestataireId', prestataireId)
          ..add('valide', valide))
        .toString();
  }
}

class ResolutionPlaqueBuilder
    implements Builder<ResolutionPlaque, ResolutionPlaqueBuilder> {
  _$ResolutionPlaque? _$v;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  bool? _valide;
  bool? get valide => _$this._valide;
  set valide(bool? valide) => _$this._valide = valide;

  ResolutionPlaqueBuilder() {
    ResolutionPlaque._defaults(this);
  }

  ResolutionPlaqueBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _prestataireId = $v.prestataireId;
      _valide = $v.valide;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResolutionPlaque other) {
    _$v = other as _$ResolutionPlaque;
  }

  @override
  void update(void Function(ResolutionPlaqueBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResolutionPlaque build() => _build();

  _$ResolutionPlaque _build() {
    final _$result = _$v ??
        _$ResolutionPlaque._(
          prestataireId: BuiltValueNullFieldError.checkNotNull(
              prestataireId, r'ResolutionPlaque', 'prestataireId'),
          valide: BuiltValueNullFieldError.checkNotNull(
              valide, r'ResolutionPlaque', 'valide'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
