// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_appel.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeAppel extends DemandeAppel {
  @override
  final String? issue;
  @override
  final String motif;
  @override
  final DateTime passeLeLocal;
  @override
  final String? prestataireId;
  @override
  final String uuidClient;
  @override
  final String vers;

  factory _$DemandeAppel([void Function(DemandeAppelBuilder)? updates]) =>
      (DemandeAppelBuilder()..update(updates))._build();

  _$DemandeAppel._(
      {this.issue,
      required this.motif,
      required this.passeLeLocal,
      this.prestataireId,
      required this.uuidClient,
      required this.vers})
      : super._();
  @override
  DemandeAppel rebuild(void Function(DemandeAppelBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeAppelBuilder toBuilder() => DemandeAppelBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeAppel &&
        issue == other.issue &&
        motif == other.motif &&
        passeLeLocal == other.passeLeLocal &&
        prestataireId == other.prestataireId &&
        uuidClient == other.uuidClient &&
        vers == other.vers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, passeLeLocal.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jc(_$hash, vers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeAppel')
          ..add('issue', issue)
          ..add('motif', motif)
          ..add('passeLeLocal', passeLeLocal)
          ..add('prestataireId', prestataireId)
          ..add('uuidClient', uuidClient)
          ..add('vers', vers))
        .toString();
  }
}

class DemandeAppelBuilder
    implements Builder<DemandeAppel, DemandeAppelBuilder> {
  _$DemandeAppel? _$v;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  DateTime? _passeLeLocal;
  DateTime? get passeLeLocal => _$this._passeLeLocal;
  set passeLeLocal(DateTime? passeLeLocal) =>
      _$this._passeLeLocal = passeLeLocal;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  String? _vers;
  String? get vers => _$this._vers;
  set vers(String? vers) => _$this._vers = vers;

  DemandeAppelBuilder() {
    DemandeAppel._defaults(this);
  }

  DemandeAppelBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _issue = $v.issue;
      _motif = $v.motif;
      _passeLeLocal = $v.passeLeLocal;
      _prestataireId = $v.prestataireId;
      _uuidClient = $v.uuidClient;
      _vers = $v.vers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeAppel other) {
    _$v = other as _$DemandeAppel;
  }

  @override
  void update(void Function(DemandeAppelBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeAppel build() => _build();

  _$DemandeAppel _build() {
    final _$result = _$v ??
        _$DemandeAppel._(
          issue: issue,
          motif: BuiltValueNullFieldError.checkNotNull(
              motif, r'DemandeAppel', 'motif'),
          passeLeLocal: BuiltValueNullFieldError.checkNotNull(
              passeLeLocal, r'DemandeAppel', 'passeLeLocal'),
          prestataireId: prestataireId,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandeAppel', 'uuidClient'),
          vers: BuiltValueNullFieldError.checkNotNull(
              vers, r'DemandeAppel', 'vers'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
