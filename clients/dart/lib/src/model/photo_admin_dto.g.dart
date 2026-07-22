// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_admin_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhotoAdminDto extends PhotoAdminDto {
  @override
  final String id;
  @override
  final int position;
  @override
  final String url;

  factory _$PhotoAdminDto([void Function(PhotoAdminDtoBuilder)? updates]) =>
      (PhotoAdminDtoBuilder()..update(updates))._build();

  _$PhotoAdminDto._(
      {required this.id, required this.position, required this.url})
      : super._();
  @override
  PhotoAdminDto rebuild(void Function(PhotoAdminDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhotoAdminDtoBuilder toBuilder() => PhotoAdminDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhotoAdminDto &&
        id == other.id &&
        position == other.position &&
        url == other.url;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, position.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhotoAdminDto')
          ..add('id', id)
          ..add('position', position)
          ..add('url', url))
        .toString();
  }
}

class PhotoAdminDtoBuilder
    implements Builder<PhotoAdminDto, PhotoAdminDtoBuilder> {
  _$PhotoAdminDto? _$v;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  int? _position;
  int? get position => _$this._position;
  set position(int? position) => _$this._position = position;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  PhotoAdminDtoBuilder() {
    PhotoAdminDto._defaults(this);
  }

  PhotoAdminDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _id = $v.id;
      _position = $v.position;
      _url = $v.url;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhotoAdminDto other) {
    _$v = other as _$PhotoAdminDto;
  }

  @override
  void update(void Function(PhotoAdminDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhotoAdminDto build() => _build();

  _$PhotoAdminDto _build() {
    final _$result = _$v ??
        _$PhotoAdminDto._(
          id: BuiltValueNullFieldError.checkNotNull(id, r'PhotoAdminDto', 'id'),
          position: BuiltValueNullFieldError.checkNotNull(
              position, r'PhotoAdminDto', 'position'),
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'PhotoAdminDto', 'url'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
