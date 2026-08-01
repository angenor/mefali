// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preuve_appels.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PreuveAppels extends PreuveAppels {
  @override
  final bool espacementOk;
  @override
  final int faits;
  @override
  final BuiltList<DateTime> horodatages;
  @override
  final BuiltList<String> issues;
  @override
  final String? motifCle;
  @override
  final bool ok;
  @override
  final int requis;

  factory _$PreuveAppels([void Function(PreuveAppelsBuilder)? updates]) =>
      (PreuveAppelsBuilder()..update(updates))._build();

  _$PreuveAppels._(
      {required this.espacementOk,
      required this.faits,
      required this.horodatages,
      required this.issues,
      this.motifCle,
      required this.ok,
      required this.requis})
      : super._();
  @override
  PreuveAppels rebuild(void Function(PreuveAppelsBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreuveAppelsBuilder toBuilder() => PreuveAppelsBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PreuveAppels &&
        espacementOk == other.espacementOk &&
        faits == other.faits &&
        horodatages == other.horodatages &&
        issues == other.issues &&
        motifCle == other.motifCle &&
        ok == other.ok &&
        requis == other.requis;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, espacementOk.hashCode);
    _$hash = $jc(_$hash, faits.hashCode);
    _$hash = $jc(_$hash, horodatages.hashCode);
    _$hash = $jc(_$hash, issues.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, requis.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PreuveAppels')
          ..add('espacementOk', espacementOk)
          ..add('faits', faits)
          ..add('horodatages', horodatages)
          ..add('issues', issues)
          ..add('motifCle', motifCle)
          ..add('ok', ok)
          ..add('requis', requis))
        .toString();
  }
}

class PreuveAppelsBuilder
    implements Builder<PreuveAppels, PreuveAppelsBuilder> {
  _$PreuveAppels? _$v;

  bool? _espacementOk;
  bool? get espacementOk => _$this._espacementOk;
  set espacementOk(bool? espacementOk) => _$this._espacementOk = espacementOk;

  int? _faits;
  int? get faits => _$this._faits;
  set faits(int? faits) => _$this._faits = faits;

  ListBuilder<DateTime>? _horodatages;
  ListBuilder<DateTime> get horodatages =>
      _$this._horodatages ??= ListBuilder<DateTime>();
  set horodatages(ListBuilder<DateTime>? horodatages) =>
      _$this._horodatages = horodatages;

  ListBuilder<String>? _issues;
  ListBuilder<String> get issues => _$this._issues ??= ListBuilder<String>();
  set issues(ListBuilder<String>? issues) => _$this._issues = issues;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  int? _requis;
  int? get requis => _$this._requis;
  set requis(int? requis) => _$this._requis = requis;

  PreuveAppelsBuilder() {
    PreuveAppels._defaults(this);
  }

  PreuveAppelsBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _espacementOk = $v.espacementOk;
      _faits = $v.faits;
      _horodatages = $v.horodatages.toBuilder();
      _issues = $v.issues.toBuilder();
      _motifCle = $v.motifCle;
      _ok = $v.ok;
      _requis = $v.requis;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PreuveAppels other) {
    _$v = other as _$PreuveAppels;
  }

  @override
  void update(void Function(PreuveAppelsBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PreuveAppels build() => _build();

  _$PreuveAppels _build() {
    _$PreuveAppels _$result;
    try {
      _$result = _$v ??
          _$PreuveAppels._(
            espacementOk: BuiltValueNullFieldError.checkNotNull(
                espacementOk, r'PreuveAppels', 'espacementOk'),
            faits: BuiltValueNullFieldError.checkNotNull(
                faits, r'PreuveAppels', 'faits'),
            horodatages: horodatages.build(),
            issues: issues.build(),
            motifCle: motifCle,
            ok: BuiltValueNullFieldError.checkNotNull(
                ok, r'PreuveAppels', 'ok'),
            requis: BuiltValueNullFieldError.checkNotNull(
                requis, r'PreuveAppels', 'requis'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'horodatages';
        horodatages.build();
        _$failedField = 'issues';
        issues.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'PreuveAppels', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
