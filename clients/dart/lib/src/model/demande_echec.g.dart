// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'demande_echec.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$DemandeEchec extends DemandeEchec {
  @override
  final String? arretId;
  @override
  final String motifCle;
  @override
  final String typeIssue;
  @override
  final String uuidClient;

  factory _$DemandeEchec([void Function(DemandeEchecBuilder)? updates]) =>
      (DemandeEchecBuilder()..update(updates))._build();

  _$DemandeEchec._(
      {this.arretId,
      required this.motifCle,
      required this.typeIssue,
      required this.uuidClient})
      : super._();
  @override
  DemandeEchec rebuild(void Function(DemandeEchecBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DemandeEchecBuilder toBuilder() => DemandeEchecBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is DemandeEchec &&
        arretId == other.arretId &&
        motifCle == other.motifCle &&
        typeIssue == other.typeIssue &&
        uuidClient == other.uuidClient;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, arretId.hashCode);
    _$hash = $jc(_$hash, motifCle.hashCode);
    _$hash = $jc(_$hash, typeIssue.hashCode);
    _$hash = $jc(_$hash, uuidClient.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'DemandeEchec')
          ..add('arretId', arretId)
          ..add('motifCle', motifCle)
          ..add('typeIssue', typeIssue)
          ..add('uuidClient', uuidClient))
        .toString();
  }
}

class DemandeEchecBuilder
    implements Builder<DemandeEchec, DemandeEchecBuilder> {
  _$DemandeEchec? _$v;

  String? _arretId;
  String? get arretId => _$this._arretId;
  set arretId(String? arretId) => _$this._arretId = arretId;

  String? _motifCle;
  String? get motifCle => _$this._motifCle;
  set motifCle(String? motifCle) => _$this._motifCle = motifCle;

  String? _typeIssue;
  String? get typeIssue => _$this._typeIssue;
  set typeIssue(String? typeIssue) => _$this._typeIssue = typeIssue;

  String? _uuidClient;
  String? get uuidClient => _$this._uuidClient;
  set uuidClient(String? uuidClient) => _$this._uuidClient = uuidClient;

  DemandeEchecBuilder() {
    DemandeEchec._defaults(this);
  }

  DemandeEchecBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _arretId = $v.arretId;
      _motifCle = $v.motifCle;
      _typeIssue = $v.typeIssue;
      _uuidClient = $v.uuidClient;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(DemandeEchec other) {
    _$v = other as _$DemandeEchec;
  }

  @override
  void update(void Function(DemandeEchecBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  DemandeEchec build() => _build();

  _$DemandeEchec _build() {
    final _$result = _$v ??
        _$DemandeEchec._(
          arretId: arretId,
          motifCle: BuiltValueNullFieldError.checkNotNull(
              motifCle, r'DemandeEchec', 'motifCle'),
          typeIssue: BuiltValueNullFieldError.checkNotNull(
              typeIssue, r'DemandeEchec', 'typeIssue'),
          uuidClient: BuiltValueNullFieldError.checkNotNull(
              uuidClient, r'DemandeEchec', 'uuidClient'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
