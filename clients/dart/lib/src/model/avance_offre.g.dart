// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'avance_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AvanceOffre extends AvanceOffre {
  @override
  final String devise;
  @override
  final int montantUnites;
  @override
  final int plafondRetenuUnites;

  factory _$AvanceOffre([void Function(AvanceOffreBuilder)? updates]) =>
      (AvanceOffreBuilder()..update(updates))._build();

  _$AvanceOffre._(
      {required this.devise,
      required this.montantUnites,
      required this.plafondRetenuUnites})
      : super._();
  @override
  AvanceOffre rebuild(void Function(AvanceOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AvanceOffreBuilder toBuilder() => AvanceOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AvanceOffre &&
        devise == other.devise &&
        montantUnites == other.montantUnites &&
        plafondRetenuUnites == other.plafondRetenuUnites;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, montantUnites.hashCode);
    _$hash = $jc(_$hash, plafondRetenuUnites.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AvanceOffre')
          ..add('devise', devise)
          ..add('montantUnites', montantUnites)
          ..add('plafondRetenuUnites', plafondRetenuUnites))
        .toString();
  }
}

class AvanceOffreBuilder implements Builder<AvanceOffre, AvanceOffreBuilder> {
  _$AvanceOffre? _$v;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _montantUnites;
  int? get montantUnites => _$this._montantUnites;
  set montantUnites(int? montantUnites) =>
      _$this._montantUnites = montantUnites;

  int? _plafondRetenuUnites;
  int? get plafondRetenuUnites => _$this._plafondRetenuUnites;
  set plafondRetenuUnites(int? plafondRetenuUnites) =>
      _$this._plafondRetenuUnites = plafondRetenuUnites;

  AvanceOffreBuilder() {
    AvanceOffre._defaults(this);
  }

  AvanceOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _devise = $v.devise;
      _montantUnites = $v.montantUnites;
      _plafondRetenuUnites = $v.plafondRetenuUnites;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AvanceOffre other) {
    _$v = other as _$AvanceOffre;
  }

  @override
  void update(void Function(AvanceOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AvanceOffre build() => _build();

  _$AvanceOffre _build() {
    final _$result = _$v ??
        _$AvanceOffre._(
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'AvanceOffre', 'devise'),
          montantUnites: BuiltValueNullFieldError.checkNotNull(
              montantUnites, r'AvanceOffre', 'montantUnites'),
          plafondRetenuUnites: BuiltValueNullFieldError.checkNotNull(
              plafondRetenuUnites, r'AvanceOffre', 'plafondRetenuUnites'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
