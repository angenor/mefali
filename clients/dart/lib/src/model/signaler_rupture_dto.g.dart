// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'signaler_rupture_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$SignalerRuptureDto extends SignalerRuptureDto {
  @override
  final String articleId;
  @override
  final DateTime horodatageLocal;

  factory _$SignalerRuptureDto(
          [void Function(SignalerRuptureDtoBuilder)? updates]) =>
      (SignalerRuptureDtoBuilder()..update(updates))._build();

  _$SignalerRuptureDto._(
      {required this.articleId, required this.horodatageLocal})
      : super._();
  @override
  SignalerRuptureDto rebuild(
          void Function(SignalerRuptureDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  SignalerRuptureDtoBuilder toBuilder() =>
      SignalerRuptureDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is SignalerRuptureDto &&
        articleId == other.articleId &&
        horodatageLocal == other.horodatageLocal;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, articleId.hashCode);
    _$hash = $jc(_$hash, horodatageLocal.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'SignalerRuptureDto')
          ..add('articleId', articleId)
          ..add('horodatageLocal', horodatageLocal))
        .toString();
  }
}

class SignalerRuptureDtoBuilder
    implements Builder<SignalerRuptureDto, SignalerRuptureDtoBuilder> {
  _$SignalerRuptureDto? _$v;

  String? _articleId;
  String? get articleId => _$this._articleId;
  set articleId(String? articleId) => _$this._articleId = articleId;

  DateTime? _horodatageLocal;
  DateTime? get horodatageLocal => _$this._horodatageLocal;
  set horodatageLocal(DateTime? horodatageLocal) =>
      _$this._horodatageLocal = horodatageLocal;

  SignalerRuptureDtoBuilder() {
    SignalerRuptureDto._defaults(this);
  }

  SignalerRuptureDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _articleId = $v.articleId;
      _horodatageLocal = $v.horodatageLocal;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(SignalerRuptureDto other) {
    _$v = other as _$SignalerRuptureDto;
  }

  @override
  void update(void Function(SignalerRuptureDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  SignalerRuptureDto build() => _build();

  _$SignalerRuptureDto _build() {
    final _$result = _$v ??
        _$SignalerRuptureDto._(
          articleId: BuiltValueNullFieldError.checkNotNull(
              articleId, r'SignalerRuptureDto', 'articleId'),
          horodatageLocal: BuiltValueNullFieldError.checkNotNull(
              horodatageLocal, r'SignalerRuptureDto', 'horodatageLocal'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
