// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offre_courante.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$OffreCourante extends OffreCourante {
  @override
  final BuiltList<ArretOffre> arrets;
  @override
  final AvanceOffre avance;
  @override
  final String commandeId;
  @override
  final bool degraded;
  @override
  final DestinationOffre destination;
  @override
  final DateTime echeanceLe;
  @override
  final GainOffre gain;
  @override
  final String mode;
  @override
  final String offreId;
  @override
  final int restantS;
  @override
  final int timerS;

  factory _$OffreCourante([void Function(OffreCouranteBuilder)? updates]) =>
      (OffreCouranteBuilder()..update(updates))._build();

  _$OffreCourante._(
      {required this.arrets,
      required this.avance,
      required this.commandeId,
      required this.degraded,
      required this.destination,
      required this.echeanceLe,
      required this.gain,
      required this.mode,
      required this.offreId,
      required this.restantS,
      required this.timerS})
      : super._();
  @override
  OffreCourante rebuild(void Function(OffreCouranteBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  OffreCouranteBuilder toBuilder() => OffreCouranteBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is OffreCourante &&
        arrets == other.arrets &&
        avance == other.avance &&
        commandeId == other.commandeId &&
        degraded == other.degraded &&
        destination == other.destination &&
        echeanceLe == other.echeanceLe &&
        gain == other.gain &&
        mode == other.mode &&
        offreId == other.offreId &&
        restantS == other.restantS &&
        timerS == other.timerS;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arrets.hashCode);
    _$hash = $jc(_$hash, avance.hashCode);
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, destination.hashCode);
    _$hash = $jc(_$hash, echeanceLe.hashCode);
    _$hash = $jc(_$hash, gain.hashCode);
    _$hash = $jc(_$hash, mode.hashCode);
    _$hash = $jc(_$hash, offreId.hashCode);
    _$hash = $jc(_$hash, restantS.hashCode);
    _$hash = $jc(_$hash, timerS.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'OffreCourante')
          ..add('arrets', arrets)
          ..add('avance', avance)
          ..add('commandeId', commandeId)
          ..add('degraded', degraded)
          ..add('destination', destination)
          ..add('echeanceLe', echeanceLe)
          ..add('gain', gain)
          ..add('mode', mode)
          ..add('offreId', offreId)
          ..add('restantS', restantS)
          ..add('timerS', timerS))
        .toString();
  }
}

class OffreCouranteBuilder
    implements Builder<OffreCourante, OffreCouranteBuilder> {
  _$OffreCourante? _$v;

  ListBuilder<ArretOffre>? _arrets;
  ListBuilder<ArretOffre> get arrets =>
      _$this._arrets ??= ListBuilder<ArretOffre>();
  set arrets(ListBuilder<ArretOffre>? arrets) => _$this._arrets = arrets;

  AvanceOffreBuilder? _avance;
  AvanceOffreBuilder get avance => _$this._avance ??= AvanceOffreBuilder();
  set avance(AvanceOffreBuilder? avance) => _$this._avance = avance;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  DestinationOffreBuilder? _destination;
  DestinationOffreBuilder get destination =>
      _$this._destination ??= DestinationOffreBuilder();
  set destination(DestinationOffreBuilder? destination) =>
      _$this._destination = destination;

  DateTime? _echeanceLe;
  DateTime? get echeanceLe => _$this._echeanceLe;
  set echeanceLe(DateTime? echeanceLe) => _$this._echeanceLe = echeanceLe;

  GainOffreBuilder? _gain;
  GainOffreBuilder get gain => _$this._gain ??= GainOffreBuilder();
  set gain(GainOffreBuilder? gain) => _$this._gain = gain;

  String? _mode;
  String? get mode => _$this._mode;
  set mode(String? mode) => _$this._mode = mode;

  String? _offreId;
  String? get offreId => _$this._offreId;
  set offreId(String? offreId) => _$this._offreId = offreId;

  int? _restantS;
  int? get restantS => _$this._restantS;
  set restantS(int? restantS) => _$this._restantS = restantS;

  int? _timerS;
  int? get timerS => _$this._timerS;
  set timerS(int? timerS) => _$this._timerS = timerS;

  OffreCouranteBuilder() {
    OffreCourante._defaults(this);
  }

  OffreCouranteBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arrets = $v.arrets.toBuilder();
      _avance = $v.avance.toBuilder();
      _commandeId = $v.commandeId;
      _degraded = $v.degraded;
      _destination = $v.destination.toBuilder();
      _echeanceLe = $v.echeanceLe;
      _gain = $v.gain.toBuilder();
      _mode = $v.mode;
      _offreId = $v.offreId;
      _restantS = $v.restantS;
      _timerS = $v.timerS;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(OffreCourante other) {
    _$v = other as _$OffreCourante;
  }

  @override
  void update(void Function(OffreCouranteBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  OffreCourante build() => _build();

  _$OffreCourante _build() {
    _$OffreCourante _$result;
    try {
      _$result = _$v ??
          _$OffreCourante._(
            arrets: arrets.build(),
            avance: avance.build(),
            commandeId: BuiltValueNullFieldError.checkNotNull(
                commandeId, r'OffreCourante', 'commandeId'),
            degraded: BuiltValueNullFieldError.checkNotNull(
                degraded, r'OffreCourante', 'degraded'),
            destination: destination.build(),
            echeanceLe: BuiltValueNullFieldError.checkNotNull(
                echeanceLe, r'OffreCourante', 'echeanceLe'),
            gain: gain.build(),
            mode: BuiltValueNullFieldError.checkNotNull(
                mode, r'OffreCourante', 'mode'),
            offreId: BuiltValueNullFieldError.checkNotNull(
                offreId, r'OffreCourante', 'offreId'),
            restantS: BuiltValueNullFieldError.checkNotNull(
                restantS, r'OffreCourante', 'restantS'),
            timerS: BuiltValueNullFieldError.checkNotNull(
                timerS, r'OffreCourante', 'timerS'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'arrets';
        arrets.build();
        _$failedField = 'avance';
        avance.build();

        _$failedField = 'destination';
        destination.build();

        _$failedField = 'gain';
        gain.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'OffreCourante', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
