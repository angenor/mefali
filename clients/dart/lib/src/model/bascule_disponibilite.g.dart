// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bascule_disponibilite.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BasculeDisponibilite extends BasculeDisponibilite {
  @override
  final bool enLigne;
  @override
  final int? plafondDeclareUnites;

  factory _$BasculeDisponibilite(
          [void Function(BasculeDisponibiliteBuilder)? updates]) =>
      (BasculeDisponibiliteBuilder()..update(updates))._build();

  _$BasculeDisponibilite._({required this.enLigne, this.plafondDeclareUnites})
      : super._();
  @override
  BasculeDisponibilite rebuild(
          void Function(BasculeDisponibiliteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BasculeDisponibiliteBuilder toBuilder() =>
      BasculeDisponibiliteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BasculeDisponibilite &&
        enLigne == other.enLigne &&
        plafondDeclareUnites == other.plafondDeclareUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, enLigne.hashCode);
    _$hash = $jc(_$hash, plafondDeclareUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BasculeDisponibilite')
          ..add('enLigne', enLigne)
          ..add('plafondDeclareUnites', plafondDeclareUnites))
        .toString();
  }
}

class BasculeDisponibiliteBuilder
    implements Builder<BasculeDisponibilite, BasculeDisponibiliteBuilder> {
  _$BasculeDisponibilite? _$v;

  bool? _enLigne;
  bool? get enLigne => _$this._enLigne;
  set enLigne(bool? enLigne) => _$this._enLigne = enLigne;

  int? _plafondDeclareUnites;
  int? get plafondDeclareUnites => _$this._plafondDeclareUnites;
  set plafondDeclareUnites(int? plafondDeclareUnites) =>
      _$this._plafondDeclareUnites = plafondDeclareUnites;

  BasculeDisponibiliteBuilder() {
    BasculeDisponibilite._defaults(this);
  }

  BasculeDisponibiliteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _enLigne = $v.enLigne;
      _plafondDeclareUnites = $v.plafondDeclareUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BasculeDisponibilite other) {
    _$v = other as _$BasculeDisponibilite;
  }

  @override
  void update(void Function(BasculeDisponibiliteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BasculeDisponibilite build() => _build();

  _$BasculeDisponibilite _build() {
    final _$result = _$v ??
        _$BasculeDisponibilite._(
          enLigne: BuiltValueNullFieldError.checkNotNull(
              enLigne, r'BasculeDisponibilite', 'enLigne'),
          plafondDeclareUnites: plafondDeclareUnites,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
