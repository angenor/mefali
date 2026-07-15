// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modifier_adresse.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ModifierAdresse extends ModifierAdresse {
  @override
  final String? libelle;
  @override
  final String? repereTexte;

  factory _$ModifierAdresse([void Function(ModifierAdresseBuilder)? updates]) =>
      (ModifierAdresseBuilder()..update(updates))._build();

  _$ModifierAdresse._({this.libelle, this.repereTexte}) : super._();
  @override
  ModifierAdresse rebuild(void Function(ModifierAdresseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ModifierAdresseBuilder toBuilder() => ModifierAdresseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ModifierAdresse &&
        libelle == other.libelle &&
        repereTexte == other.repereTexte;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, libelle.hashCode);
    _$hash = $jc(_$hash, repereTexte.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ModifierAdresse')
          ..add('libelle', libelle)
          ..add('repereTexte', repereTexte))
        .toString();
  }
}

class ModifierAdresseBuilder
    implements Builder<ModifierAdresse, ModifierAdresseBuilder> {
  _$ModifierAdresse? _$v;

  String? _libelle;
  String? get libelle => _$this._libelle;
  set libelle(String? libelle) => _$this._libelle = libelle;

  String? _repereTexte;
  String? get repereTexte => _$this._repereTexte;
  set repereTexte(String? repereTexte) => _$this._repereTexte = repereTexte;

  ModifierAdresseBuilder() {
    ModifierAdresse._defaults(this);
  }

  ModifierAdresseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _libelle = $v.libelle;
      _repereTexte = $v.repereTexte;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ModifierAdresse other) {
    _$v = other as _$ModifierAdresse;
  }

  @override
  void update(void Function(ModifierAdresseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ModifierAdresse build() => _build();

  _$ModifierAdresse _build() {
    final _$result = _$v ??
        _$ModifierAdresse._(
          libelle: libelle,
          repereTexte: repereTexte,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
