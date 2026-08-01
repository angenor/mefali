// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remise_bloquee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RemiseBloquee extends RemiseBloquee {
  @override
  final DateTime bloqueLe;
  @override
  final String commandeId;
  @override
  final String? coursierId;
  @override
  final int essaisCode;
  @override
  final String? livraisonId;
  @override
  final String reference;
  @override
  final String zoneId;

  factory _$RemiseBloquee([void Function(RemiseBloqueeBuilder)? updates]) =>
      (RemiseBloqueeBuilder()..update(updates))._build();

  _$RemiseBloquee._(
      {required this.bloqueLe,
      required this.commandeId,
      this.coursierId,
      required this.essaisCode,
      this.livraisonId,
      required this.reference,
      required this.zoneId})
      : super._();
  @override
  RemiseBloquee rebuild(void Function(RemiseBloqueeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RemiseBloqueeBuilder toBuilder() => RemiseBloqueeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RemiseBloquee &&
        bloqueLe == other.bloqueLe &&
        commandeId == other.commandeId &&
        coursierId == other.coursierId &&
        essaisCode == other.essaisCode &&
        livraisonId == other.livraisonId &&
        reference == other.reference &&
        zoneId == other.zoneId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, bloqueLe.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, coursierId.hashCode);
    _$hash = $jc(_$hash, essaisCode.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, reference.hashCode);
    _$hash = $jc(_$hash, zoneId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RemiseBloquee')
          ..add('bloqueLe', bloqueLe)
          ..add('commandeId', commandeId)
          ..add('coursierId', coursierId)
          ..add('essaisCode', essaisCode)
          ..add('livraisonId', livraisonId)
          ..add('reference', reference)
          ..add('zoneId', zoneId))
        .toString();
  }
}

class RemiseBloqueeBuilder
    implements Builder<RemiseBloquee, RemiseBloqueeBuilder> {
  _$RemiseBloquee? _$v;

  DateTime? _bloqueLe;
  DateTime? get bloqueLe => _$this._bloqueLe;
  set bloqueLe(DateTime? bloqueLe) => _$this._bloqueLe = bloqueLe;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _coursierId;
  String? get coursierId => _$this._coursierId;
  set coursierId(String? coursierId) => _$this._coursierId = coursierId;

  int? _essaisCode;
  int? get essaisCode => _$this._essaisCode;
  set essaisCode(int? essaisCode) => _$this._essaisCode = essaisCode;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  String? _reference;
  String? get reference => _$this._reference;
  set reference(String? reference) => _$this._reference = reference;

  String? _zoneId;
  String? get zoneId => _$this._zoneId;
  set zoneId(String? zoneId) => _$this._zoneId = zoneId;

  RemiseBloqueeBuilder() {
    RemiseBloquee._defaults(this);
  }

  RemiseBloqueeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _bloqueLe = $v.bloqueLe;
      _commandeId = $v.commandeId;
      _coursierId = $v.coursierId;
      _essaisCode = $v.essaisCode;
      _livraisonId = $v.livraisonId;
      _reference = $v.reference;
      _zoneId = $v.zoneId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RemiseBloquee other) {
    _$v = other as _$RemiseBloquee;
  }

  @override
  void update(void Function(RemiseBloqueeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RemiseBloquee build() => _build();

  _$RemiseBloquee _build() {
    final _$result = _$v ??
        _$RemiseBloquee._(
          bloqueLe: BuiltValueNullFieldError.checkNotNull(
              bloqueLe, r'RemiseBloquee', 'bloqueLe'),
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'RemiseBloquee', 'commandeId'),
          coursierId: coursierId,
          essaisCode: BuiltValueNullFieldError.checkNotNull(
              essaisCode, r'RemiseBloquee', 'essaisCode'),
          livraisonId: livraisonId,
          reference: BuiltValueNullFieldError.checkNotNull(
              reference, r'RemiseBloquee', 'reference'),
          zoneId: BuiltValueNullFieldError.checkNotNull(
              zoneId, r'RemiseBloquee', 'zoneId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
