// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'devis.dart';

// **************************************************************************
// BuiltValueGenerator
// **************************************************************************

class _$Devis extends Devis {
  @override
  final bool degraded;
  @override
  final String devise;
  @override
  final int distanceM;
  @override
  final int etaS;
  @override
  final int marge;
  @override
  final int partCoursier;
  @override
  final int prixClient;
  @override
  final bool proposerScission;

  factory _$Devis([void Function(DevisBuilder)? updates]) =>
      (DevisBuilder()..update(updates))._build();

  _$Devis._(
      {required this.degraded,
      required this.devise,
      required this.distanceM,
      required this.etaS,
      required this.marge,
      required this.partCoursier,
      required this.prixClient,
      required this.proposerScission})
      : super._();
  @override
  Devis rebuild(void Function(DevisBuilder) updates) =>
      (toBuilder()..update(updates)).build();

  @override
  DevisBuilder toBuilder() => DevisBuilder()..replace(this);

  @override
  bool operator ==(Object other) {
    if (identical(other, this)) return true;
    return other is Devis &&
        degraded == other.degraded &&
        devise == other.devise &&
        distanceM == other.distanceM &&
        etaS == other.etaS &&
        marge == other.marge &&
        partCoursier == other.partCoursier &&
        prixClient == other.prixClient &&
        proposerScission == other.proposerScission;
  }

  @override
  int get hashCode {
    var _$hash = 0;
    _$hash = $jc(_$hash, degraded.hashCode);
    _$hash = $jc(_$hash, devise.hashCode);
    _$hash = $jc(_$hash, distanceM.hashCode);
    _$hash = $jc(_$hash, etaS.hashCode);
    _$hash = $jc(_$hash, marge.hashCode);
    _$hash = $jc(_$hash, partCoursier.hashCode);
    _$hash = $jc(_$hash, prixClient.hashCode);
    _$hash = $jc(_$hash, proposerScission.hashCode);
    _$hash = $jf(_$hash);
    return _$hash;
  }

  @override
  String toString() {
    return (newBuiltValueToStringHelper(r'Devis')
          ..add('degraded', degraded)
          ..add('devise', devise)
          ..add('distanceM', distanceM)
          ..add('etaS', etaS)
          ..add('marge', marge)
          ..add('partCoursier', partCoursier)
          ..add('prixClient', prixClient)
          ..add('proposerScission', proposerScission))
        .toString();
  }
}

class DevisBuilder implements Builder<Devis, DevisBuilder> {
  _$Devis? _$v;

  bool? _degraded;
  bool? get degraded => _$this._degraded;
  set degraded(bool? degraded) => _$this._degraded = degraded;

  String? _devise;
  String? get devise => _$this._devise;
  set devise(String? devise) => _$this._devise = devise;

  int? _distanceM;
  int? get distanceM => _$this._distanceM;
  set distanceM(int? distanceM) => _$this._distanceM = distanceM;

  int? _etaS;
  int? get etaS => _$this._etaS;
  set etaS(int? etaS) => _$this._etaS = etaS;

  int? _marge;
  int? get marge => _$this._marge;
  set marge(int? marge) => _$this._marge = marge;

  int? _partCoursier;
  int? get partCoursier => _$this._partCoursier;
  set partCoursier(int? partCoursier) => _$this._partCoursier = partCoursier;

  int? _prixClient;
  int? get prixClient => _$this._prixClient;
  set prixClient(int? prixClient) => _$this._prixClient = prixClient;

  bool? _proposerScission;
  bool? get proposerScission => _$this._proposerScission;
  set proposerScission(bool? proposerScission) =>
      _$this._proposerScission = proposerScission;

  DevisBuilder() {
    Devis._defaults(this);
  }

  DevisBuilder get _$this {
    final $v = _$v;
    if ($v != null) {
      _degraded = $v.degraded;
      _devise = $v.devise;
      _distanceM = $v.distanceM;
      _etaS = $v.etaS;
      _marge = $v.marge;
      _partCoursier = $v.partCoursier;
      _prixClient = $v.prixClient;
      _proposerScission = $v.proposerScission;
      _$v = null;
    }
    return this;
  }

  @override
  void replace(Devis other) {
    _$v = other as _$Devis;
  }

  @override
  void update(void Function(DevisBuilder)? updates) {
    if (updates != null) updates(this);
  }

  @override
  Devis build() => _build();

  _$Devis _build() {
    final _$result = _$v ??
        _$Devis._(
          degraded: BuiltValueNullFieldError.checkNotNull(
              degraded, r'Devis', 'degraded'),
          devise:
              BuiltValueNullFieldError.checkNotNull(devise, r'Devis', 'devise'),
          distanceM: BuiltValueNullFieldError.checkNotNull(
              distanceM, r'Devis', 'distanceM'),
          etaS: BuiltValueNullFieldError.checkNotNull(etaS, r'Devis', 'etaS'),
          marge:
              BuiltValueNullFieldError.checkNotNull(marge, r'Devis', 'marge'),
          partCoursier: BuiltValueNullFieldError.checkNotNull(
              partCoursier, r'Devis', 'partCoursier'),
          prixClient: BuiltValueNullFieldError.checkNotNull(
              prixClient, r'Devis', 'prixClient'),
          proposerScission: BuiltValueNullFieldError.checkNotNull(
              proposerScission, r'Devis', 'proposerScission'),
        );
    replace(_$result);
    return _$result;
  }
}

// ignore_for_file: deprecated_member_use_from_same_package,type=lint
