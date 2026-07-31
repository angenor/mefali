// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_preuve.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhotoPreuve extends PhotoPreuve {
  @override
  final String id;
  @override
  final DateTime priseLe;
  @override
  final DateTime? purgeeLe;
  @override
  final String? url;

  factory _$PhotoPreuve([void Function(PhotoPreuveBuilder)? updates]) =>
      (PhotoPreuveBuilder()..update(updates))._build();

  _$PhotoPreuve._(
      {required this.id, required this.priseLe, this.purgeeLe, this.url})
      : super._();
  @override
  PhotoPreuve rebuild(void Function(PhotoPreuveBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhotoPreuveBuilder toBuilder() => PhotoPreuveBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhotoPreuve &&
        id == other.id &&
        priseLe == other.priseLe &&
        purgeeLe == other.purgeeLe &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, priseLe.hashCode);
    _$hash = $jc(_$hash, purgeeLe.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhotoPreuve')
          ..add('id', id)
          ..add('priseLe', priseLe)
          ..add('purgeeLe', purgeeLe)
          ..add('url', url))
        .toString();
  }
}

class PhotoPreuveBuilder implements Builder<PhotoPreuve, PhotoPreuveBuilder> {
  _$PhotoPreuve? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  DateTime? _priseLe;
  DateTime? get priseLe => _$this._priseLe;
  set priseLe(DateTime? priseLe) => _$this._priseLe = priseLe;

  DateTime? _purgeeLe;
  DateTime? get purgeeLe => _$this._purgeeLe;
  set purgeeLe(DateTime? purgeeLe) => _$this._purgeeLe = purgeeLe;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  PhotoPreuveBuilder() {
    PhotoPreuve._defaults(this);
  }

  PhotoPreuveBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _priseLe = $v.priseLe;
      _purgeeLe = $v.purgeeLe;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhotoPreuve other) {
    _$v = other as _$PhotoPreuve;
  }

  @override
  void update(void Function(PhotoPreuveBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhotoPreuve build() => _build();

  _$PhotoPreuve _build() {
    final _$result = _$v ??
        _$PhotoPreuve._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PhotoPreuve', 'id'),
          priseLe: BuiltValueNullFieldError.checkNotNull(
              priseLe, r'PhotoPreuve', 'priseLe'),
          purgeeLe: purgeeLe,
          url: url,
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
