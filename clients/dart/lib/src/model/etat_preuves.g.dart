// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'etat_preuves.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$EtatPreuves extends EtatPreuves {
  @override
  final PreuveAppels appels;
  @override
  final PreuvePhotos photos;
  @override
  final PreuvePresence presence;
  @override
  final bool reunies;
  @override
  final int reuniesSur;
  @override
  final int total;

  factory _$EtatPreuves([void Function(EtatPreuvesBuilder)? updates]) =>
      (EtatPreuvesBuilder()..update(updates))._build();

  _$EtatPreuves._(
      {required this.appels,
      required this.photos,
      required this.presence,
      required this.reunies,
      required this.reuniesSur,
      required this.total})
      : super._();
  @override
  EtatPreuves rebuild(void Function(EtatPreuvesBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  EtatPreuvesBuilder toBuilder() => EtatPreuvesBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is EtatPreuves &&
        appels == other.appels &&
        photos == other.photos &&
        presence == other.presence &&
        reunies == other.reunies &&
        reuniesSur == other.reuniesSur &&
        total == other.total;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, appels.hashCode);
    _$hash = $jc(_$hash, photos.hashCode);
    _$hash = $jc(_$hash, presence.hashCode);
    _$hash = $jc(_$hash, reunies.hashCode);
    _$hash = $jc(_$hash, reuniesSur.hashCode);
    _$hash = $jc(_$hash, total.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'EtatPreuves')
          ..add('appels', appels)
          ..add('photos', photos)
          ..add('presence', presence)
          ..add('reunies', reunies)
          ..add('reuniesSur', reuniesSur)
          ..add('total', total))
        .toString();
  }
}

class EtatPreuvesBuilder implements Builder<EtatPreuves, EtatPreuvesBuilder> {
  _$EtatPreuves? _$v;

  PreuveAppelsBuilder? _appels;
  PreuveAppelsBuilder get appels => _$this._appels ??= PreuveAppelsBuilder();
  set appels(PreuveAppelsBuilder? appels) => _$this._appels = appels;

  PreuvePhotosBuilder? _photos;
  PreuvePhotosBuilder get photos => _$this._photos ??= PreuvePhotosBuilder();
  set photos(PreuvePhotosBuilder? photos) => _$this._photos = photos;

  PreuvePresenceBuilder? _presence;
  PreuvePresenceBuilder get presence =>
      _$this._presence ??= PreuvePresenceBuilder();
  set presence(PreuvePresenceBuilder? presence) => _$this._presence = presence;

  bool? _reunies;
  bool? get reunies => _$this._reunies;
  set reunies(bool? reunies) => _$this._reunies = reunies;

  int? _reuniesSur;
  int? get reuniesSur => _$this._reuniesSur;
  set reuniesSur(int? reuniesSur) => _$this._reuniesSur = reuniesSur;

  int? _total;
  int? get total => _$this._total;
  set total(int? total) => _$this._total = total;

  EtatPreuvesBuilder() {
    EtatPreuves._defaults(this);
  }

  EtatPreuvesBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _appels = $v.appels.toBuilder();
      _photos = $v.photos.toBuilder();
      _presence = $v.presence.toBuilder();
      _reunies = $v.reunies;
      _reuniesSur = $v.reuniesSur;
      _total = $v.total;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(EtatPreuves other) {
    _$v = other as _$EtatPreuves;
  }

  @override
  void update(void Function(EtatPreuvesBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  EtatPreuves build() => _build();

  _$EtatPreuves _build() {
    _$EtatPreuves _$result;
    try {
      _$result = _$v ??
          _$EtatPreuves._(
            appels: appels.build(),
            photos: photos.build(),
            presence: presence.build(),
            reunies: BuiltValueNullFieldError.checkNotNull(
                reunies, r'EtatPreuves', 'reunies'),
            reuniesSur: BuiltValueNullFieldError.checkNotNull(
                reuniesSur, r'EtatPreuves', 'reuniesSur'),
            total: BuiltValueNullFieldError.checkNotNull(
                total, r'EtatPreuves', 'total'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'appels';
        appels.build();
        _$failedField = 'photos';
        photos.build();
        _$failedField = 'presence';
        presence.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'EtatPreuves', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
