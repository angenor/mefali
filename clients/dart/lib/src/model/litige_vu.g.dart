// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'litige_vu.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$LitigeVu extends LitigeVu {
  @override
  final String commandeId;
  @override
  final String etatCle;
  @override
  final String id;
  @override
  final int montantUnites;
  @override
  final DateTime ouvertLe;
  @override
  final String reference;

  factory _$LitigeVu([void Function(LitigeVuBuilder)? updates]) =>
      (LitigeVuBuilder()..update(updates))._build();

  _$LitigeVu._(
      {required this.commandeId,
      required this.etatCle,
      required this.id,
      required this.montantUnites,
      required this.ouvertLe,
      required this.reference})
      : super._();
  @override
  LitigeVu rebuild(void Function(LitigeVuBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  LitigeVuBuilder toBuilder() => LitigeVuBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is LitigeVu &&
        commandeId == other.commandeId &&
        etatCle == other.etatCle &&
        id == other.id &&
        montantUnites == other.montantUnites &&
        ouvertLe == other.ouvertLe &&
        reference == other.reference;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, etatCle.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, ouvertLe.hashCode);
    _$hash = $jc(_$hash, reference.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'LitigeVu')
          ..add('commandeId', commandeId)
          ..add('etatCle', etatCle)
          ..add('id', id)
          ..add('montantUnites', montantUnites)
          ..add('ouvertLe', ouvertLe)
          ..add('reference', reference))
        .toString();
  }
}

class LitigeVuBuilder implements Builder<LitigeVu, LitigeVuBuilder> {
  _$LitigeVu? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _etatCle;
  String? get etatCle => _$this._etatCle;
  set etatCle(String? etatCle) => _$this._etatCle = etatCle;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  DateTime? _ouvertLe;
  DateTime? get ouvertLe => _$this._ouvertLe;
  set ouvertLe(DateTime? ouvertLe) => _$this._ouvertLe = ouvertLe;

  String? _reference;
  String? get reference => _$this._reference;
  set reference(String? reference) => _$this._reference = reference;

  LitigeVuBuilder() {
    LitigeVu._defaults(this);
  }

  LitigeVuBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _etatCle = $v.etatCle;
      _id = $v.id;
      _montantUnites = $v.montantUnites;
      _ouvertLe = $v.ouvertLe;
      _reference = $v.reference;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(LitigeVu other) {
    _$v = other as _$LitigeVu;
  }

  @override
  void update(void Function(LitigeVuBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  LitigeVu build() => _build();

  _$LitigeVu _build() {
    final _$result = _$v ??
        _$LitigeVu._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'LitigeVu', 'commandeId'),
          etatCle: BuiltValueNullFieldError.checkNotNull(
              etatCle, r'LitigeVu', 'etatCle'),
          id: BuiltValueNullFieldError.checkNotNull(id, r'LitigeVu', 'id'),
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'LitigeVu', 'montantUnites'),
          ouvertLe: BuiltValueNullFieldError.checkNotNull(
              ouvertLe, r'LitigeVu', 'ouvertLe'),
          reference: BuiltValueNullFieldError.checkNotNull(
              reference, r'LitigeVu', 'reference'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
