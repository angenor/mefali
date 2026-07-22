// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'boutique_vendeur.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$BoutiqueVendeur extends BoutiqueVendeur {
  @override
  final EtatEffectifBoutique etatEffectif;
  @override
  final HorairesSemaineDto horaires;
  @override
  final BuiltList<PlageDto> horairesDuJour;
  @override
  final DateTime? pauseFin;
  @override
  final bool rappelOuverture;
  @override
  final StatutBoutique statut;

  factory _$BoutiqueVendeur([void Function(BoutiqueVendeurBuilder)? updates]) =>
      (BoutiqueVendeurBuilder()..update(updates))._build();

  _$BoutiqueVendeur._(
      {required this.etatEffectif,
      required this.horaires,
      required this.horairesDuJour,
      this.pauseFin,
      required this.rappelOuverture,
      required this.statut})
      : super._();
  @override
  BoutiqueVendeur rebuild(void Function(BoutiqueVendeurBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  BoutiqueVendeurBuilder toBuilder() => BoutiqueVendeurBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is BoutiqueVendeur &&
        etatEffectif == other.etatEffectif &&
        horaires == other.horaires &&
        horairesDuJour == other.horairesDuJour &&
        pauseFin == other.pauseFin &&
        rappelOuverture == other.rappelOuverture &&
        statut == other.statut;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, etatEffectif.hashCode);
    _$hash = $jc(_$hash, horaires.hashCode);
    _$hash = $jc(_$hash, horairesDuJour.hashCode);
    _$hash = $jc(_$hash, pauseFin.hashCode);
    _$hash = $jc(_$hash, rappelOuverture.hashCode);
    _$hash = $jc(_$hash, statut.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'BoutiqueVendeur')
          ..add('etatEffectif', etatEffectif)
          ..add('horaires', horaires)
          ..add('horairesDuJour', horairesDuJour)
          ..add('pauseFin', pauseFin)
          ..add('rappelOuverture', rappelOuverture)
          ..add('statut', statut))
        .toString();
  }
}

class BoutiqueVendeurBuilder
    implements Builder<BoutiqueVendeur, BoutiqueVendeurBuilder> {
  _$BoutiqueVendeur? _$v;

  EtatEffectifBoutiqueBuilder? _etatEffectif;
  EtatEffectifBoutiqueBuilder get etatEffectif =>
      _$this._etatEffectif ??= EtatEffectifBoutiqueBuilder();
  set etatEffectif(EtatEffectifBoutiqueBuilder? etatEffectif) =>
      _$this._etatEffectif = etatEffectif;

  HorairesSemaineDtoBuilder? _horaires;
  HorairesSemaineDtoBuilder get horaires =>
      _$this._horaires ??= HorairesSemaineDtoBuilder();
  set horaires(HorairesSemaineDtoBuilder? horaires) =>
      _$this._horaires = horaires;

  ListBuilder<PlageDto>? _horairesDuJour;
  ListBuilder<PlageDto> get horairesDuJour =>
      _$this._horairesDuJour ??= ListBuilder<PlageDto>();
  set horairesDuJour(ListBuilder<PlageDto>? horairesDuJour) =>
      _$this._horairesDuJour = horairesDuJour;

  DateTime? _pauseFin;
  DateTime? get pauseFin => _$this._pauseFin;
  set pauseFin(DateTime? pauseFin) => _$this._pauseFin = pauseFin;

  bool? _rappelOuverture;
  bool? get rappelOuverture => _$this._rappelOuverture;
  set rappelOuverture(bool? rappelOuverture) =>
      _$this._rappelOuverture = rappelOuverture;

  StatutBoutique? _statut;
  StatutBoutique? get statut => _$this._statut;
  set statut(StatutBoutique? statut) => _$this._statut = statut;

  BoutiqueVendeurBuilder() {
    BoutiqueVendeur._defaults(this);
  }

  BoutiqueVendeurBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _etatEffectif = $v.etatEffectif.toBuilder();
      _horaires = $v.horaires.toBuilder();
      _horairesDuJour = $v.horairesDuJour.toBuilder();
      _pauseFin = $v.pauseFin;
      _rappelOuverture = $v.rappelOuverture;
      _statut = $v.statut;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(BoutiqueVendeur other) {
    _$v = other as _$BoutiqueVendeur;
  }

  @override
  void update(void Function(BoutiqueVendeurBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  BoutiqueVendeur build() => _build();

  _$BoutiqueVendeur _build() {
    _$BoutiqueVendeur _$result;
    try {
      _$result = _$v ??
          _$BoutiqueVendeur._(
            etatEffectif: etatEffectif.build(),
            horaires: horaires.build(),
            horairesDuJour: horairesDuJour.build(),
            pauseFin: pauseFin,
            rappelOuverture: BuiltValueNullFieldError.checkNotNull(
                rappelOuverture, r'BoutiqueVendeur', 'rappelOuverture'),
            statut: BuiltValueNullFieldError.checkNotNull(
                statut, r'BoutiqueVendeur', 'statut'),
          );
    } catch (_) {
      late String _$failedField;
      try {
        _$failedField = 'etatEffectif';
        etatEffectif.build();
        _$failedField = 'horaires';
        horaires.build();
        _$failedField = 'horairesDuJour';
        horairesDuJour.build();
      } catch (e) {
        throw BuiltValueNestedFieldError(
            r'BoutiqueVendeur', _$failedField, e.toString());
      }
      rethrow;
    }
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
