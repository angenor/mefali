// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'charte_admin_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$CharteAdminDto extends CharteAdminDto {
  @override
  final DateTime deposeeLe;
  @override
  final String id;
  @override
  final Date signeeLe;
  @override
  final String url;
  @override
  final String versionCharte;

  factory _$CharteAdminDto([void Function(CharteAdminDtoBuilder)? updates]) =>
      (CharteAdminDtoBuilder()..update(updates))._build();

  _$CharteAdminDto._(
      {required this.deposeeLe,
      required this.id,
      required this.signeeLe,
      required this.url,
      required this.versionCharte})
      : super._();
  @override
  CharteAdminDto rebuild(void Function(CharteAdminDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  CharteAdminDtoBuilder toBuilder() => CharteAdminDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is CharteAdminDto &&
        deposeeLe == other.deposeeLe &&
        id == other.id &&
        signeeLe == other.signeeLe &&
        url == other.url &&
        versionCharte == other.versionCharte;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, deposeeLe.hashCode);
    _$hash = $jc(_$hash, id.hashCode);
    _$hash = $jc(_$hash, signeeLe.hashCode);
    _$hash = $jc(_$hash, url.hashCode);
    _$hash = $jc(_$hash, versionCharte.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'CharteAdminDto')
          ..add('deposeeLe', deposeeLe)
          ..add('id', id)
          ..add('signeeLe', signeeLe)
          ..add('url', url)
          ..add('versionCharte', versionCharte))
        .toString();
  }
}

class CharteAdminDtoBuilder
    implements Builder<CharteAdminDto, CharteAdminDtoBuilder> {
  _$CharteAdminDto? _$v;

  DateTime? _deposeeLe;
  DateTime? get deposeeLe => _$this._deposeeLe;
  set deposeeLe(DateTime? deposeeLe) => _$this._deposeeLe = deposeeLe;

  String? _id;
  String? get id => _$this._id;
  set id(String? id) => _$this._id = id;

  Date? _signeeLe;
  Date? get signeeLe => _$this._signeeLe;
  set signeeLe(Date? signeeLe) => _$this._signeeLe = signeeLe;

  String? _url;
  String? get url => _$this._url;
  set url(String? url) => _$this._url = url;

  String? _versionCharte;
  String? get versionCharte => _$this._versionCharte;
  set versionCharte(String? versionCharte) =>
      _$this._versionCharte = versionCharte;

  CharteAdminDtoBuilder() {
    CharteAdminDto._defaults(this);
  }

  CharteAdminDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _deposeeLe = $v.deposeeLe;
      _id = $v.id;
      _signeeLe = $v.signeeLe;
      _url = $v.url;
      _versionCharte = $v.versionCharte;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(CharteAdminDto other) {
    _$v = other as _$CharteAdminDto;
  }

  @override
  void update(void Function(CharteAdminDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  CharteAdminDto build() => _build();

  _$CharteAdminDto _build() {
    final _$result = _$v ??
        _$CharteAdminDto._(
          deposeeLe: BuiltValueNullFieldError.checkNotNull(
              deposeeLe, r'CharteAdminDto', 'deposeeLe'),
          id: BuiltValueNullFieldError.checkNotNull(
              id, r'CharteAdminDto', 'id'),
          signeeLe: BuiltValueNullFieldError.checkNotNull(
              signeeLe, r'CharteAdminDto', 'signeeLe'),
          url: BuiltValueNullFieldError.checkNotNull(
              url, r'CharteAdminDto', 'url'),
          versionCharte: BuiltValueNullFieldError.checkNotNull(
              versionCharte, r'CharteAdminDto', 'versionCharte'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
