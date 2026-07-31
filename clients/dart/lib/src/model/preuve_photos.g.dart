// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'preuve_photos.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PreuvePhotos extends PreuvePhotos {
  @override
  final int faites;
  @override
  final bool ok;
  @override
  final int requis;

  factory _$PreuvePhotos([void Function(PreuvePhotosBuilder)? updates]) =>
      (PreuvePhotosBuilder()..update(updates))._build();

  _$PreuvePhotos._(
      {required this.faites, required this.ok, required this.requis})
      : super._();
  @override
  PreuvePhotos rebuild(void Function(PreuvePhotosBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PreuvePhotosBuilder toBuilder() => PreuvePhotosBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PreuvePhotos &&
        faites == other.faites &&
        ok == other.ok &&
        requis == other.requis;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, faites.hashCode);
    _$hash = $jc(_$hash, ok.hashCode);
    _$hash = $jc(_$hash, requis.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PreuvePhotos')
          ..add('faites', faites)
          ..add('ok', ok)
          ..add('requis', requis))
        .toString();
  }
}

class PreuvePhotosBuilder
    implements Builder<PreuvePhotos, PreuvePhotosBuilder> {
  _$PreuvePhotos? _$v;

  int? _faites;
  int? get faites => _$this._faites;
  set faites(int? faites) => _$this._faites = faites;

  bool? _ok;
  bool? get ok => _$this._ok;
  set ok(bool? ok) => _$this._ok = ok;

  int? _requis;
  int? get requis => _$this._requis;
  set requis(int? requis) => _$this._requis = requis;

  PreuvePhotosBuilder() {
    PreuvePhotos._defaults(this);
  }

  PreuvePhotosBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _faites = $v.faites;
      _ok = $v.ok;
      _requis = $v.requis;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PreuvePhotos other) {
    _$v = other as _$PreuvePhotos;
  }

  @override
  void update(void Function(PreuvePhotosBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PreuvePhotos build() => _build();

  _$PreuvePhotos _build() {
    final _$result = _$v ??
        _$PreuvePhotos._(
          faites: BuiltValueNullFieldError.checkNotNull(
              faites, r'PreuvePhotos', 'faites'),
          ok: BuiltValueNullFieldError.checkNotNull(ok, r'PreuvePhotos', 'ok'),
          requis: BuiltValueNullFieldError.checkNotNull(
              requis, r'PreuvePhotos', 'requis'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
