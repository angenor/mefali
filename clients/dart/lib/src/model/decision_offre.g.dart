// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'decision_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DecisionOffre extends DecisionOffre {
  @override
  final DateTime horodatageLocal;
  @override
  final String uuidClient;

  factory _$DecisionOffre([void Function(DecisionOffreBuilder)? updates]) =>
      (DecisionOffreBuilder()..update(updates))._build();

  _$DecisionOffre._({required this.horodatageLocal, required this.uuidClient})
      : super._();
  @override
  DecisionOffre rebuild(void Function(DecisionOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DecisionOffreBuilder toBuilder() => DecisionOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DecisionOffre &&
        horodatageLocal == other.horodatageLocal &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, horodatageLocal.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DecisionOffre')
          ..add('horodatageLocal', horodatageLocal)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DecisionOffreBuilder
    implements Builder<DecisionOffre, DecisionOffreBuilder> {
  _$DecisionOffre? _$v;

  DateTime? _horodatageLocal;
  DateTime? get horodatageLocal => _$this._horodatageLocal;
  set horodatageLocal(DateTime? horodatageLocal) =>
      _$this._horodatageLocal = horodatageLocal;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DecisionOffreBuilder() {
    DecisionOffre._defaults(this);
  }

  DecisionOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _horodatageLocal = $v.horodatageLocal;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DecisionOffre other) {
    _$v = other as _$DecisionOffre;
  }

  @override
  void update(void Function(DecisionOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DecisionOffre build() => _build();

  _$DecisionOffre _build() {
    final _$result = _$v ??
        _$DecisionOffre._(
          horodatageLocal: BuiltValueNullFieldError.checkNotNull(
              horodatageLocal, r'DecisionOffre', 'horodatageLocal'),
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DecisionOffre', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
