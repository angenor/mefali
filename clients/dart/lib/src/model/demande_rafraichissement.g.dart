// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_rafraichissement.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeRafraichissement extends DemandeRafraichissement {
  @override
  final String rafraichissement;

  factory _$DemandeRafraichissement(
          [void Function(DemandeRafraichissementBuilder)? updates]) =>
      (DemandeRafraichissementBuilder()..update(updates))._build();

  _$DemandeRafraichissement._({required this.rafraichissement}) : super._();
  @override
  DemandeRafraichissement rebuild(
          void Function(DemandeRafraichissementBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeRafraichissementBuilder toBuilder() =>
      DemandeRafraichissementBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeRafraichissement &&
        rafraichissement == other.rafraichissement;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, rafraichissement.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeRafraichissement')
          ..add('rafraichissement', rafraichissement))
        .toString();
  }
}

class DemandeRafraichissementBuilder
    implements
        Builder<DemandeRafraichissement, DemandeRafraichissementBuilder> {
  _$DemandeRafraichissement? _$v;

  String? _rafraichissement;
  String? get rafraichissement => _$this._rafraichissement;
  set rafraichissement(String? rafraichissement) =>
      _$this._rafraichissement = rafraichissement;

  DemandeRafraichissementBuilder() {
    DemandeRafraichissement._defaults(this);
  }

  DemandeRafraichissementBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _rafraichissement = $v.rafraichissement;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeRafraichissement other) {
    _$v = other as _$DemandeRafraichissement;
  }

  @override
  void update(void Function(DemandeRafraichissementBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeRafraichissement build() => _build();

  _$DemandeRafraichissement _build() {
    final _$result = _$v ??
        _$DemandeRafraichissement._(
          rafraichissement: BuiltValueNullFieldError.checkNotNull(
              rafraichissement, r'DemandeRafraichissement', 'rafraichissement'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
