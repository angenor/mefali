// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo_preuve_deposee.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$PhotoPreuveDeposee extends PhotoPreuveDeposee {
  @override
  final String photoId;
  @override
  final int photos;
  @override
  final bool rejeu;

  factory _$PhotoPreuveDeposee(
          [void Function(PhotoPreuveDeposeeBuilder)? updates]) =>
      (PhotoPreuveDeposeeBuilder()..update(updates))._build();

  _$PhotoPreuveDeposee._(
      {required this.photoId, required this.photos, required this.rejeu})
      : super._();
  @override
  PhotoPreuveDeposee rebuild(
          void Function(PhotoPreuveDeposeeBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  PhotoPreuveDeposeeBuilder toBuilder() =>
      PhotoPreuveDeposeeBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is PhotoPreuveDeposee &&
        photoId == other.photoId &&
        photos == other.photos &&
        rejeu == other.rejeu;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, photoId.hashCode);
    _$hash = $jc(_$hash, photos.hashCode);
    _$hash = $jc(_$hash, rejeu.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'PhotoPreuveDeposee')
          ..add('photoId', photoId)
          ..add('photos', photos)
          ..add('rejeu', rejeu))
        .toString();
  }
}

class PhotoPreuveDeposeeBuilder
    implements Builder<PhotoPreuveDeposee, PhotoPreuveDeposeeBuilder> {
  _$PhotoPreuveDeposee? _$v;

  String? _photoId;
  String? get photoId => _$this._photoId;
  set photoId(String? photoId) => _$this._photoId = photoId;

  int? _photos;
  int? get photos => _$this._photos;
  set photos(int? photos) => _$this._photos = photos;

  bool? _rejeu;
  bool? get rejeu => _$this._rejeu;
  set rejeu(bool? rejeu) => _$this._rejeu = rejeu;

  PhotoPreuveDeposeeBuilder() {
    PhotoPreuveDeposee._defaults(this);
  }

  PhotoPreuveDeposeeBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _photoId = $v.photoId;
      _photos = $v.photos;
      _rejeu = $v.rejeu;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(PhotoPreuveDeposee other) {
    _$v = other as _$PhotoPreuveDeposee;
  }

  @override
  void update(void Function(PhotoPreuveDeposeeBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  PhotoPreuveDeposee build() => _build();

  _$PhotoPreuveDeposee _build() {
    final _$result = _$v ??
        _$PhotoPreuveDeposee._(
          photoId: BuiltValueNullFieldError.checkNotNull(
              photoId, r'PhotoPreuveDeposee', 'photoId'),
          photos: BuiltValueNullFieldError.checkNotNull(
              photos, r'PhotoPreuveDeposee', 'photos'),
          rejeu: BuiltValueNullFieldError.checkNotNull(
              rejeu, r'PhotoPreuveDeposee', 'rejeu'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
