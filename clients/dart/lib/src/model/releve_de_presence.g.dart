// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'releve_de_presence.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReleveDePresence extends ReleveDePresence {
  @override
  final int distanceM;
  @override
  final DateTime releveLeLocal;
  @override
  final String uuidClient;

  factory _$ReleveDePresence(
          [void Function(ReleveDePresenceBuilder)? updates]) =>
      (ReleveDePresenceBuilder()..update(updates))._build();

  _$ReleveDePresence._(
      {required this.distanceM,
      required this.releveLeLocal,
      required this.uuidClient})
      : super._();
  @override
  ReleveDePresence rebuild(void Function(ReleveDePresenceBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReleveDePresenceBuilder toBuilder() =>
      ReleveDePresenceBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReleveDePresence &&
        distanceM == other.distanceM &&
        releveLeLocal == other.releveLeLocal &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, releveLeLocal.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReleveDePresence')
          ..add('distanceM', distanceM)
          ..add('releveLeLocal', releveLeLocal)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class ReleveDePresenceBuilder
    implements Builder<ReleveDePresence, ReleveDePresenceBuilder> {
  _$ReleveDePresence? _$v;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  DateTime? _releveLeLocal;
  DateTime? get releveLeLocal => _$this._releveLeLocal;
  set releveLeLocal(DateTime? releveLeLocal) =>
      _$this._releveLeLocal = releveLeLocal;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  ReleveDePresenceBuilder() {
    ReleveDePresence._defaults(this);
  }

  ReleveDePresenceBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _distanceM = $v.distanceM;
      _releveLeLocal = $v.releveLeLocal;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReleveDePresence other) {
    _$v = other as _$ReleveDePresence;
  }

  @override
  void update(void Function(ReleveDePresenceBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReleveDePresence build() => _build();

  _$ReleveDePresence _build() {
    final _$result = _$v ??
        _$ReleveDePresence._(
          distanceM: BuiltValueNullFieldError.checkNotNull(
              distanceM, r'ReleveDePresence', 'distanceM'),
          releveLeLocal: BuiltValueNullFieldError.checkNotNull(
              releveLeLocal, r'ReleveDePresence', 'releveLeLocal'),
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'ReleveDePresence', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
