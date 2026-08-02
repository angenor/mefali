// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reponse_notification.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ReponseNotification extends ReponseNotification {
  @override
  final String? motif;
  @override
  final bool traite;

  factory _$ReponseNotification(
          [void Function(ReponseNotificationBuilder)? updates]) =>
      (ReponseNotificationBuilder()..update(updates))._build();

  _$ReponseNotification._({this.motif, required this.traite}) : super._();
  @override
  ReponseNotification rebuild(
          void Function(ReponseNotificationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ReponseNotificationBuilder toBuilder() =>
      ReponseNotificationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ReponseNotification &&
        motif == other.motif &&
        traite == other.traite;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, motif.hashCode);
    _$hash = $jc(_$hash, traite.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ReponseNotification')
          ..add('motif', motif)
          ..add('traite', traite))
        .toString();
  }
}

class ReponseNotificationBuilder
    implements Builder<ReponseNotification, ReponseNotificationBuilder> {
  _$ReponseNotification? _$v;

  String? _motif;
  String? get motif => _$this._motif;
  set motif(String? motif) => _$this._motif = motif;

  bool? _traite;
  bool? get traite => _$this._traite;
  set traite(bool? traite) => _$this._traite = traite;

  ReponseNotificationBuilder() {
    ReponseNotification._defaults(this);
  }

  ReponseNotificationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _motif = $v.motif;
      _traite = $v.traite;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ReponseNotification other) {
    _$v = other as _$ReponseNotification;
  }

  @override
  void update(void Function(ReponseNotificationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ReponseNotification build() => _build();

  _$ReponseNotification _build() {
    final _$result = _$v ??
        _$ReponseNotification._(
          motif: motif,
          traite: BuiltValueNullFieldError.checkNotNull(
              traite, r'ReponseNotification', 'traite'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
