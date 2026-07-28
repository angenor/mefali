// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'acceptation_offre.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$AcceptationOffre extends AcceptationOffre {
  @override
  final String commandeId;
  @override
  final String etatLivraison;
  @override
  final String livraisonId;
  @override
  final bool rejeu;

  factory _$AcceptationOffre(
          [void Function(AcceptationOffreBuilder)? updates]) =>
      (AcceptationOffreBuilder()..update(updates))._build();

  _$AcceptationOffre._(
      {required this.commandeId,
      required this.etatLivraison,
      required this.livraisonId,
      required this.rejeu})
      : super._();
  @override
  AcceptationOffre rebuild(void Function(AcceptationOffreBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  AcceptationOffreBuilder toBuilder() =>
      AcceptationOffreBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is AcceptationOffre &&
        commandeId == other.commandeId &&
        etatLivraison == other.etatLivraison &&
        livraisonId == other.livraisonId &&
        rejeu == other.rejeu;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, etatLivraison.hashCode);
    _$hash = $jc(_$hash, livraisonId.hashCode);
    _$hash = $jc(_$hash, rejeu.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'AcceptationOffre')
          ..add('commandeId', commandeId)
          ..add('etatLivraison', etatLivraison)
          ..add('livraisonId', livraisonId)
          ..add('rejeu', rejeu))
        .toString();
  }
}

class AcceptationOffreBuilder
    implements Builder<AcceptationOffre, AcceptationOffreBuilder> {
  _$AcceptationOffre? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _etatLivraison;
  String? get etatLivraison => _$this._etatLivraison;
  set etatLivraison(String? etatLivraison) =>
      _$this._etatLivraison = etatLivraison;

  String? _livraisonId;
  String? get livraisonId => _$this._livraisonId;
  set livraisonId(String? livraisonId) => _$this._livraisonId = livraisonId;

  bool? _rejeu;
  bool? get rejeu => _$this._rejeu;
  set rejeu(bool? rejeu) => _$this._rejeu = rejeu;

  AcceptationOffreBuilder() {
    AcceptationOffre._defaults(this);
  }

  AcceptationOffreBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _etatLivraison = $v.etatLivraison;
      _livraisonId = $v.livraisonId;
      _rejeu = $v.rejeu;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(AcceptationOffre other) {
    _$v = other as _$AcceptationOffre;
  }

  @override
  void update(void Function(AcceptationOffreBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  AcceptationOffre build() => _build();

  _$AcceptationOffre _build() {
    final _$result = _$v ??
        _$AcceptationOffre._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'AcceptationOffre', 'commandeId'),
          etatLivraison: BuiltValueNullFieldError.checkNotNull(
              etatLivraison, r'AcceptationOffre', 'etatLivraison'),
          livraisonId: BuiltValueNullFieldError.checkNotNull(
              livraisonId, r'AcceptationOffre', 'livraisonId'),
          rejeu: BuiltValueNullFieldError.checkNotNull(
              rejeu, r'AcceptationOffre', 'rejeu'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
