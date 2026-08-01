// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appel_journalise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppelJournalise extends AppelJournalise {
  @override
  final String id;
  @override
  final String issue;
  @override
  final String motif;
  @override
  final DateTime passeLe;
  @override
  final DateTime passeLeLocal;
  @override
  final String? prestataireId;
  @override
  final String vers;

  factory _$AppelJournalise([void Function(AppelJournaliseBuilder)? updates]) =>
      (AppelJournaliseBuilder()..update(updates))._build();

  _$AppelJournalise._(
      {required this.id,
      required this.issue,
      required this.motif,
      required this.passeLe,
      required this.passeLeLocal,
      this.prestataireId,
      required this.vers})
      : super._();
  @override
  AppelJournalise rebuild(void Function(AppelJournaliseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppelJournaliseBuilder toBuilder() => AppelJournaliseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppelJournalise &&
        id == other.id &&
        issue == other.issue &&
        motif == other.motif &&
        passeLe == other.passeLe &&
        passeLeLocal == other.passeLeLocal &&
        prestataireId == other.prestataireId &&
        vers == other.vers;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, issue.hashCode);
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, passeLe.hashCode);
    _$hash = $jc(_$hash, passeLeLocal.hashCode);
    _$hash = $jc(_$hash, prestataireId.hashCode);
    _$hash = $jc(_$hash, vers.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppelJournalise')
          ..add('id', id)
          ..add('issue', issue)
          ..add('motif', motif)
          ..add('passeLe', passeLe)
          ..add('passeLeLocal', passeLeLocal)
          ..add('prestataireId', prestataireId)
          ..add('vers', vers))
        .toString();
  }
}

class AppelJournaliseBuilder
    implements Builder<AppelJournalise, AppelJournaliseBuilder> {
  _$AppelJournalise? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  String? _issue;
  String? get issue => _$this._issue;
  set issue(String? issue) => _$this._issue = issue;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  DateTime? _passeLe;
  DateTime? get passeLe => _$this._passeLe;
  set passeLe(DateTime? passeLe) => _$this._passeLe = passeLe;

  DateTime? _passeLeLocal;
  DateTime? get passeLeLocal => _$this._passeLeLocal;
  set passeLeLocal(DateTime? passeLeLocal) =>
      _$this._passeLeLocal = passeLeLocal;

  String? _prestataireId;
  String? get prestataireId => _$this._prestataireId;
  set prestataireId(String? prestataireId) =>
      _$this._prestataireId = prestataireId;

  String? _vers;
  String? get vers => _$this._vers;
  set vers(String? vers) => _$this._vers = vers;

  AppelJournaliseBuilder() {
    AppelJournalise._defaults(this);
  }

  AppelJournaliseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _issue = $v.issue;
      _motif = $v.motif;
      _passeLe = $v.passeLe;
      _passeLeLocal = $v.passeLeLocal;
      _prestataireId = $v.prestataireId;
      _vers = $v.vers;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppelJournalise other) {
    _$v = other as _$AppelJournalise;
  }

  @override
  void update(void Function(AppelJournaliseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppelJournalise build() => _build();

  _$AppelJournalise _build() {
    final _$result = _$v ??
        _$AppelJournalise._(
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'AppelJournalise', 'id'),
          issue: BuiltValueNullFieldError.checkNotNull(
              issue, r'AppelJournalise', 'issue'),
          motif: BuiltValueNullFieldError.checkNotNull(
              motif, r'AppelJournalise', 'motif'),
          passeLe: BuiltValueNullFieldError.checkNotNull(
              passeLe, r'AppelJournalise', 'passeLe'),
          passeLeLocal: BuiltValueNullFieldError.checkNotNull(
              passeLeLocal, r'AppelJournalise', 'passeLeLocal'),
          prestataireId: prestataireId,
          vers: BuiltValueNullFieldError.checkNotNull(
              vers, r'AppelJournalise', 'vers'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
