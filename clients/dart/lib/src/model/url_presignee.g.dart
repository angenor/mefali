// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_presignee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$UrlPresignee extends UrlPresignee {
  @override
  final DateTime expireLe;
  @override
  final String url;

  factory _$UrlPresignee([void Function(UrlPresigneeBuilder)? updates]) =>
      (UrlPresigneeBuilder()..update(updates))._build();

  _$UrlPresignee._({required this.expireLe, required this.url}) : super._();
  @override
  UrlPresignee rebuild(void Function(UrlPresigneeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  UrlPresigneeBuilder toBuilder() => UrlPresigneeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is UrlPresignee &&
        expireLe == other.expireLe &&
        url == other.url;
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
    return (newBuiltValueToStringHelper(r'UrlPresignee')
          ..add('expireLe', expireLe)
          ..add('url', url))
        .toString();
  }
}

class UrlPresigneeBuilder
    implements Builder<UrlPresignee, UrlPresigneeBuilder> {
  _$UrlPresignee? _$v;

  DateTime? _expireLe;
  DateTime? get expireLe => _$this._expireLe;
  set expireLe(DateTime? expireLe) => _$this._expireLe = expireLe;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  UrlPresigneeBuilder() {
    UrlPresignee._defaults(this);
  }

  UrlPresigneeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _expireLe = $v.expireLe;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(UrlPresignee other) {
    _$v = other as _$UrlPresignee;
  }

  @override
  void update(void Function(UrlPresigneeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  UrlPresignee build() => _build();

  _$UrlPresignee _build() {
    final _$result = _$v ??
        _$UrlPresignee._(
          expireLe: BuiltValueNullFieldError.checkNotNull(
              expireLe, r'UrlPresignee', 'expireLe'),
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'UrlPresignee', 'url'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
