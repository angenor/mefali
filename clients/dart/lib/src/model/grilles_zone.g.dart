// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grilles_zone.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$GrillesZone extends GrillesZone {
  @override
  final Grille? brouillon;
  @override
  final Grille? enVigueur;

  factory _$GrillesZone([void Function(GrillesZoneBuilder)? updates]) =>
      (GrillesZoneBuilder()..update(updates))._build();

  _$GrillesZone._({this.brouillon, this.enVigueur}) : super._();
  @override
  GrillesZone rebuild(void Function(GrillesZoneBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GrillesZoneBuilder toBuilder() => GrillesZoneBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is GrillesZone &&
        brouillon == other.brouillon &&
        enVigueur == other.enVigueur;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, brouillon.hashCode);
    _$hash = $jc(_$hash, enVigueur.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'GrillesZone')
          ..add('brouillon', brouillon)
          ..add('enVigueur', enVigueur))
        .toString();
  }
}

class GrillesZoneBuilder implements Builder<GrillesZone, GrillesZoneBuilder> {
  _$GrillesZone? _$v;

  GrilleBuilder? _brouillon;
  GrilleBuilder get brouillon => _$this._brouillon ??= GrilleBuilder();
  set brouillon(GrilleBuilder? brouillon) => _$this._brouillon = brouillon;

  GrilleBuilder? _enVigueur;
  GrilleBuilder get enVigueur => _$this._enVigueur ??= GrilleBuilder();
  set enVigueur(GrilleBuilder? enVigueur) => _$this._enVigueur = enVigueur;

  GrillesZoneBuilder() {
    GrillesZone._defaults(this);
  }

  GrillesZoneBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _brouillon = $v.brouillon?.toBuilder();
      _enVigueur = $v.enVigueur?.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(GrillesZone other) {
    _$v = other as _$GrillesZone;
  }

  @override
  void update(void Function(GrillesZoneBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  GrillesZone build() => _build();

  _$GrillesZone _build() {
    _$GrillesZone _$result;
    try {
      _$result = _$v ??
          _$GrillesZone._(
            brouillon: _brouillon?.build(),
            enVigueur: _enVigueur?.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'brouillon';
        _brouillon?.build();
        _$failedField = 'enVigueur';
        _enVigueur?.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'GrillesZone', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
