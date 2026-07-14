// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'jetons_dto.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$JetonsDto extends JetonsDto {
  @override
  final String acces;
  @override
  final String rafraichissement;

  factory _$JetonsDto([void Function(JetonsDtoBuilder)? updates]) =>
      (JetonsDtoBuilder()..update(updates))._build();

  _$JetonsDto._({required this.acces, required this.rafraichissement})
      : super._();
  @override
  JetonsDto rebuild(void Function(JetonsDtoBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  JetonsDtoBuilder toBuilder() => JetonsDtoBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is JetonsDto &&
        acces == other.acces &&
        rafraichissement == other.rafraichissement;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, acces.hashCode);
    _$hash = $jc(_$hash, rafraichissement.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'JetonsDto')
          ..add('acces', acces)
          ..add('rafraichissement', rafraichissement))
        .toString();
  }
}

class JetonsDtoBuilder implements Builder<JetonsDto, JetonsDtoBuilder> {
  _$JetonsDto? _$v;

  String? _acces;
  String? get acces => _$this._acces;
  set acces(String? acces) => _$this._acces = acces;

  String? _rafraichissement;
  String? get rafraichissement => _$this._rafraichissement;
  set rafraichissement(String? rafraichissement) =>
      _$this._rafraichissement = rafraichissement;

  JetonsDtoBuilder() {
    JetonsDto._defaults(this);
  }

  JetonsDtoBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _acces = $v.acces;
      _rafraichissement = $v.rafraichissement;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(JetonsDto other) {
    _$v = other as _$JetonsDto;
  }

  @override
  void update(void Function(JetonsDtoBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  JetonsDto build() => _build();

  _$JetonsDto _build() {
    final _$result = _$v ??
        _$JetonsDto._(
          acces: BuiltValueNullFieldError.checkNotNull(
              acces, r'JetonsDto', 'acces'),
          rafraichissement: BuiltValueNullFieldError.checkNotNull(
              rafraichissement, r'JetonsDto', 'rafraichissement'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
