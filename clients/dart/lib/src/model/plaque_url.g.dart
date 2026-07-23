// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plaque_url.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PlaqueUrl extends PlaqueUrl {
  @override
  final DateTime expireLe;
  @override
  final String url;

  factory _$PlaqueUrl([void Function(PlaqueUrlBuilder)? updates]) =>
      (PlaqueUrlBuilder()..update(updates))._build();

  _$PlaqueUrl._({required this.expireLe, required this.url}) : super._();
  @override
  PlaqueUrl rebuild(void Function(PlaqueUrlBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PlaqueUrlBuilder toBuilder() => PlaqueUrlBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PlaqueUrl && expireLe == other.expireLe && url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, expireLe.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PlaqueUrl')
          ..add('expireLe', expireLe)
          ..add('url', url))
        .toString();
  }
}

class PlaqueUrlBuilder implements Builder<PlaqueUrl, PlaqueUrlBuilder> {
  _$PlaqueUrl? _$v;

  DateTime? _expireLe;
  DateTime? get expireLe => _$this._expireLe;
  set expireLe(DateTime? expireLe) => _$this._expireLe = expireLe;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  PlaqueUrlBuilder() {
    PlaqueUrl._defaults(this);
  }

  PlaqueUrlBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _expireLe = $v.expireLe;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PlaqueUrl other) {
    _$v = other as _$PlaqueUrl;
  }

  @override
  void update(void Function(PlaqueUrlBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PlaqueUrl build() => _build();

  _$PlaqueUrl _build() {
    final _$result = _$v ??
        _$PlaqueUrl._(
          expireLe: BuiltValueNullFieldError.checkNotNull(
              expireLe, r'PlaqueUrl', 'expireLe'),
          url: BuiltValueNullFieldError.checkNotNull(url, r'PlaqueUrl', 'url'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
