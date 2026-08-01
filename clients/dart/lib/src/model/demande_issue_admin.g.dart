// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_issue_admin.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeIssueAdmin extends DemandeIssueAdmin {
  @override
  final String? arretId;
  @override
  final String motifCle;
  @override
  final String typeIssue;

  factory _$DemandeIssueAdmin(
          [void Function(DemandeIssueAdminBuilder)? updates]) =>
      (DemandeIssueAdminBuilder()..update(updates))._build();

  _$DemandeIssueAdmin._(
      {this.arretId, required this.motifCle, required this.typeIssue})
      : super._();
  @override
  DemandeIssueAdmin rebuild(void Function(DemandeIssueAdminBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeIssueAdminBuilder toBuilder() =>
      DemandeIssueAdminBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeIssueAdmin &&
        arretId == other.arretId &&
        motifCle == other.motifCle &&
        typeIssue == other.typeIssue;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, typeIssue.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeIssueAdmin')
          ..add('arretId', arretId)
          ..add('motifCle', motifCle)
          ..add('typeIssue', typeIssue))
        .toString();
  }
}

class DemandeIssueAdminBuilder
    implements Builder<DemandeIssueAdmin, DemandeIssueAdminBuilder> {
  _$DemandeIssueAdmin? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  String? _typeIssue;
  String? get typeIssue => _$this._typeIssue;
  set typeIssue(String? typeIssue) => _$this._typeIssue = typeIssue;

  DemandeIssueAdminBuilder() {
    DemandeIssueAdmin._defaults(this);
  }

  DemandeIssueAdminBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _motifCle = $v.motifCle;
      _typeIssue = $v.typeIssue;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeIssueAdmin other) {
    _$v = other as _$DemandeIssueAdmin;
  }

  @override
  void update(void Function(DemandeIssueAdminBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeIssueAdmin build() => _build();

  _$DemandeIssueAdmin _build() {
    final _$result = _$v ??
        _$DemandeIssueAdmin._(
          arretId: arretId,
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DemandeIssueAdmin', 'motifCle'),
          typeIssue: BuiltValueNullFieldError.checkNotNull(
              typeIssue, r'DemandeIssueAdmin', 'typeIssue'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
