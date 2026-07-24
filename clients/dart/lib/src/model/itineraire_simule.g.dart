// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'itineraire_simule.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ItineraireSimule extends ItineraireSimule {
  @override
  final bool degraded;
  @override
  final int distanceM;
  @override
  final int etaS;
  @override
  final bool exhaustif;
  @override
  final BuiltList<int> ordre;

  factory _$ItineraireSimule(
          [void Function(ItineraireSimuleBuilder)? updates]) =>
      (ItineraireSimuleBuilder()..update(updates))._build();

  _$ItineraireSimule._(
      {required this.degraded,
      required this.distanceM,
      required this.etaS,
      required this.exhaustif,
      required this.ordre})
      : super._();
  @override
  ItineraireSimule rebuild(void Function(ItineraireSimuleBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ItineraireSimuleBuilder toBuilder() =>
      ItineraireSimuleBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ItineraireSimule &&
        degraded == other.degraded &&
        distanceM == other.distanceM &&
        etaS == other.etaS &&
        exhaustif == other.exhaustif &&
        ordre == other.ordre;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, etaS.hashCode);
    _$hash = $jc(_$hash, exhaustif.hashCode);
    _$hash = $jc(_$hash, ordre.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ItineraireSimule')
          ..add('degraded', degraded)
          ..add('distanceM', distanceM)
          ..add('etaS', etaS)
          ..add('exhaustif', exhaustif)
          ..add('ordre', ordre))
        .toString();
  }
}

class ItineraireSimuleBuilder
    implements Builder<ItineraireSimule, ItineraireSimuleBuilder> {
  _$ItineraireSimule? _$v;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  int? _etaS;
  int? get etaS => _$this._etaS;
  set etaS(int? etaS) => _$this._etaS = etaS;

  bool? _exhaustif;
  bool? get exhaustif => _$this._exhaustif;
  set exhaustif(bool? exhaustif) => _$this._exhaustif = exhaustif;

  ListBuilder<int>? _ordre;
  ListBuilder<int> get ordre => _$this._ordre ??= ListBuilder<int>();
  set ordre(ListBuilder<int>? ordre) => _$this._ordre = ordre;

  ItineraireSimuleBuilder() {
    ItineraireSimule._defaults(this);
  }

  ItineraireSimuleBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _degraded = $v.degraded;
      _distanceM = $v.distanceM;
      _etaS = $v.etaS;
      _exhaustif = $v.exhaustif;
      _ordre = $v.ordre.toBuilder();
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ItineraireSimule other) {
    _$v = other as _$ItineraireSimule;
  }

  @override
  void update(void Function(ItineraireSimuleBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ItineraireSimule build() => _build();

  _$ItineraireSimule _build() {
    _$ItineraireSimule _$result;
    try {
      _$result = _$v ??
          _$ItineraireSimule._(
            degraded: BuiltValueNullFieldError.checkNotNull(
                degraded, r'ItineraireSimule', 'degraded'),
            distanceM: BuiltValueNullFieldError.checkNotNull(
                distanceM, r'ItineraireSimule', 'distanceM'),
            etaS: BuiltValueNullFieldError.checkNotNull(
                etaS, r'ItineraireSimule', 'etaS'),
            exhaustif: BuiltValueNullFieldError.checkNotNull(
                exhaustif, r'ItineraireSimule', 'exhaustif'),
            ordre: ordre.build(),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'ordre';
        ordre.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'ItineraireSimule', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
