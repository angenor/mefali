// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_remise.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatRemise extends ResultatRemise {
  @override
  final String commandeId;
  @override
  final int essaisCode;
  @override
  final String livraisonId;
  @override
  final String modeRemise;
  @override
  final bool rejeu;

  factory _$ResultatRemise([void Function(ResultatRemiseBuilder)? updates]) =>
      (ResultatRemiseBuilder()..update(updates))._build();

  _$ResultatRemise._(
      {required this.commandeId,
      required this.essaisCode,
      required this.livraisonId,
      required this.modeRemise,
      required this.rejeu})
      : super._();
  @override
  ResultatRemise rebuild(void Function(ResultatRemiseBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatRemiseBuilder toBuilder() => ResultatRemiseBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatRemise &&
        commandeId == other.commandeId &&
        essaisCode == other.essaisCode &&
        livraisonId == other.livraisonId &&
        modeRemise == other.modeRemise &&
        rejeu == other.rejeu;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, essaisCode.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, modeRemise.hashCode);
    _$hash = $jc(_$hash, rejeu.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatRemise')
          ..add('commandeId', commandeId)
          ..add('essaisCode', essaisCode)
          ..add('livraisonId', livraisonId)
          ..add('modeRemise', modeRemise)
          ..add('rejeu', rejeu))
        .toString();
  }
}

class ResultatRemiseBuilder
    implements Builder<ResultatRemise, ResultatRemiseBuilder> {
  _$ResultatRemise? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  int? _essaisCode;
  int? get essaisCode => _$this._essaisCode;
  set essaisCode(int? essaisCode) => _$this._essaisCode = essaisCode;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  String? _modeRemise;
  String? get modeRemise => _$this._modeRemise;
  set modeRemise(String? modeRemise) => _$this._modeRemise = modeRemise;

  bool? _rejeu;
  bool? get rejeu => _$this._rejeu;
  set rejeu(bool? rejeu) => _$this._rejeu = rejeu;

  ResultatRemiseBuilder() {
    ResultatRemise._defaults(this);
  }

  ResultatRemiseBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _essaisCode = $v.essaisCode;
      _livraisonId = $v.livraisonId;
      _modeRemise = $v.modeRemise;
      _rejeu = $v.rejeu;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatRemise other) {
    _$v = other as _$ResultatRemise;
  }

  @override
  void update(void Function(ResultatRemiseBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatRemise build() => _build();

  _$ResultatRemise _build() {
    final _$result = _$v ??
        _$ResultatRemise._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'ResultatRemise', 'commandeId'),
          essaisCode: BuiltValueNullFieldError.checkNotNull(
              essaisCode, r'ResultatRemise', 'essaisCode'),
          livraisonId: BuiltValueNullFieldError.checkNotNull(
              livraisonId, r'ResultatRemise', 'livraisonId'),
          modeRemise: BuiltValueNullFieldError.checkNotNull(
              modeRemise, r'ResultatRemise', 'modeRemise'),
          rejeu: BuiltValueNullFieldError.checkNotNull(
              rejeu, r'ResultatRemise', 'rejeu'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
