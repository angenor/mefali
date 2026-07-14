// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_role_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatRoleDto extends EtatRoleDto {
  @override
  final DateTime? decideLe;
  @override
  final String? motif;
  @override
  final String role;
  @override
  final String statut;

  factory _$EtatRoleDto([void Function(EtatRoleDtoBuilder)? updates]) =>
      (EtatRoleDtoBuilder()..update(updates))._build();

  _$EtatRoleDto._(
      {this.decideLe, this.motif, required this.role, required this.statut})
      : super._();
  @override
  EtatRoleDto rebuild(void Function(EtatRoleDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatRoleDtoBuilder toBuilder() => EtatRoleDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatRoleDto &&
        decideLe == other.decideLe &&
        motif == other.motif &&
        role == other.role &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, decideLe.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, role.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatRoleDto')
          ..add('decideLe', decideLe)
          ..add('motif', motif)
          ..add('role', role)
          ..add('statut', statut))
        .toString();
  }
}

class EtatRoleDtoBuilder implements Builder<EtatRoleDto, EtatRoleDtoBuilder> {
  _$EtatRoleDto? _$v;

  DateTime? _decideLe;
  DateTime? get decideLe => _$this._decideLe;
  set decideLe(DateTime? decideLe) => _$this._decideLe = decideLe;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  String? _role;
  String? get role => _$this._role;
  set role(String? role) => _$this._role = role;

  String? _statut;
  String? get statut => _$this._statut;
  set statut(String? statut) => _$this._statut = statut;

  EtatRoleDtoBuilder() {
    EtatRoleDto._defaults(this);
  }

  EtatRoleDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _decideLe = $v.decideLe;
      _motif = $v.motif;
      _role = $v.role;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatRoleDto other) {
    _$v = other as _$EtatRoleDto;
  }

  @override
  void update(void Function(EtatRoleDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatRoleDto build() => _build();

  _$EtatRoleDto _build() {
    final _$result = _$v ??
        _$EtatRoleDto._(
          decideLe: decideLe,
          motif: motif,
          role: BuiltValueNullFieldError.checkNotNull(
              role, r'EtatRoleDto', 'role'),
          statut: BuiltValueNullFieldError.checkNotNull(
              statut, r'EtatRoleDto', 'statut'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
