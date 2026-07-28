// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reprise_faite.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$RepriseFaite extends RepriseFaite {
  @override
  final String commandeId;
  @override
  final String etatCommande;
  @override
  final String incidentId;

  factory _$RepriseFaite([void Function(RepriseFaiteBuilder)? updates]) =>
      (RepriseFaiteBuilder()..update(updates))._build();

  _$RepriseFaite._(
      {required this.commandeId,
      required this.etatCommande,
      required this.incidentId})
      : super._();
  @override
  RepriseFaite rebuild(void Function(RepriseFaiteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  RepriseFaiteBuilder toBuilder() => RepriseFaiteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is RepriseFaite &&
        commandeId == other.commandeId &&
        etatCommande == other.etatCommande &&
        incidentId == other.incidentId;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, etatCommande.hashCode);
    _$hash = $jc(_$hash, incidentId.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'RepriseFaite')
          ..add('commandeId', commandeId)
          ..add('etatCommande', etatCommande)
          ..add('incidentId', incidentId))
        .toString();
  }
}

class RepriseFaiteBuilder
    implements Builder<RepriseFaite, RepriseFaiteBuilder> {
  _$RepriseFaite? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _etatCommande;
  String? get etatCommande => _$this._etatCommande;
  set etatCommande(String? etatCommande) => _$this._etatCommande = etatCommande;

  String? _incidentId;
  String? get incidentId => _$this._incidentId;
  set incidentId(String? incidentId) => _$this._incidentId = incidentId;

  RepriseFaiteBuilder() {
    RepriseFaite._defaults(this);
  }

  RepriseFaiteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _etatCommande = $v.etatCommande;
      _incidentId = $v.incidentId;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(RepriseFaite other) {
    _$v = other as _$RepriseFaite;
  }

  @override
  void update(void Function(RepriseFaiteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  RepriseFaite build() => _build();

  _$RepriseFaite _build() {
    final _$result = _$v ??
        _$RepriseFaite._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'RepriseFaite', 'commandeId'),
          etatCommande: BuiltValueNullFieldError.checkNotNull(
              etatCommande, r'RepriseFaite', 'etatCommande'),
          incidentId: BuiltValueNullFieldError.checkNotNull(
              incidentId, r'RepriseFaite', 'incidentId'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
