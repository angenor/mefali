// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'resultat_annulation.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$ResultatAnnulation extends ResultatAnnulation {
  @override
  final String commandeId;
  @override
  final String devise;
  @override
  final int montantAvance;
  @override
  final int partCoursierDue;
  @override
  final bool remboursementDu;
  @override
  final bool sansFrais;

  factory _$ResultatAnnulation(
          [void Function(ResultatAnnulationBuilder)? updates]) =>
      (ResultatAnnulationBuilder()..update(updates))._build();

  _$ResultatAnnulation._(
      {required this.commandeId,
      required this.devise,
      required this.montantAvance,
      required this.partCoursierDue,
      required this.remboursementDu,
      required this.sansFrais})
      : super._();
  @override
  ResultatAnnulation rebuild(
          void Function(ResultatAnnulationBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  ResultatAnnulationBuilder toBuilder() =>
      ResultatAnnulationBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is ResultatAnnulation &&
        commandeId == other.commandeId &&
        devise == other.devise &&
        montantAvance == other.montantAvance &&
        partCoursierDue == other.partCoursierDue &&
        remboursementDu == other.remboursementDu &&
        sansFrais == other.sansFrais;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, commandeId.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, montantAvance.hashCode);
    _$hash = $jc(_$hash, partCoursierDue.hashCode);
    _$hash = $jc(_$hash, remboursementDu.hashCode);
    _$hash = $jc(_$hash, sansFrais.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'ResultatAnnulation')
          ..add('commandeId', commandeId)
          ..add('devise', devise)
          ..add('montantAvance', montantAvance)
          ..add('partCoursierDue', partCoursierDue)
          ..add('remboursementDu', remboursementDu)
          ..add('sansFrais', sansFrais))
        .toString();
  }
}

class ResultatAnnulationBuilder
    implements Builder<ResultatAnnulation, ResultatAnnulationBuilder> {
  _$ResultatAnnulation? _$v;

  String? _commandeId;
  String? get commandeId => _$this._commandeId;
  set commandeId(String? commandeId) => _$this._commandeId = commandeId;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _montantAvance;
  int? get montantAvance => _$this._montantAvance;
  set montantAvance(int? montantAvance) =>
      _$this._montantAvance = montantAvance;

  int? _partCoursierDue;
  int? get partCoursierDue => _$this._partCoursierDue;
  set partCoursierDue(int? partCoursierDue) =>
      _$this._partCoursierDue = partCoursierDue;

  bool? _remboursementDu;
  bool? get remboursementDu => _$this._remboursementDu;
  set remboursementDu(bool? remboursementDu) =>
      _$this._remboursementDu = remboursementDu;

  bool? _sansFrais;
  bool? get sansFrais => _$this._sansFrais;
  set sansFrais(bool? sansFrais) => _$this._sansFrais = sansFrais;

  ResultatAnnulationBuilder() {
    ResultatAnnulation._defaults(this);
  }

  ResultatAnnulationBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _commandeId = $v.commandeId;
      _devise = $v.devise;
      _montantAvance = $v.montantAvance;
      _partCoursierDue = $v.partCoursierDue;
      _remboursementDu = $v.remboursementDu;
      _sansFrais = $v.sansFrais;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(ResultatAnnulation other) {
    _$v = other as _$ResultatAnnulation;
  }

  @override
  void update(void Function(ResultatAnnulationBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  ResultatAnnulation build() => _build();

  _$ResultatAnnulation _build() {
    final _$result = _$v ??
        _$ResultatAnnulation._(
          commandeId: BuiltValueNullFieldError.checkNotNull(
              commandeId, r'ResultatAnnulation', 'commandeId'),
          devise: BuiltValueNullFieldError.checkNotNull(
              devise, r'ResultatAnnulation', 'devise'),
          montantAvance: BuiltValueNullFieldError.checkNotNull(
              montantAvance, r'ResultatAnnulation', 'montantAvance'),
          partCoursierDue: BuiltValueNullFieldError.checkNotNull(
              partCoursierDue, r'ResultatAnnulation', 'partCoursierDue'),
          remboursementDu: BuiltValueNullFieldError.checkNotNull(
              remboursementDu, r'ResultatAnnulation', 'remboursementDu'),
          sansFrais: BuiltValueNullFieldError.checkNotNull(
              sansFrais, r'ResultatAnnulation', 'sansFrais'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
