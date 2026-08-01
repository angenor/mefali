// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_photo_preuve.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandePhotoPreuve extends DemandePhotoPreuve {
  @override
  final DateTime? priseLeLocal;
  @override
  final String uuidClient;

  factory _$DemandePhotoPreuve(
          [void Function(DemandePhotoPreuveBuilder)? updates]) =>
      (DemandePhotoPreuveBuilder()..update(updates))._build();

  _$DemandePhotoPreuve._({this.priseLeLocal, required this.uuidClient})
      : super._();
  @override
  DemandePhotoPreuve rebuild(
          void Function(DemandePhotoPreuveBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandePhotoPreuveBuilder toBuilder() =>
      DemandePhotoPreuveBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandePhotoPreuve &&
        priseLeLocal == other.priseLeLocal &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, priseLeLocal.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandePhotoPreuve')
          ..add('priseLeLocal', priseLeLocal)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DemandePhotoPreuveBuilder
    implements Builder<DemandePhotoPreuve, DemandePhotoPreuveBuilder> {
  _$DemandePhotoPreuve? _$v;

  DateTime? _priseLeLocal;
  DateTime? get priseLeLocal => _$this._priseLeLocal;
  set priseLeLocal(DateTime? priseLeLocal) =>
      _$this._priseLeLocal = priseLeLocal;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DemandePhotoPreuveBuilder() {
    DemandePhotoPreuve._defaults(this);
  }

  DemandePhotoPreuveBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _priseLeLocal = $v.priseLeLocal;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandePhotoPreuve other) {
    _$v = other as _$DemandePhotoPreuve;
  }

  @override
  void update(void Function(DemandePhotoPreuveBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandePhotoPreuve build() => _build();

  _$DemandePhotoPreuve _build() {
    final _$result = _$v ??
        _$DemandePhotoPreuve._(
          priseLeLocal: priseLeLocal,
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandePhotoPreuve', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
