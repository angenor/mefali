// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grille.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Grille extends Grille {
  @override
  final DateTime? effetLe;
  @override
  final String etat;
  @override
  final String id;
  @override
  final BuiltList<Regle> regles;
  @override
  final bool simulee;
  @override
  final DateTime? simuleeLe;
  @override
  final int version;
  @override
  final String zoneId;

  factory _$Grille([void Function(GrilleBuilder)? updates]) =>
      (GrilleBuilder()..update(updates))._build();

  _$Grille._(
      {this.effetLe,
      required this.etat,
      required this.id,
      required this.regles,
      required this.simulee,
      this.simuleeLe,
      required this.version,
      required this.zoneId})
      : super._();
  @override
  Grille rebuild(void Function(GrilleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  GrilleBuilder toBuilder() => GrilleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Grille &&
        effetLe == other.effetLe &&
        etat == other.etat &&
        id == other.id &&
        regles == other.regles &&
        simulee == other.simulee &&
        simuleeLe == other.simuleeLe &&
        version == other.version &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, effetLe.hashCode);
    _$hash = $jc(_$hash, etat.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, regles.hashCode);
    _$hash = $jc(_$hash, simulee.hashCode);
    _$hash = $jc(_$hash, simuleeLe.hashCode);
    _$hash = $jc(_$hash, version.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Grille')
          ..add('effetLe', effetLe)
          ..add('etat', etat)
          ..add('id', id)
          ..add('regles', regles)
          ..add('simulee', simulee)
          ..add('simuleeLe', simuleeLe)
          ..add('version', version)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class GrilleBuilder implements Builder<Grille, GrilleBuilder> {
  _$Grille? _$v;

  DateTime? _effetLe;
  DateTime? get effetLe => _$this._effetLe;
  set effetLe(DateTime? effetLe) => _$this._effetLe = effetLe;

  String? _etat;
  String? get etat => _$this._etat;
  set etat(String? etat) => _$this._etat = etat;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  ListBuilder<Regle>? _regles;
  ListBuilder<Regle> get regles => _$this._regles ??= ListBuilder<Regle>();
  set regles(ListBuilder<Regle>? regles) => _$this._regles = regles;

  bool? _simulee;
  bool? get simulee => _$this._simulee;
  set simulee(bool? simulee) => _$this._simulee = simulee;

  DateTime? _simuleeLe;
  DateTime? get simuleeLe => _$this._simuleeLe;
  set simuleeLe(DateTime? simuleeLe) => _$this._simuleeLe = simuleeLe;

  int? _version;
  int? get version => _$this._version;
  set version(int? version) => _$this._version = version;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  GrilleBuilder() {
    Grille._defaults(this);
  }

  GrilleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _effetLe = $v.effetLe;
      _etat = $v.etat;
      _id = $v.id;
      _regles = $v.regles.toBuilder();
      _simulee = $v.simulee;
      _simuleeLe = $v.simuleeLe;
      _version = $v.version;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Grille other) {
    _$v = other as _$Grille;
  }

  @override
  void update(void Function(GrilleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Grille build() => _build();

  _$Grille _build() {
    _$Grille _$result;
    try {
      _$result = _$v ??
          _$Grille._(
            effetLe: effetLe,
            etat:
                BuiltValueNullFieldError.checkNotNull(etat, r'Grille', 'etat'),
            id: BuiltValueNullFieldError.checkNotNull(id, r'Grille', 'id'),
            regles: regles.build(),
            simulee: BuiltValueNullFieldError.checkNotNull(
                simulee, r'Grille', 'simulee'),
            simuleeLe: simuleeLe,
            version: BuiltValueNullFieldError.checkNotNull(
                version, r'Grille', 'version'),
            zoneId: BuiltValueNullFieldError.checkNotNull(
                zoneId, r'Grille', 'zoneId'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'regles';
        regles.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'Grille', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
