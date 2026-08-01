// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appel_enregistre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AppelEnregistre extends AppelEnregistre {
  @override
  final String appelId;
  @override
  final bool comptePourPreuve;

  factory _$AppelEnregistre([void Function(AppelEnregistreBuilder)? updates]) =>
      (AppelEnregistreBuilder()..update(updates))._build();

  _$AppelEnregistre._({required this.appelId, required this.comptePourPreuve})
      : super._();
  @override
  AppelEnregistre rebuild(void Function(AppelEnregistreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AppelEnregistreBuilder toBuilder() => AppelEnregistreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AppelEnregistre &&
        appelId == other.appelId &&
        comptePourPreuve == other.comptePourPreuve;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appelId.hashCode);
    _$hash = $jc(_$hash, comptePourPreuve.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AppelEnregistre')
          ..add('appelId', appelId)
          ..add('comptePourPreuve', comptePourPreuve))
        .toString();
  }
}

class AppelEnregistreBuilder
    implements Builder<AppelEnregistre, AppelEnregistreBuilder> {
  _$AppelEnregistre? _$v;

  String? _appelId;
  String? get appelId => _$this._appelId;
  set appelId(String? appelId) => _$this._appelId = appelId;

  bool? _comptePourPreuve;
  bool? get comptePourPreuve => _$this._comptePourPreuve;
  set comptePourPreuve(bool? comptePourPreuve) =>
      _$this._comptePourPreuve = comptePourPreuve;

  AppelEnregistreBuilder() {
    AppelEnregistre._defaults(this);
  }

  AppelEnregistreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appelId = $v.appelId;
      _comptePourPreuve = $v.comptePourPreuve;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AppelEnregistre other) {
    _$v = other as _$AppelEnregistre;
  }

  @override
  void update(void Function(AppelEnregistreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AppelEnregistre build() => _build();

  _$AppelEnregistre _build() {
    final _$result = _$v ??
        _$AppelEnregistre._(
          appelId: BuiltValueNullFieldError.checkNotNull(
              appelId, r'AppelEnregistre', 'appelId'),
          comptePourPreuve: BuiltValueNullFieldError.checkNotNull(
              comptePourPreuve, r'AppelEnregistre', 'comptePourPreuve'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
